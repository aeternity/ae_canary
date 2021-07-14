defmodule AeCanary.Mdw.Cache.Service.Status do
  use AeCanary.Mdw.Cache.Service, name: "MDW status"

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

  @impl true
  def init(), do: nil

  @impl true
  def refresh_interval(), do: seconds(5)

  @impl true
  def cache_handle(), do: :status

  @impl true
  def refresh(_) do
    case Mdw.Api.status() do
      {:ok, data} -> Map.put(data, :__struct__, Data)
      _failed -> nil
    end
  end
end
