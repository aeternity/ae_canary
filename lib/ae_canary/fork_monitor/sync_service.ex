defmodule AeCanary.ForkMonitor.SyncService do
  use GenServer
  require Logger

  defmodule State do
    defstruct [
      :chain_walker_pid,
      :chains,
      :top_height,
      :max_depth,
      :sync_status,
      :backfill,
      :backfill_pid
    ]
  end

  @refresh_interval 180_000

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`
    max_depth = config(:max_sync_depth, 50_000)
    backfill = config(:active_backfill, false)
    GenServer.start_link(__MODULE__, [max_depth, backfill], name: __MODULE__)
  end

  def init([max_depth, backfill]) do
    Process.flag(:trap_exit, true)
    Process.send_after(self(), :run_sync, @refresh_interval)
    {:ok, %State{max_depth: max_depth, backfill: backfill, sync_status: :waiting}}
  end

  def handle_call(:get_status, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_info(:run_sync, %State{max_depth: max_depth} = state) do
    {:ok, pid} =
      Task.start_link(AeCanary.ForkMonitor.Model.ChainWalker, :updateChainEnds, [
        max_depth,
        self()
      ])

    Logger.info(
      "Started chain walker sync process with pid #{inspect(pid)} to max_depth #{max_depth}"
    )

    {:noreply, %{state | sync_status: :started, chain_walker_pid: pid}}
  end

  def handle_info({:started_sync, uniqueChainEnds, topHeight}, state) do
    {:noreply,
     %{
       state
       | sync_status: :running,
         chains: Enum.into(uniqueChainEnds, %{}),
         top_height: topHeight
     }}
  end

  def handle_info(:finished_sync, %State{backfill_pid: nil, backfill: true} = state) do
    {:ok, pid} = Task.start_link(AeCanary.ForkMonitor.Model.TransactionBackfill, :backfill, [])
    {:noreply, %{state | sync_status: :synced, backfill_pid: pid}}
  end

  def handle_info(:finished_sync, state) do
    {:noreply, %{state | sync_status: :synced}}
  end

  def handle_info({:EXIT, pid, :normal}, %State{chain_walker_pid: cwpid} = state)
      when pid == cwpid do
    Process.send_after(self(), :run_sync, @refresh_interval)
    {:noreply, %{state | chain_walker_pid: nil}}
  end

  def handle_info({:EXIT, pid, err}, %State{chain_walker_pid: cwpid} = state) when pid == cwpid do
    Logger.error("Chain walker process crashed #{inspect(err)}")
    Process.send_after(self(), :run_sync, @refresh_interval)
    {:noreply, %{state | sync_status: :error, chain_walker_pid: nil}}
  end

  def handle_info({:EXIT, pid, _}, %State{backfill_pid: bpid} = state)
      when pid == bpid do
    {:noreply, %{state | backfill_pid: nil}}
  end

  def handle_info({:progress, topHash, current}, %State{chains: chains} = state) do
    {:noreply, %{state | chains: Map.put(chains, topHash, current)}}
  end

  defp config(key, default) do
    case Application.fetch_env(:ae_canary, AeCanary.ForkMonitor) do
      :error -> default
      {:ok, v} -> Keyword.get(v, key, default)
    end
  end
end
