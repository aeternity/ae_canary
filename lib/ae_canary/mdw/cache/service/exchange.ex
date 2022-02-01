defmodule AeCanary.Mdw.Cache.Service.Exchange do
  use AeCanary.Mdw.Cache.Service, name: "Exchanges exposure"

  alias AeCanary.Transactions
  alias AeCanary.Exchanges

  alias AeCanary.Statistics.InterquartileRange, as: IR

  @impl true
  def init(), do: nil

  @impl true
  def refresh_interval(), do: minutes(10)

  @impl true
  def cache_handle(), do: :exchanges

  @impl true
  def refresh(_) do
    update_start = DateTime.utc_now() |> DateTime.to_date()
    alerts_start = alerts_start(update_start)
    dates = get_dates(update_start)

    all = Exchanges.list_exchanges_and_addresses()
    exchanges = exchanges_data(all, dates)
    alerts = alerts(exchanges, alerts_start)

    users = AeCanary.Accounts.list_users()
    AeCanary.Mdw.Notifier.send_notifications(alerts, users)

    %{
      exchanges: exchanges,
      alerts_for_past_days: alerts
    }
  end

  def exchanges_data(exchanges, dates) do
    exchanges
    |> Enum.map(fn %{addresses: addrs} = exchange ->
      data = addresses_data(addrs, dates)
      Map.merge(exchange, data)
    end)
    |> Enum.sort(&(&1.txs >= &2.txs))
  end

  def addresses_data(addresses, dates) do
    {addrs, aggregated} =
      addresses
      |> Enum.map_reduce(nil, fn address, acc ->
        data = address_data(address.addr, dates)
        new_acc = merge_dataset_data(acc, data.dataset)
        {Map.merge(address, data), new_acc}
      end)

    has_txs_past_days =
      aggregated
      |> Enum.slice(0..(has_transactions_in_the_past_days_interval() - 1))
      |> Enum.any?(&(&1.tx_count > 0))

    txs_total = aggregated |> Enum.reduce(0, &(&1.tx_count + &2))
    upper_boundaries = boundaries(aggregated)

    %{
      upper_boundaries: upper_boundaries,
      addresses: addrs,
      aggregated: aggregated,
      has_txs_past_days: has_txs_past_days,
      txs: txs_total
    }
  end

  def address_data(address, [from_date | _] = dates) do
    deposits =
      :recipient_id
      |> Transactions.aggregated_for_address(address, from_date)

    withdrawals =
      :sender_id
      |> Transactions.aggregated_for_address(address, from_date)

    has_txs = map_size(withdrawals) + map_size(deposits) > 0

    dataset =
      dates
      |> Enum.reverse()
      |> Enum.map(fn date ->
        deposit = Map.get(deposits, date, %{sum: 0, count: 0})
        withdrawal = Map.get(withdrawals, date, %{sum: 0, count: 0})

        %{
          date: date,
          exposure: deposit.sum - withdrawal.sum,
          tx_count: deposit.count + withdrawal.count,
          deposits_sum: deposit.sum,
          deposits_count: deposit.count,
          withdrawals_sum: withdrawal.sum,
          withdrawals_count: withdrawal.count
        }
      end)

    big_deposits = suspicious_deposits(address, from_date)
    upper_boundaries = boundaries(dataset)
    over_the_boundaries = over_the_boundaries(dataset, from_date, upper_boundaries)

    %{
      dataset: dataset,
      has_txs: has_txs,
      big_deposits: big_deposits,
      upper_boundaries: upper_boundaries,
      over_the_boundaries: over_the_boundaries
    }
  end

  defp merge_dataset_data(nil, dataset), do: dataset

  defp merge_dataset_data(acc, dataset) do
    acc
    |> Enum.zip(dataset)
    |> Enum.map(fn {
                     %{date: date} = acc,
                     %{date: date} = datapoint
                   } ->
      %{
        date: date,
        exposure: datapoint_sum(:exposure, acc, datapoint),
        tx_count: datapoint_sum(:tx_count, acc, datapoint),
        deposits_sum: datapoint_sum(:deposits_sum, acc, datapoint),
        deposits_count: datapoint_sum(:deposits_count, acc, datapoint),
        withdrawals_sum: datapoint_sum(:withdrawals_sum, acc, datapoint),
        withdrawals_count: datapoint_sum(:withdrawals_count, acc, datapoint)
      }
    end)
  end

  defp datapoint_sum(key, l, r), do: l[key] + r[key]

  def suspicious_deposits(addr, from_date) do
    Transactions.list_spend_txs_by(%{
      recipient_id: addr,
      date_from: from_date,
      amount_at_least: suspicious_deposits_threshold()
    })
  end

  def boundaries(dataset) do
    dataset
    |> Enum.map(& &1.exposure)
    |> upper_boundaries()
  end

  defp upper_boundaries(list0) do
    list =
      case iqr_use_positive_exposure_only() do
        true -> Enum.filter(list0, &(&1 > 0))
        false -> list0
      end

    case IR.third_quartile(list) do
      nil ->
        [0, 0]

      q3 ->
        iqr = IR.iqr(list)

        Enum.map(
          [iqr_lower_boundary_multiplier(), iqr_upper_boundary_multiplier()],
          fn multiplier ->
            IR.q3_fence(q3, iqr, multiplier)
          end
        )
        |> Enum.sort()
    end
  end

  def over_the_boundaries(dataset, time, [lower, upper]) do
    last_day_in_alert_scope = Timex.shift(time, days: -1 * alert_interval_in_days())

    dataset
    |> Enum.filter(&(Date.compare(&1.date, last_day_in_alert_scope) != :lt))
    |> Enum.filter(&(&1.exposure > lower and &1.exposure > 0))
    |> Enum.map(fn %{date: date, exposure: exposure} ->
      message =
        if exposure > upper do
          %{boundary: "upper", exposure: exposure, limit: upper}
        else
          %{boundary: "lower", exposure: exposure, limit: lower}
        end

      %{date: date, message: message}
    end)
  end

  def alerts(exchanges, from_date),
    do:
      exchanges
      |> Enum.flat_map(fn exchange -> exchange_alerts(exchange, from_date) end)

  defp exchange_alerts(%{name: name, id: id, addresses: addresses}, from_date) do
    addresses
    |> Enum.flat_map(fn address -> address_alerts(address, from_date) end)
    |> maybe_exchange_alert(id, name)
  end

  defp maybe_exchange_alert([], _, _), do: []
  defp maybe_exchange_alert(data, id, name), do: [%{name: name, id: id, addresses: data}]

  defp address_alerts(addr, from_date) do
    deposits = filter_deposits(addr.big_deposits, from_date)
    boundaries = filter_boundaries(addr.over_the_boundaries, from_date)

    maybe_address_alert(deposits, boundaries, addr.id, addr.addr)
  end

  def filter_deposits(deposits, from_date) do
    deposits
    |> Enum.filter(&(Date.compare(DateTime.to_date(&1.micro_time), from_date) != :lt))
  end

  def filter_boundaries(boundaries, from_date) do
    boundaries
    |> Enum.filter(&(Date.compare(&1.date, from_date) != :lt))
  end

  defp maybe_address_alert([], [], _, _), do: []

  defp maybe_address_alert(deposits, boundaries, id, addr),
    do: [
      %{
        id: id,
        addr: addr,
        big_deposits: deposits,
        over_the_boundaries: boundaries
      }
    ]

  defp get_dates(today),
    do:
      show_period_in_days()..0
      |> Enum.map(&Timex.shift(today, days: -1 * &1))

  defp alerts_start(today),
    do:
      today
      |> Timex.shift(days: -1 * alert_interval_in_days())

  def show_period_in_days(), do: config(:stats_interval_in_days, 30)

  def alert_interval_in_days(), do: config(:show_alerts_interval_in_days, 7)

  def has_transactions_in_the_past_days_interval(),
    do: config(:has_transactions_in_the_past_days_interval, 7)

  def suspicious_deposits_threshold(), do: config(:suspicious_deposits_threshold, 500_000)

  def iqr_use_positive_exposure_only(), do: config(:iqr_use_positive_exposure_only, false)
  def iqr_lower_boundary_multiplier(), do: config(:iqr_lower_boundary_multiplier, 1.5)
  def iqr_upper_boundary_multiplier(), do: config(:iqr_upper_boundary_multiplier, 3)

  defp config(key, default) do
    case Application.fetch_env(:ae_canary, AeCanary.Mdw.Cache.Service.Exchange) do
      :error -> default
      {:ok, v} -> Keyword.get(v, key, default)
    end
  end
end
