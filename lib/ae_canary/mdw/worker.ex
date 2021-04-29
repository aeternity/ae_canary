defmodule AeCanary.Mdw.Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:exec, fun}, _from, state) do
    {:reply, fun.(), state}
  end

  def exec(pid, fun), do: GenServer.call(pid, {:exec, fun}, :infinity)
end
