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
    interval = 20 * 24
    buckets = buckets(top_height, interval)
    exchanges =
      Exchanges.list_exchanges_and_addresses()
      |> Enum.map(
        fn(%{id: exchange_id, name: exchange_name, addresses: addresses}) ->
          fetched_addresses =
            Enum.map(addresses,
              fn(address) ->
                amounts =
                  buckets
                  |> Enum.map(
                    fn({k, %{from: l_end, to: r_end, name: name}}) ->
                      deposit = sum_amounts(Mdw.Api.incoming_spend_txs(address.addr, l_end, r_end))
                      withdrawal = sum_amounts(Mdw.Api.outgoing_spend_txs(address.addr, l_end, r_end))
                      {k, %{deposit: deposit, withdrawal: withdrawal}}
                    end)
                  |> Enum.into(%{})
                %{id: address.id, addr: address.addr, amounts: amounts} 
              end)
          aggregated =
            fetched_addresses
            |> Enum.reduce(
              %{},
              fn(%{amounts: amounts}, acc) -> Map.merge(amounts, acc, fn(_k, v1, v2) -> %{deposit: v1.deposit + v2.deposit, withdrawal: v1.withdrawal + v2.withdrawal} end) end)
          %{id: exchange_id, name: exchange_name, addresses: fetched_addresses, aggregated: aggregated}
        end)
      |> Enum.sort(
        fn(exc1, exc2) ->
          exc1.aggregated["1"].deposit >= exc2.aggregated["1"].deposit
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

  defp sum_amounts({:ok, txs}) do
    sum_amounts(txs)
  end
  defp sum_amounts(txs) do
    txs
    |> Enum.map(fn %Tx{tx: %Spend{amount: amount}} -> amount end)
    |> Enum.sum()
  end
end
