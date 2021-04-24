defmodule AeCanary.Mdw.Api do

  @spec status() :: {:ok, %{mdw_version: String.t,
                            node_version: String.t,
                            node_height: integer(),
                            node_syncing: boolean(),
                            mdw_synced: boolean()}} | :not_found | {:error, String.t}
  def status() do
    get("status", ["mdw_version", "node_version", "node_height", "node_syncing", "mdw_synced"])
  end

  defp get(uri, expected_fields) do
    mdw = Application.fetch_env!(:ae_canary, :mdw_url)
    case HTTPoison.get(mdw <> uri) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, parse_body(body, expected_fields)} 
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        :not_found
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp parse_body(body, fields) do
    body
    |> Jason.decode!
    |> Map.take(fields)
    |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end
end
