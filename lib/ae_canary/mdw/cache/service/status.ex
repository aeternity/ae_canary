defmodule AeCanary.Mdw.Cache.Service.Status do
  use AeCanary.Mdw.Cache.Service, name: "Node connection status"

  defmodule Data do
    defstruct node_version: "0.0.0",
              node_height: 0

    @type t() :: %__MODULE__{
            node_version: String.t(),
            node_height: integer()
          }
  end

  @impl true
  def init(), do: nil

  @impl true
  def refresh_interval(), do: seconds(5)

  @impl true
  def cache_handle(), do: :status

  @impl true
  def refresh(_) do
    case AeCanary.Node.Api.status() do
      {:ok, %{"node_version" => vsn, "top_block_height" => height}} ->
        %Data{node_version: vsn, node_height: height}

      _failed ->
        nil
    end
  end
end
