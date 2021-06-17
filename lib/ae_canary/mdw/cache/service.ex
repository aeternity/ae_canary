defmodule AeCanary.Mdw.Cache.Service do
  defmodule State do
    defstruct [:data, :refresh_start_tmst, :refresh_end_tmst, :last_refresh_length]
  end

  @callback init() :: {:ok, state :: term()}
  @callback cache_handle() :: atom()
  @callback refresh_interval() :: integer()
  @callback refresh() :: term()

  defmacro __using__(name: name) do
    quote do
      alias AeCanary.Mdw
      @behaviour AeCanary.Mdw.Cache.Service
      def name(), do: unquote(name)

      # GenServer Callbacks
      def start_link() do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      def child_spec(_opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, []},
          type: :worker,
          restart: :transient
        }
      end

      def init(_) do
        start_refresh_timer(:initial)
        {:ok, %State{data: init()}}
      end

      def handle_call(:get, _from, state) do
        {:reply, state.data, state}
      end

      def handle_call(:stats, _from, state) do
        stats =
          case state.refresh_start_tmst do
            nil when state.refresh_end_tmst == nil ->
              %{}

            nil ->
              %{
                ongoing_update: false,
                last_refresh_length: state.last_refresh_length,
                refresh_end_tmst: state.refresh_end_tmst
              }

            _ ->
              %{
                ongoing_update: true,
                last_refresh_length: state.last_refresh_length,
                refresh_start_tmst: state.refresh_start_tmst
              }
          end

        {:reply, stats, state}
      end

      def handle_info(:refresh_data, state) do
        refresh_data()
        start_refresh_timer()
        {:noreply, %State{state | refresh_start_tmst: now(), refresh_end_tmst: nil}}
      end

      def handle_info({:set, data}, state) do
        AeCanary.Mdw.Cache.set_data(cache_handle(), data)
        now = now()

        last_refresh_length =
          Timex.diff(now, state.refresh_start_tmst, :millisecond)
          |> Timex.Duration.from_milliseconds()

        {:noreply,
         %{
           state
           | data: data,
             refresh_end_tmst: now,
             refresh_start_tmst: nil,
             last_refresh_length: last_refresh_length
         }}
      end

      #
      # API
      def get() do
        GenServer.call(__MODULE__, :get)
      end

      def set(data) do
        send(__MODULE__, {:set, data})
      end

      def stats() do
        GenServer.call(__MODULE__, :stats)
      end

      # Internal
      defp refresh_data() do
        Mdw.async_fetch(&refresh/0, &__MODULE__.set/1)
      end

      defp start_refresh_timer() do
        start_refresh_timer(:normal)
      end

      defp start_refresh_timer(type) do
        milliseconds =
          case type do
            :initial ->
              ## Bit of an ugly hack to allow the unit tests to run in a node that
              ## doesn't start these services until long after the tests are finished.
              ## If we can work out a way for the Exchange service to access Ecto
              ## outside all the Exunit Ecto pools we can remove this.
              case Application.fetch_env(:ae_canary, AeCanary.Mdw.Cache.Service) do
                :error -> 0
                {:ok, v} -> Keyword.get(v, :startup_delay, 0)
              end

            _ ->
              refresh_interval()
          end

        Process.send_after(self(), :refresh_data, milliseconds)
      end

      defp seconds(s), do: s * 1000
      defp minutes(m), do: seconds(m) * 60
      defp hours(h), do: minutes(h) * 60

      defp now() do
        Timex.now()
      end
    end
  end
end
