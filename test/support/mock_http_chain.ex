defmodule AeCanary.MockHTTPChain do
  @moduledoc """
  Mock HTTP client implementation to provide a simple blockchain sufficient for
  testing fork detection
  """

  alias AeCanary.MockChain

  def get(uri),
    do:
      uri
      |> URI.parse()
      |> process
      |> response

  defp process(%URI{path: "/v2/status/chain-ends" <> _}),
    do: {:ok, MockChain.get_chain_ends()}

  defp process(%URI{path: "/v2/generations/current"}),
    do: {:ok, MockChain.get_current_generation()}

  defp process(%URI{path: "/v2/generations/hash/" <> hash}),
    do: {:ok, MockChain.get_generation(hash)}

  defp process(%URI{path: "/v2/key-blocks/hash/" <> hash}) do
    case MockChain.get_block(hash) do
      false ->
        {:error, ""}

      block ->
        entry = Map.put(block, :time, DateTime.utc_now() |> DateTime.to_unix(:millisecond))
        {:ok, entry}
    end
  end

  defp process(%URI{path: "/v2/micro-blocks/hash/" <> path}) do
    case String.split(path, "/") do
      [hash, "transactions"] ->
        {:ok, MockChain.get_transactions(hash)}

      _ ->
        {:error, ""}
    end
  end

  defp response({:ok, body}), do: response(200, body)
  defp response({:error, body}), do: response(404, body)

  defp response(status_code, body),
    do: {:ok, %HTTPoison.Response{status_code: status_code, body: encode!(body)}}

  defp encode!(""), do: ""
  defp encode!(body), do: Jason.encode!(body)
end
