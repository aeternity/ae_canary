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
  defp get_block("end1"), do: %{height: 13, hash: "end1", prev_key_hash: "end1-1"}
  defp get_block("end1-1"), do: %{height: 12, hash: "end1-1", prev_key_hash: "end1-2"}
  defp get_block("end1-2"), do: %{height: 11, hash: "end1-2", prev_key_hash: "end-main-4"}
  ## end2 chain
  defp get_block("end2"), do: %{height: 7, hash: "end2", prev_key_hash: "end2-1"}
  defp get_block("end2-1"), do: %{height: 6, hash: "end2-1", prev_key_hash: "end2-2"}
  defp get_block("end2-2"), do: %{height: 5, hash: "end2-2", prev_key_hash: "end-main-10"}
  ## Main chain
  defp get_block("end-main"), do: %{height: 14, hash: "end-main", prev_key_hash: "end-main-1"}
  defp get_block("end-main-1"), do: %{height: 13, hash: "end-main-1", prev_key_hash: "end-main-2"}
  defp get_block("end-main-2"), do: %{height: 12, hash: "end-main-2", prev_key_hash: "end-main-3"}
  defp get_block("end-main-3"), do: %{height: 11, hash: "end-main-3", prev_key_hash: "end-main-4"}
  defp get_block("end-main-4"), do: %{height: 10, hash: "end-main-4", prev_key_hash: "end-main-5"}
  defp get_block("end-main-5"), do: %{height: 9, hash: "end-main-5", prev_key_hash: "end-main-6"}
  defp get_block("end-main-6"), do: %{height: 8, hash: "end-main-6", prev_key_hash: "end-main-7"}
  defp get_block("end-main-7"), do: %{height: 7, hash: "end-main-7", prev_key_hash: "end-main-8"}
  defp get_block("end-main-8"), do: %{height: 6, hash: "end-main-8", prev_key_hash: "end-main-9"}
  defp get_block("end-main-9"), do: %{height: 5, hash: "end-main-9", prev_key_hash: "end-main-10"}

  defp get_block("end-main-10"),
    do: %{height: 4, hash: "end-main-10", prev_key_hash: "end-main-11"}

  defp get_block("end-main-11"),
    do: %{height: 3, hash: "end-main-11", prev_key_hash: "end-main-12"}

  defp get_block("end-main-12"),
    do: %{height: 2, hash: "end-main-12", prev_key_hash: "end-main-13"}

  defp get_block("end-main-13"),
    do: %{height: 1, hash: "end-main-13", prev_key_hash: "end-main-14"}

  defp get_block("end-main-14"), do: %{height: 0, hash: "end-main-14", prev_key_hash: ""}
  ## It's the end
  defp get_block(_), do: false
end
