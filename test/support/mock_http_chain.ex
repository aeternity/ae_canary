defmodule AeCanary.MockHTTPChain do
  @moduledoc """
  Mock HTTP client implementation to provide a simple blockchain sufficient for
  testing fork detection
  """
  def get!(uri) do
    case URI.parse(uri) do
      %URI{path: "/v2/key-blocks/hash/" <> hash} ->
        case get_block(hash) do
          false ->
            %HTTPoison.Response{status_code: 404, body: ""}

          block ->
            entry = Map.put(block, :time, DateTime.utc_now() |> DateTime.to_unix(:millisecond))
            %HTTPoison.Response{status_code: 200, body: Jason.encode!(entry)}
        end

      %URI{path: "/v2/status/chain-ends" <> _} ->
        %HTTPoison.Response{status_code: 200, body: Jason.encode!(get_chain_ends())}
    end
  end

  defp get_chain_ends() do
    ["end-main", "end1", "end2"]
  end

  ## end1 chain
  defp get_block("end1"), do: %{height: 80, hash: "end1", prev_key_hash: "end1-1"}
  defp get_block("end1-1"), do: %{height: 79, hash: "end1-1", prev_key_hash: "end1-2"}
  defp get_block("end1-2"), do: %{height: 78, hash: "end1-2", prev_key_hash: "end-main-4"}
  ## end2 chain
  defp get_block("end2"), do: %{height: 90, hash: "end2", prev_key_hash: "end2-1"}
  defp get_block("end2-1"), do: %{height: 89, hash: "end2-1", prev_key_hash: "end2-2"}
  defp get_block("end2-2"), do: %{height: 88, hash: "end2-2", prev_key_hash: "end-main-3"}
  ## Main chain
  defp get_block("end-main"), do: %{height: 100, hash: "end-main", prev_key_hash: "end-main-1"}
  defp get_block("end-main-1"), do: %{height: 99, hash: "end-main-1", prev_key_hash: "end-main-2"}
  defp get_block("end-main-2"), do: %{height: 98, hash: "end-main-2", prev_key_hash: "end-main-3"}
  defp get_block("end-main-3"), do: %{height: 97, hash: "end-main-3", prev_key_hash: "end-main-4"}
  defp get_block("end-main-4"), do: %{height: 96, hash: "end-main-4", prev_key_hash: ""}
  ## It's the end
  defp get_block(_), do: false
end
