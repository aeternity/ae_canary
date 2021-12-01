defmodule AeCanary.MockChain do
  @moduledoc """
  Provide definitions for mocked chain
  """

  def get_chain_ends() do
    ["end-main", "end1", "end2"]
  end

  ## end1 chain
  def get_block("end1"), do: get_block(13, "end1", "end1-1")
  def get_block("end1-1"), do: get_block(12, "end1-1", "end1-2")
  def get_block("end1-2"), do: get_block(11, "end1-2", "end-main-4")
  ## end2 chain
  def get_block("end2"), do: get_block(7, "end2", "end2-1")
  def get_block("end2-1"), do: get_block(6, "end2-1", "end2-2")
  def get_block("end2-2"), do: get_block(5, "end2-2", "end-main-10")
  ## Main chain
  def get_block("end-main"), do: get_block(14, "end-main", "end-main-1")
  def get_block("end-main-1"), do: get_block(13, "end-main-1", "end-main-2")
  def get_block("end-main-2"), do: get_block(12, "end-main-2", "end-main-3")
  def get_block("end-main-3"), do: get_block(11, "end-main-3", "end-main-4")
  def get_block("end-main-4"), do: get_block(10, "end-main-4", "end-main-5")
  def get_block("end-main-5"), do: get_block(9, "end-main-5", "end-main-6")
  def get_block("end-main-6"), do: get_block(8, "end-main-6", "end-main-7")
  def get_block("end-main-7"), do: get_block(7, "end-main-7", "end-main-8")
  def get_block("end-main-8"), do: get_block(6, "end-main-8", "end-main-9")
  def get_block("end-main-9"), do: get_block(5, "end-main-9", "end-main-10")
  def get_block("end-main-10"), do: get_block(4, "end-main-10", "end-main-11")
  def get_block("end-main-11"), do: get_block(3, "end-main-11", "end-main-12")
  def get_block("end-main-12"), do: get_block(2, "end-main-12", "end-main-13")
  def get_block("end-main-13"), do: get_block(1, "end-main-13", "end-main-14")
  def get_block("end-main-14"), do: get_block(0, "end-main-14", "")
  ## It's the end
  def get_block(_), do: false

  defp get_block(height, hash, prev_key_hash),
    do: %{height: height, hash: hash, prev_key_hash: prev_key_hash}

  def get_current_generation(), do: get_generation("end-main")

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
      "micro_blocks" => microblocks(key_hash)
    }
  end

  def microblocks("end-main"), do: ["mh_end-main"]
  def microblocks("end-main-7"), do: ["mh_end-main-7"]
  def microblocks("end-main-13"), do: ["mh_end-main-13"]
  def microblocks("end2"), do: ["mh_end2"]
  def microblocks(_), do: []

  def microblock_hash_to_height("mh_end-main"), do: 14
  def microblock_hash_to_height("mh_end-main-7"), do: 7
  def microblock_hash_to_height("mh_end-main-13"), do: 1
  def microblock_hash_to_height("mh_end2"), do: 7

  def get_transactions("mh_end-main" = hash),
    do: %{"transactions" => [transaction(hash, "_tx1"), transaction(hash, "_tx2")]}

  def get_transactions(hash), do: %{"transactions" => [transaction(hash)]}

  defp transaction(micro_hash, hash_suffix \\ "") do
    %{
      "block_hash" => micro_hash,
      "block_height" => microblock_hash_to_height(micro_hash),
      "hash" => "th_" <> micro_hash <> hash_suffix,
      "tx" => %{
        "amount" => 20000,
        "fee" => 19_320_000_000_000,
        "nonce" => 6_355_635,
        "payload" => "ba_payload",
        "recipient_id" => "ak_rrecipient",
        "sender_id" => "ak_sender",
        "ttl" => 523_660,
        "type" => "SpendTx",
        "version" => 1
      }
    }
  end
end
