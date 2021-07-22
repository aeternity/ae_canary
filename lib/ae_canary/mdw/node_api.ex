defmodule AeCanary.Node.Api do
  @moduledoc """
  API for talking directly to an aeternity node rather that middleware
  """
  def current_generation() do
    get("generations/current")
  end

  defp get(uri) do
    node = Application.fetch_env!(:ae_canary, :node_url)

    case HTTPoison.get(node <> uri) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, parse_body(body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: reason}} ->
        {:error_code, status_code, reason}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp parse_body(body) do
    body
    |> Poison.decode!(%{keys: :atoms})
  end
end
