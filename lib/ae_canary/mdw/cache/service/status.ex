defmodule AeCanary.Mdw.Cache.Service.Status do
  use AeCanary.Mdw.Cache.Service, name: "MDW status"

  def get_data() do
    cache_handle()
    |> AeCanary.Mdw.Cache.get()
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
      {:ok, %{"node_version" => version, "top_block_height" => height}} ->
        %{version: version, height: height}

      _ ->
        nil
    end
  end
end
