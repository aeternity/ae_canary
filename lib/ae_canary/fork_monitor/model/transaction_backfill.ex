defmodule AeCanary.ForkMonitor.Model.TransactionBackfill do
  require Logger

  alias AeCanary.ForkMonitor.Model
  alias AeCanary.Transactions

  def backfill() do
    empty_blocks = Model.list_empty_blocks()
    Logger.info("Started backfill process for #{length(empty_blocks)} blocks")
    Enum.map(empty_blocks, fn block -> add_transactions(block) end)
    Logger.info("Finished backfill process")
  end

  def add_transactions(block) do
    block
    |> get_transactions
    |> store_transactions(block)
  end

  def store_transactions({:error, reason}, block) do
    Logger.error("Backfill fail for block #{block.keyHash} at height #{block.height}: #{reason}")
  end

  def store_transactions({:ok, txs}, block) do
    Enum.each(txs, fn tx ->
      {:ok, _} = Transactions.insert_spend(tx)
    end)

    {:ok, _} = Model.update_block(block, %{backfill: true})

    Logger.info(
      "Backfilled #{length(txs)} transaction for block #{block.keyHash} at height #{block.height}"
    )
  end

  def get_transactions(block) do
    case AeCanary.Node.Api.generations_at_hash(block.keyHash) do
      {:ok, generations} ->
        txs =
          Enum.flat_map(generations["micro_blocks"], fn mh ->
            {:ok, data} = AeCanary.Node.Api.transactions_in_microblock(mh)

            data["transactions"]
            |> Enum.filter(fn tx -> tx["tx"]["type"] == "SpendTx" end)
            |> Enum.map(fn tx ->
              Transactions.decode_spend!(tx, block.timestamp, block.keyHash)
            end)
          end)

        {:ok, txs}

      {:error_code, 400, reason} ->
        {:error, reason}
    end
  end
end
