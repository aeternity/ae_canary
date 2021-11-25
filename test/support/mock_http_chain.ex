defmodule AeCanary.MockHTTPChain do
  @moduledoc """
  Mock HTTP client implementation to provide a simple blockchain sufficient for
  testing fork detection
  """

  def get(uri) do
    case URI.parse(uri) do
      %URI{path: "/v2/key-blocks/hash/" <> hash} ->
        case get_block(hash) do
          false ->
            {:ok, %HTTPoison.Response{status_code: 404, body: ""}}

          block ->
            entry = Map.put(block, :time, DateTime.utc_now() |> DateTime.to_unix(:millisecond))
            {:ok, %HTTPoison.Response{status_code: 200, body: Jason.encode!(entry)}}
        end

      %URI{path: "/v2/status/chain-ends" <> _} ->
        {:ok, %HTTPoison.Response{status_code: 200, body: Jason.encode!(get_chain_ends())}}

      %URI{path: "/v2/generations/current"} ->
        {:ok,
         %HTTPoison.Response{status_code: 200, body: Jason.encode!(get_current_generation())}}

      %URI{path: "/v2/generations/hash/" <> hash} ->
        {:ok, %HTTPoison.Response{status_code: 200, body: Jason.encode!(get_generation(hash))}}

      %URI{path: "/v2/micro-blocks/hash/mh_microhash/transactions"} ->
        {:ok, %HTTPoison.Response{status_code: 200, body: Jason.encode!(%{"transactions" => []})}}

      %URI{path: "/v2/micro-blocks/hash/mh_no_transactions/transactions/count"} ->
        {:ok, %HTTPoison.Response{status_code: 200, body: Jason.encode!(%{"count" => 0})}}
    end
  end

  defp get_chain_ends() do
    ["end-main", "end1", "end2"]
  end

  ## end1 chain
  defp get_block("end1"), do: get_block(13, "end1", "end1-1")
  defp get_block("end1-1"), do: get_block(12, "end1-1", "end1-2")
  defp get_block("end1-2"), do: get_block(11, "end1-2", "end-main-4")
  ## end2 chain
  defp get_block("end2"), do: get_block(7, "end2", "end2-1")
  defp get_block("end2-1"), do: get_block(6, "end2-1", "end2-2")
  defp get_block("end2-2"), do: get_block(5, "end2-2", "end-main-10")
  ## Main chain
  defp get_block("end-main"), do: get_block(14, "end-main", "end-main-1")
  defp get_block("end-main-1"), do: get_block(13, "end-main-1", "end-main-2")
  defp get_block("end-main-2"), do: get_block(12, "end-main-2", "end-main-3")
  defp get_block("end-main-3"), do: get_block(11, "end-main-3", "end-main-4")
  defp get_block("end-main-4"), do: get_block(10, "end-main-4", "end-main-5")
  defp get_block("end-main-5"), do: get_block(9, "end-main-5", "end-main-6")
  defp get_block("end-main-6"), do: get_block(8, "end-main-6", "end-main-7")
  defp get_block("end-main-7"), do: get_block(7, "end-main-7", "end-main-8")
  defp get_block("end-main-8"), do: get_block(6, "end-main-8", "end-main-9")
  defp get_block("end-main-9"), do: get_block(5, "end-main-9", "end-main-10")
  defp get_block("end-main-10"), do: get_block(4, "end-main-10", "end-main-11")
  defp get_block("end-main-11"), do: get_block(3, "end-main-11", "end-main-12")
  defp get_block("end-main-12"), do: get_block(2, "end-main-12", "end-main-13")
  defp get_block("end-main-13"), do: get_block(1, "end-main-13", "end-main-14")
  defp get_block("end-main-14"), do: get_block(0, "end-main-14", "")
  ## It's the end
  defp get_block(_), do: false

  defp get_block(height, hash, prev_key_hash),
    do: %{height: height, hash: hash, prev_key_hash: prev_key_hash}

  defp get_current_generation(), do: get_generation("end-main")

  def get_generation(key_hash) do
    block = get_block(key_hash)
    now = Timex.now() |> Timex.to_unix()

    %{
      "key_block" => %{
        "hash" => block.hash,
        "height" => block.height,
        "prev_key_hash" => block.prev_key_hash,
        "time" => now * 1000,
        "version" => 5
      },
      "micro_blocks" => ["mh_microhash"]
    }
  end
end
