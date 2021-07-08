defmodule AeCanary.ForkMonitor.Model.ChainWalker do
  require Logger

  def nodes() do
    ["http://206.81.24.215:3013/v2"]
  end

  @doc """
   Configurable http client to allow simple test mocking - allow configuration
   of the module used for the get! request used to fetch the chain.
  """
  def http_client() do
    {:ok, v} = Application.fetch_env(:ae_canary, AeCanary.ForkMonitor)
    Keyword.get(v, :fork_monitor_http_client)
  end

  def updateChainEnds(max_depth) do
    uniqueChainEnds = getChainEnds()
    Logger.info("Starting with chain ends #{Enum.map(uniqueChainEnds, fn e -> e.hash end)}")
    topHeight = Enum.map(uniqueChainEnds, fn e -> e.block["height"] end) |> Enum.max()
    Logger.info("Found top height of #{topHeight}")
    stopAtHeight = max(0, topHeight - max_depth)

    danglingBranches =
      AeCanary.ForkMonitor.Model.unattachedBlocks()
      |> Enum.map(fn branch -> %{hash: branch.keyHash, nodeUrl: hd(nodes())} end)
      |> resolveBlocks()

    ## back trace blocks
    Enum.each(danglingBranches ++ uniqueChainEnds, fn chainEnd ->
      if chainEnd.block == false do
        Logger.info("Could not find block #{chainEnd.hash} on node #{chainEnd.nodeUrl}")
      else
        backTrack(chainEnd.nodeUrl, chainEnd.block, chainEnd.hash, stopAtHeight)
      end
    end)

    Logger.info("Finished initial insert")
  end

  defp backTrack(nodeUrl, chainEndBlock, chainEndHash, stopAtHeight) do
    ## The chain end might be so old its start is before the period of interest
    if chainEndBlock["height"] > stopAtHeight do
      insertBlock(chainEndBlock)
      prevBlock = resolveBlock(nodeUrl, chainEndBlock["prev_key_hash"])
      backTraceOnNode(nodeUrl, chainEndBlock, prevBlock, chainEndHash, stopAtHeight)
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

  defp backTraceOnNode(_nodeUrl, keyBlock, false, chainEndHash, _stopAtHeight) do
    ## keyBlock was already installed, but we didn't find its prev block on the node
    ## This must be the origin block, so we are done with this chain
    Logger.info(
      "End of chain with hash #{keyBlock["hash"]} when prev is #{keyBlock["prev_key_hash"]} on node #{chainEndHash}"
    )

    :done
  end

  defp backTraceOnNode(nodeUrl, keyBlock, prevBlock, chainEndHash, stopAtHeight) do
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
          newPrevBlock = resolveBlock(nodeUrl, prevBlock["prev_key_hash"])
          backTraceOnNode(nodeUrl, prevBlock, newPrevBlock, chainEndHash, stopAtHeight)
        else
          Logger.info(
            "Reached max depth for sync at #{prevBlock["hash"]} with height #{prevBlock["height"]}. Stopping backwards search from chain end #{chainEndHash}."
          )
        end

      :duplicate ->
        ## The prevBlock was already stored we can safely insert the reference to it
        insertReference(keyBlock)

        Logger.info(
          "Found existing block #{prevBlock["hash"]}. Stopping backwards search from chain end #{chainEndHash}."
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
    nodes()
    |> Enum.map(fn node ->
      response = http_client().get!(node <> "/status/chain-ends")

      Jason.decode!(response.body)
      |> Enum.map(fn hash -> %{nodeUrl: node, hash: hash} end)
    end)
    |> List.flatten()
    |> Enum.uniq_by(fn %{hash: hash} -> hash end)
    |> resolveBlocks()
  end

  defp resolveBlocks(blocks) do
    Enum.map(blocks, fn block ->
      Map.put(block, :block, resolveBlock(block.nodeUrl, block.hash))
    end)
  end

  defp resolveBlock(nodeUrl, keyHash) do
    block = resolveBlockOnNode(nodeUrl, keyHash)

    if block == false do
      ## Odd. We got this chain end from this nodeUrl but can't find the block there
      ## Search all the nodes
      resolveBlockOnNodes(nodes(), keyHash)
    else
      block
    end
  end

  defp resolveBlockOnNode(nodeUrl, keyHash) do
    case http_client().get!(nodeUrl <> "/key-blocks/hash/" <> keyHash) do
      %HTTPoison.Response{status_code: 200, body: body} ->
        Jason.decode!(body)

      _ ->
        false
    end
  end

  ## Go through all the nodes searching for this block
  ## only used if for some reason we didn't find it where it ought to have been
  defp resolveBlockOnNodes([nodeUrl | ns], keyHash) do
    block = resolveBlockOnNode(nodeUrl, keyHash)

    if block == false do
      resolveBlockOnNodes(ns, keyHash)
    else
      block
    end
  end

  defp resolveBlockOnNodes([], _hash) do
    false
  end
end
