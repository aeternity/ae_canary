defmodule AeCanary.Mdw.Cache.Service.Exchange do
  use AeCanary.Mdw.Cache.Service, name: "Exchanges exposure"

  alias AeCanary.Transactions
  alias AeCanary.Transactions.{Tx, Location, Spend}
  alias AeCanary.Exchanges.{Exchange, Address}
  alias AeCanary.Exchanges

  @impl true
  def init(), do: nil 

  @impl true
  def refresh_interval(), do: minutes(10)

  @impl true
  def cache_handle(), do: :exchanges

  @impl true
  def refresh() do
    {:ok, %{node_height: top_height}} = Mdw.Api.status()
    update_start = DateTime.utc_now() |> DateTime.to_date()
    interval = 20 * 24
    all_dates =
      0..30
      |> Enum.map(&(Timex.shift(update_start, days: -1 * &1)))
    buckets = buckets(top_height, interval)
    ## update DB
    update_from = top_height - refresh_period_in_blocks()
    update_to = top_height
    all_exchanges_and_addresses = Exchanges.list_exchanges_and_addresses()
    all_exchanges_and_addresses
    |> Enum.map(
      fn(%{id: exchange_id, name: exchange_name, addresses: addresses}) ->
        Enum.map(addresses,
          fn(address) ->
            Mdw.Api.incoming_spend_txs(address.addr, update_from, update_to)
            Mdw.Api.outgoing_spend_txs(address.addr, update_from, update_to)
          end)
      end)
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
      |> Enum.into(%{})
    exchanges =
      Enum.map(all_exchanges_and_addresses,
        fn(%{addresses: addrs0} = e) ->
          addrs =
            addrs0
            |> Enum.map(
              fn(a) ->
                data = Map.fetch!(addresses_and_data, a.addr)
                Map.put(a, :data, data)
              end)
          %{e | addresses: addrs}
        end)
    %{exchanges: exchanges, buckets: buckets}
  end

  defp buckets(top_height, interval) do
    mk_intervals =
      fn top, cnt, inter ->
        interval_names = %{1 => "Past 24h"}
        Enum.map(1..cnt,
          fn(idx) ->
            r_end = top - inter * (idx - 1)
            l_end = r_end - inter + 1
            case l_end do
              _ when l_end == 0 and r_end > 0 -> {idx, %{from: 1, to: r_end}}
              _ when l_end <= 0 -> :skip
              _  -> {Integer.to_string(idx), %{from: l_end, to: r_end, name: Map.get(interval_names, idx, "#{idx} * 24h")}}
            end
          end)
        |> Enum.filter(&(&1 != :skip))
        |> Enum.into(%{})
      end
    %{"1" => thirty_days} = mk_intervals.(top_height, 1, 30 * interval)
    Map.put(mk_intervals.(top_height, 7, interval), "30", %{thirty_days | name: "last 30 days"})
  end


  defp one_day_in_blocks(), do: 20 * 24
  defp show_period_in_days(), do: 30 ## days
  defp refresh_period_in_blocks(), do: one_day_in_blocks() * show_period_in_days()

  defp sum_amounts({:ok, txs}) do
    sum_amounts(txs)
  end
  defp sum_amounts(txs) do
    txs
    |> Enum.map(fn %Tx{tx: %Spend{amount: amount}} -> amount end)
    |> Enum.sum()
  end
end
