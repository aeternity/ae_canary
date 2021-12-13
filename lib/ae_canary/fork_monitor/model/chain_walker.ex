defmodule AeCanary.ForkMonitor.Model.ChainWalker do
  require Logger

  alias AeCanary.ForkMonitor.Model

  ## Inserting transactions.
  ## This mechanism traverses backwards from chain ends until it encounters a block it already has, then stops.
  ## This is potentially not enough to sync transactions, because we will have transactions created later than the chain end came into existence.
  ## So.... heuristic needed.
  ## For initial bootstrapping we need to fetch all transactions for all blocks held here
  ## After that we could fetch transactions down a small number of heights from the top to be sure we have everything
  ## How do we know how far deep to go??
  ## Could stop fetching transactions when we reach a keyblock that has at least one transaction, by querying the transactions table.
  ## This test be broken by keyblocks that don't have any transactions.... But if we always traverse a few keyblocks down from the ends

  def updateChainEnds(max_depth, notify_pid \\ nil) do
    ## We can only retrieve transactions from the main fork - the node refuses to send us transactions from the other chain ends.
    ## We would like transactions to at least have the containing keyblock stored in the blocks table, so grab the
    ## current generation as a way to find which chain end is the main fork.
    {:ok, current_generation} = AeCanary.Node.Api.current_generation()

    uniqueChainEnds = getChainEnds()

    topHeight =
      Enum.map(uniqueChainEnds, fn e ->
        if e.block == false do
          0
        else
          e.block["height"]
        end
      end)
      |> Enum.max()

    stopAtHeight = max(0, topHeight - max_depth)

    Logger.debug("Found top height of #{topHeight}, stopping at height #{stopAtHeight}")

    ## Sometimes the query arrives to a different node that doesn't yet have one or more of the chainEnds
    uniqueChainEnds =
      Enum.reject(uniqueChainEnds, fn e ->
        e.block == false or e.block["height"] < stopAtHeight
      end)

    Enum.map(uniqueChainEnds, fn e ->
      Logger.debug("Starting with chain end #{e.hash} (#{e.block["height"]})")
    end)

    chainEndHashes = Enum.map(uniqueChainEnds, fn e -> e.hash end)

    notify(
      notify_pid,
      {:started_sync, Enum.map(uniqueChainEnds, fn e -> {e.hash, e.block["height"]} end),
       topHeight}
    )

    danglingBranches =
      Model.unattachedBlocks()
      |> Enum.map(fn branch -> branch.keyHash end)
      |> resolveBlocks()

    ## back trace blocks
    Enum.each(danglingBranches ++ uniqueChainEnds, fn chainEnd ->
      if chainEnd.block == false do
        Logger.error("Could not find block #{chainEnd.hash}")
      else
        backTrack(chainEnd.block, chainEnd.hash, stopAtHeight)
      end
    end)

    Logger.info("Finished inserting keyblocks")
    ## Find the chain end related to the current generation.
    case Enum.member?(chainEndHashes, current_generation["key_block"]["hash"]) do
      true ->
        Logger.info(
          "Inserting recent transactions from top #{current_generation["key_block"]["hash"]}"
        )

        Model.TransactionWalker.update_spend_transactions_from_chain_end(
          current_generation["key_block"]["hash"]
        )

      false ->
        Logger.info(
          "Not inserting recent transactions because current generation #{current_generation["key_block"]["hash"]} not in known chain ends"
        )
    end

    Logger.info("Deleting keyblocks below height #{stopAtHeight - 1} when top is at #{topHeight}")
    Model.delete_below_height(stopAtHeight - 1)
    notify(notify_pid, :finished_sync)
  end

  defp backTrack(chainEndBlock, chainEndHash, stopAtHeight) do
    ## The chain end might be so old its start is before the period of interest
    if chainEndBlock["height"] > stopAtHeight do
      insertBlock(chainEndBlock)
      prevBlock = resolveBlock(chainEndBlock["prev_key_hash"])
      backTraceOnNode(chainEndBlock, prevBlock, chainEndHash, stopAtHeight)
    end
  end

  ## Create attrs as input to the Model.changeset and hence into the db
  defp prepForDb(block) do
    %{
      height: block["height"],
      keyHash: block["hash"],
      timestamp: DateTime.from_unix!(block["time"], :millisecond)
    }
  end

  defp backTraceOnNode(keyBlock, false, chainEndHash, _stopAtHeight) do
    ## keyBlock was already installed, but we didn't find its prev block on the node
    ## This must be the origin block, so we are done with this chain
    Logger.debug(
      "End of chain with hash #{keyBlock["hash"]} when prev is #{keyBlock["prev_key_hash"]} on node #{chainEndHash}"
    )

    :done
  end

  defp backTraceOnNode(keyBlock, prevBlock, chainEndHash, stopAtHeight) do
    ## At this point keyBlock is already inserted, but until prevBlock
    ## is inserted we can't insert the foreign key reference to it from keyBlock
    case insertBlock(prevBlock) do
      :ok ->
        if rem(keyBlock["height"], 250) == 0 do
          Logger.info(
            "Inserted block at height #{prevBlock["height"]} with hash #{prevBlock["hash"]} following from chain end #{chainEndHash}"
          )
        end

        ## Now the prevBlock is stored we can insert the reference to it
        insertReference(keyBlock)

        if prevBlock["height"] > stopAtHeight do
          newPrevBlock = resolveBlock(prevBlock["prev_key_hash"])
          backTraceOnNode(prevBlock, newPrevBlock, chainEndHash, stopAtHeight)
        else
          Logger.debug(
            "Reached max depth for sync at #{prevBlock["hash"]} with height #{prevBlock["height"]}. Stopping backwards search from chain end #{chainEndHash}."
          )
        end

      :duplicate ->
        ## The prevBlock was already stored we can safely insert the reference to it
        insertReference(keyBlock)

        Logger.debug(
          "Found existing block #{prevBlock["hash"]} (#{prevBlock["height"]}). Stopping backwards search from chain end #{chainEndHash}."
        )
    end
  end

  defp insertBlock(block) do
    case Model.create_block(prepForDb(block)) do
      {:ok, _} ->
        :ok

      {:error, %Ecto.Changeset{errors: [keyHash: {"has already been taken", _}]}} ->
        :duplicate

      err ->
        Logger.error("Failed to create block #{err}")
        :error
    end
  end

  defp insertReference(topBlock) do
    block = Model.get_block!(topBlock["hash"])
    attrs = %{lastKeyHash: topBlock["prev_key_hash"]}
    Model.update_block(block, attrs)
  end

  defp getChainEnds() do
    case AeCanary.Node.Api.chain_ends() do
      {:ok, chainEnds} ->
        resolveBlocks(chainEnds)

      err ->
        Logger.error("Failed to fetch chain ends #{err}")
        []
    end
  end

  defp resolveBlocks(blocks) do
    Enum.map(blocks, fn block ->
      %{hash: block, block: resolveBlock(block)}
    end)
  end

  defp resolveBlock(keyHash) do
    case AeCanary.Node.Api.key_block_at_hash(keyHash) do
      {:ok, block} ->
        block

      _ ->
        false
    end
  end

  defp notify(nil, _message), do: :ok
  defp notify(notify_pid, message), do: send(notify_pid, message)
end
