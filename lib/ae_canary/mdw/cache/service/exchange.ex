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
  def refresh() do
    ## update DB
    {:ok, %{node_height: top_height}} = Mdw.Api.status()
    update_from = top_height - refresh_period_in_blocks()
    update_to = top_height
    all_exchanges_and_addresses = Exchanges.list_exchanges_and_addresses()
    update_DB(update_from, update_to, all_exchanges_and_addresses)
    update_start = DateTime.utc_now() |> DateTime.to_date()
    refresh_from_db(update_start, all_exchanges_and_addresses)
  end

  defp update_DB(from, to, all_exchanges_and_addresses) do
    all_exchanges_and_addresses
    |> Enum.map(
      fn(%{addresses: addresses}) ->
        Enum.map(addresses,
          fn(address) ->
            Mdw.Api.incoming_spend_txs(address.addr, from, to)
            Mdw.Api.outgoing_spend_txs(address.addr, from, to)
          end)
      end)
  end

  defp refresh_from_db(update_start, all_exchanges_and_addresses) do
    all_dates =
      0..show_period_in_days()
      |> Enum.map(&(Timex.shift(update_start, days: -1 * &1)))
    ## fetch from DB
    addresses =
      all_exchanges_and_addresses
      |> (fn(exchanges_and_addresses) -> for %{addresses: addrs} <- exchanges_and_addresses, do: addrs end).()
      |> List.flatten()
      |> (fn(addrs) -> for a <- addrs, do: a.addr end).()
    from_date = Timex.shift(update_start, days: -1 * show_period_in_days())
    default_addresses_data = Enum.map(all_dates, fn(date) -> Enum.map(addresses, fn(addr) -> {{date, addr}, %{sum: 0, txs: 0}} end) end) |> List.flatten() |> Enum.into(%{})
    to_map =
      fn(records) ->
        found_data =
          records
          |> Enum.map(
            fn(%{address: addr, date: date, sum: sum, txs: txs_cnt}) -> {{date, addr}, %{sum: sum, txs: txs_cnt}} end)
          |> Enum.into(%{})
        Map.merge(default_addresses_data, found_data)
      end
    withdrawals = Transactions.aggregated_for_addresses(:sender_id, addresses, from_date) |> to_map.()
    deposits = Transactions.aggregated_for_addresses(:recipient_id, addresses, from_date) |> to_map.()
    {true, _, _, _} = {map_size(withdrawals) == map_size(deposits), map_size(withdrawals), map_size(deposits), map_size(default_addresses_data)}
    addresses_and_data =
      Map.merge(deposits, withdrawals, fn({date, addr}, d, w) -> {addr, %{date: date, deposits: d, withdrawals: w}} end)
      |> Map.values()
      |> Enum.reduce(%{},
        fn({addr, data}, accum) ->
          old_data = Map.get(accum, addr, [])
          Map.put(accum, addr, [data | old_data])
        end)
      |> Enum.map(fn({address, data}) -> {address, Enum.sort(data, &(Date.compare(&1.date, &2.date) != :lt)) } end)
      |> Enum.map(fn({address, data}) -> {address, %{data: data, has_txs: Enum.any?(data, &(&1.deposits.txs > 0 || &1.withdrawals.txs > 0))}} end)
      |> Enum.into(%{})
    exchanges =
      Enum.map(all_exchanges_and_addresses,
        fn(%{addresses: addrs0} = e) ->
          addrs =
            addrs0
            |> Enum.map(
              fn(a) ->
                %{data: data, has_txs: has_txs} = Map.fetch!(addresses_and_data, a.addr)
                suspicious_deposits = Transactions.list_locations_of_spend_txs_by(%{select: :tx_and_location, recipient_id: a.addr, date_from: Timex.shift(update_start, days: -1 * show_period_in_days()), amount_at_least: suspicious_deposits_threshold()})
                boundaries =
                  data
                  |> Enum.map(&(&1.deposits.sum - &1.withdrawals.sum))
                  |> upper_boundaries()
                [lower_boundary, upper_boundary] =
                  boundaries
                  |> Enum.sort()
                last_day_in_alert_scope = Timex.shift(update_start, days: -1 * alert_interval_in_days())
                over_the_boundaries =
                  data
                  |> Enum.filter(&(Date.compare(&1.date, last_day_in_alert_scope) != :lt)) ## :gt or :eq
                  |> Enum.filter(&(&1.deposits.sum - &1.withdrawals.sum >= lower_boundary and &1.deposits.sum - &1.withdrawals.sum > 0))
                  |> Enum.map(
                    fn(%{date: date, deposits: deposits, withdrawals: withdrawals}) ->
                      message =
                        case deposits.sum - withdrawals.sum do
                          exposure when exposure > upper_boundary ->
                            %{boundary: "upper", exposure: exposure, limit: upper_boundary}
                          exposure ->
                            %{boundary: "lower", exposure: exposure, limit: lower_boundary}
                        end
                      %{date: date, message: message}
                    end)
                    Map.merge(a, %{data: data, has_txs: has_txs, big_deposits: suspicious_deposits, upper_boundaries: boundaries, over_the_boundaries: over_the_boundaries})
              end)
          aggregated =
            addrs
            |> Enum.map(&(&1.data))
            |> Enum.zip()
            |> Enum.map(
              fn(tuple) ->
                tuple
                |> Tuple.to_list()
                |> Enum.reduce(
                  %{deposits: 0, txs: 0, withdrawals: 0},
                  fn(%{date: date, deposits: d1, withdrawals: w1}, %{txs: accum_txs, deposits: accum_d, withdrawals: accum_w}) ->
                    %{date: date, txs: d1.txs + w1.txs + accum_txs, deposits: d1.sum + accum_d, withdrawals: w1.sum + accum_w}
                  end)
              end)
          has_txs_past_days =
            aggregated
            |> Enum.slice(0..has_transactions_in_the_past_days_interval() - 1)
            |> Enum.any?(&(&1.txs > 0))
          txs_total =
            aggregated
            |> Enum.reduce(0, &(&1.txs + &2))
          upper_boundaries = upper_boundaries(aggregated |> Enum.map(&(&1.deposits - &1.withdrawals)))
          Map.merge(e, %{upper_boundaries: upper_boundaries, addresses: addrs, aggregated: aggregated, has_txs_past_days: has_txs_past_days, txs: txs_total})
        end)
      |> Enum.sort(&(&1.txs >= &2.txs))
    seven_days_ago =
      update_start
      |> Timex.shift(days: -1 * alert_interval_in_days())
    alerts_for_past_days =
      exchanges
      |> Enum.map(
        fn(%{name: name, id: id, addresses: addresses}) ->
          interesting_addresses =
            addresses
            |> Enum.map(
              fn(%{addr: addr, big_deposits: d, id: id, over_the_boundaries: over_the_boundaries}) ->
                deposits =
                  d
                  |> Enum.filter(&(Date.compare(DateTime.to_date(&1.location.micro_time), seven_days_ago) != :lt))
                case Enum.empty?(deposits) and Enum.empty?(over_the_boundaries) do
                  true -> :skip
                  false -> %{id: id, addr: addr, big_deposits: deposits, over_the_boundaries: over_the_boundaries}
                end
              end)
            |> Enum.filter(&(&1 != :skip))
          case Enum.empty?(interesting_addresses) do
            true -> :skip
            false -> %{name: name, id: id, addresses: interesting_addresses}
          end
        end)
      |> Enum.filter(&(&1 != :skip))
    %{exchanges: exchanges, alerts_for_past_days: alerts_for_past_days}
  end

  defp one_day_in_blocks(), do: 20 * 24

  def show_period_in_days(), do: config(:stats_interval_in_days, 30)

  def alert_interval_in_days(), do: config(:show_alerts_interval_in_days, 7)

  def has_transactions_in_the_past_days_interval(), do: config(:has_transactions_in_the_past_days_interval, 7)

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

  defp refresh_period_in_blocks(), do: one_day_in_blocks() * show_period_in_days()

  defp upper_boundaries(list0) do
    list =
      case iqr_use_positive_exposure_only() do
        true -> Enum.filter(list0, &(&1 > 0))
        false -> list0
      end
    case IR.third_quartile(list) do
      nil -> [0, 0]
      q3 ->
        iqr = IR.iqr(list)
        Enum.map(
          [iqr_lower_boundary_multiplier(), iqr_upper_boundary_multiplier()],
          fn(multiplier) ->
            IR.q3_fence(q3, iqr, multiplier)
          end)
    end
  end
end