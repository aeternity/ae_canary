defmodule AeCanary.ForkMonitor.Model.TransactionWalker do
  require Logger
  alias AeCanary.ForkMonitor.Model

  @doc """
   Pull down SpendTx transactions from an aeternity node starting at the
   chain end and stopping when:
   1. We find the keyblock hash already in the spend_txs table
        AND
   2. The height is below 101 blocks from the top.

  This ensures we always fetch and store transactions from recent keyblocks that are
  still open for modification.

  Blocks in the most recent 100 transactions can be removed or moved to a different block.
  So for recent blocks we need to tidy up any microforks. Do this by grabbing the 100 last keyblock hashes
  of our chosen trunk and deleting all transactions with height in the last 100 that have
  a keyblock hash that is no longer in our 100 'proper' hashes.

  Then sync the transactions in each keyblock to match the latest view of the node, deleting and adding as needed
  """
  def update_spend_transactions_from_chain_end(chainEnd) do
    topBlock = Model.get_block!(chainEnd)
    topHeight = topBlock.height
    alwaysSyncAbove = topHeight - 101

    ## Get the 100 blocks below the chosen chainEnd and delete all blocks
    ## within the same height range that are not one of the chosen.
    Model.get_linked_keyblocks_above_height(topBlock.keyHash, alwaysSyncAbove)
    |> Enum.map(fn b -> b.keyHash end)
    |> AeCanary.Transactions.delete_unattached_transactions_above_height(alwaysSyncAbove)

    IO.inspect(topBlock, label: "insert_sync_transactions")
    insert_spend_transactions(topBlock, alwaysSyncAbove)
  end

  defp insert_spend_transactions(block, alwaysSyncAbove) do
    if block.height > alwaysSyncAbove do
      IO.inspect(block.height, label: "insert_sync_transactionsX")
      sync_spend_transactions(block)

      if not is_nil(block.lastKeyHash) do
        nextBlock = Model.get_block!(block.lastKeyHash)
        IO.inspect(nextBlock.keyHash, label: "insert_sync_transactionsY")
        insert_spend_transactions(nextBlock, alwaysSyncAbove)
      end
    else
      ## We are now inserting below the top 100. This should be a one off at startup.
      ## Insert/update until we reach a key block that already has a SpendTx
      ## (this has the side effect of updating records with the old schema)
      case AeCanary.Transactions.any_transactions_in_keyblock?(block.keyHash) do
        true ->
          IO.inspect(true, label: "any_transactions_in_keyblock? #{block.keyHash}")
          :ok

        false ->
          IO.inspect(false, label: "create_spend_transactions")
          create_spend_transactions(block)

          if not is_nil(block.lastKeyHash) do
            nextBlock = Model.get_block!(block.lastKeyHash)
            insert_spend_transactions(nextBlock, alwaysSyncAbove)
          end
      end
    end
  end

  defp create_spend_transactions(block) do
    {:ok, generations} = AeCanary.Node.Api.generations_at_hash(block.keyHash)

    Enum.each(generations["micro_blocks"], fn mh ->
      {:ok, data} = AeCanary.Node.Api.transactions_in_microblock(mh)

      spend_txs =
        data["transactions"]
        |> Enum.filter(fn tx -> tx["tx"]["type"] == "SpendTx" end)

      Enum.each(spend_txs, fn tx ->
        spend_tx = AeCanary.Transactions.decode_spend!(tx, block.timestamp, block.keyHash)
        ## IO.inspect(spend_tx, label: "Spend TX")
        {:ok, _} = AeCanary.Transactions.insert_spend(spend_tx)
      end)
    end)
  end

  defp sync_spend_transactions(block) do
    {:ok, generations} = AeCanary.Node.Api.generations_at_hash(block.keyHash)

    ## While we are above the always sync threshold:
    ## For each microblock in the generation fetch the set of transactions we
    ## have stored locally and grab the transactions from the node.
    ## Delete any in the database not in the current node set
    ## Add any from the node we do not already have in the db

    Enum.each(generations["micro_blocks"], fn mh ->
      stored = AeCanary.Transactions.list_tx_hash_in_block(mh) |> MapSet.new()
      {:ok, data} = AeCanary.Node.Api.transactions_in_microblock(mh)

      from_node =
        data["transactions"]
        |> Enum.filter(fn tx -> tx["tx"]["type"] == "SpendTx" end)
        |> Enum.map(fn t -> t["hash"] end)
        |> MapSet.new()

      deleted = MapSet.difference(stored, from_node)

      Enum.each(deleted, fn d -> AeCanary.Transactions.delete_spend_with_hash(d) end)

      ## create the set of transaction hashes we got from the node that were not already stored in the db.
      ## These are our candidate hashes for inserting
      added = MapSet.difference(from_node, stored)

      ## Filter the full transaction list to only include those that still need to be inserted
      previously_unseen_txs =
        Enum.filter(data["transactions"], fn tx -> MapSet.member?(added, tx["hash"]) end)

      Enum.each(previously_unseen_txs, fn tx ->
        spend_tx = AeCanary.Transactions.decode_spend!(tx, block.timestamp, block.keyHash)
        ## IO.inspect(spend_tx, label: "Spend TX")
        {:ok, _} = AeCanary.Transactions.insert_spend(spend_tx)
      end)
    end)
  end
end
