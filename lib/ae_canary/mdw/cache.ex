defmodule AeCanary.Mdw.Cache do

  alias AeCanary.Mdw.Cache
  alias AeCanary.Mdw.Cache.{Data, State}
  alias AeCanary.Mdw

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
    defstruct data: nil 
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
    {:ok, start_refresh_timer(%State{}, 0)}
  end

  def handle_call(:get_data, _from, state) do
    data = state.data
    {:reply, data, state}
  end

  def handle_info(:refresh_data, state) do
    refresh_data()
    {:noreply, start_refresh_timer(state)}
  end
  def handle_info({:update_data, mdw_data}, state) do
    data = struct(Data, mdw_data)
    {:noreply, %{state | data: data}}
  end
  def handle_info({:update_data, :failed}, state) do
    {:noreply, %{state | data: nil}}
  end

  # API
  def get() do
    GenServer.call(__MODULE__, :get_data)
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

  # Internal
  defp refresh_data() do
    Mdw.async_fetch(&Mdw.Api.status/0, &Cache.update_data/1)
  end

  defp start_refresh_timer(state), do: start_refresh_timer(state, 5000)

  defp start_refresh_timer(state, interval) do
    _timer_ref = Process.send_after(self(), :refresh_data, interval)
    state
  end
end
