defmodule AeCanary.Mdw.Cache.Service.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      AeCanary.Mdw.Cache.Service.Status,
      AeCanary.Mdw.Cache.Service.Exchange,
      AeCanary.Mdw.Cache.Service.TaintedAccounts,
      AeCanary.Mdw.Cache.Service.ForkDetector,
      AeCanary.Mdw.Cache.Service.BlockDelay
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
