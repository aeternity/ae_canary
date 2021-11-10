defmodule AeCanary.ForkMonitor.Model.ChainWalker do
  require Logger

  def updateChainEnds(max_depth, notify_pid \\ nil) do
    uniqueChainEnds = getChainEnds()
    Logger.info("Found chain ends #{Enum.map(uniqueChainEnds, fn e -> e.hash end)}")

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

    notify(
      notify_pid,
      {:started_sync, Enum.map(uniqueChainEnds, fn e -> {e.hash, e.block["height"]} end),
       topHeight}
    )

    danglingBranches =
      AeCanary.ForkMonitor.Model.unattachedBlocks()
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

    Logger.info("Finished inserting")
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
    case AeCanary.ForkMonitor.Model.create_block(prepForDb(block)) do
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
    block = AeCanary.ForkMonitor.Model.get_block!(topBlock["hash"])
    attrs = %{lastKeyHash: topBlock["prev_key_hash"]}
    AeCanary.ForkMonitor.Model.update_block(block, attrs)
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
