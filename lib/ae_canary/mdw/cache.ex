defmodule AeCanary.Mdw.Cache do

  defmodule State do
    defstruct new_data: %{}
    @type t() :: %__MODULE__{
      new_data: Map.t
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
    {:ok, %State{}}
  end

  def handle_call({:set, source, data}, _from, state) do
    new_data = Map.put(state.new_data, source, data)
    {:reply, :ok, %State{state | new_data: new_data}}
  end

  def handle_call({:get, key}, _from, state) do
    data = state.new_data[key]
    {:reply, data, state}
  end

  # API
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def set_data(source, data) do
    GenServer.call(__MODULE__, {:set, source, data})
  end
end
