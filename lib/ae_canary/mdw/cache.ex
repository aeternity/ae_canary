defmodule AeCanary.Mdw.Cache do

  alias AeCanary.Mdw.Cache
  alias AeCanary.Mdw.Cache.{Data, State}
  alias AeCanary.Mdw

  alias AeCanary.Exchanges.{Exchange, Address}
  alias AeCanary.Exchanges

  alias AeCanary.Mdw.Api.{Tx}

  defmodule Data do
    defstruct mdw_version: "0.0.0",
              node_version: "0.0.0",
              node_height: 0,
              node_syncing: false,
              mdw_synced: false
    @type t() :: %__MODULE__{
      mdw_version: String.t,
      node_version: String.t,
      node_height: integer(),
      node_syncing: boolean(),
      mdw_synced: boolean()}
  end

  defmodule State do
    defstruct data: nil, exchanges: nil
    @type t() :: %__MODULE__{
      data: nil | Data.t
      }
  end

  # Callbacks
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker,
      restart: :permanent
    }
  end

  def init(_) do
    {:ok, start_refresh_timer(%State{}, :initial)}
  end

  def handle_call(:get_status, _from, state) do
    data = state.data
    {:reply, data, state}
  end

  def handle_call(:get_exchanges, _from, state) do
    data = state.exchanges
    {:reply, data, state}
  end

  def handle_info(:refresh_data, state) do
    refresh_data()
    {:noreply, start_refresh_timer(state, :status)}
  end
  def handle_info(:refresh_exchanges, state) do
    refresh_exchanges()
    {:noreply, start_refresh_timer(state, :exchanges)}
  end
  def handle_info({:update_data, data}, state) do
    {:noreply, %{state | data: data}}
  end
  def handle_info({:update_data, :failed}, state) do
    {:noreply, %{state | data: nil}}
  end
  def handle_info({:update_exchanges, exchanges}, state) do
    {:noreply, %{state | exchanges: exchanges}}
  end

  # API
  def get() do
    GenServer.call(__MODULE__, :get_status)
  end

  def get_exchanges() do
    GenServer.call(__MODULE__, :get_exchanges)
  end

  def update_data({:ok, data}) do
    send(__MODULE__, {:update_data, data})
  end
  def update_data({:error_code, _}) do
    ## TODO: log this event
    send(__MODULE__, {:update_data, :failed})
  end
  def update_data({:error, _reason}) do
    ## TODO: log this event
    send(__MODULE__, {:update_data, :failed})
  end

  def update_exchange(exchanges) do
    send(__MODULE__, {:update_exchanges, exchanges})
  end

  # Internal
  defp refresh_data() do
    Mdw.async_fetch(&Mdw.Api.status/0, &Cache.update_data/1)
  end

  defp refresh_exchanges() do
    Mdw.async_fetch(
      fn() ->
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
      end, &Cache.update_exchange/1)
  end


  defp start_refresh_timer(state, type) do
    timers = %{status: {:refresh_data, seconds(5)},
               exchanges: {:refresh_exchanges, minutes(10)}}
    start_timer =
      fn({event, milliseconds}) ->
        time =
          case type do
            :initial -> 0
            _ -> milliseconds
          end
          Process.send_after(self(), event, time)
      end
    case type do
      :initial -> timers |> Map.values |> Enum.each(start_timer)
      _ -> timers |> Map.get(type) |> start_timer.()
    end
    state
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

  defp seconds(s), do: s * 1000
  defp minutes(m), do: seconds(m) * 60

  defp aetto_to_ae(amt), do: amt / :math.pow(10, 18)

  defp sum_amounts({:ok, txs}) do
    txs
    |> Enum.map(fn %Tx{tx: %Tx.Spend{amount: amount}} -> amount end)
    |> Enum.sum()
    |> aetto_to_ae()
  end
end
