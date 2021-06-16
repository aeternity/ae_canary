defmodule AeCanary.Mdw.Cache.Service.TaintedAccounts do
  use AeCanary.Mdw.Cache.Service, name: "[WIP] Tainted accounts"

  @impl true
  def init(), do: nil

  @impl true
  def refresh_interval(), do: seconds(20)

  @impl true
  def cache_handle(), do: :tainted_accounts

  @impl true
  def refresh() do
    :ok
  end
end
