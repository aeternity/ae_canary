defmodule AeCanary.ForkMonitor.Model.ChainWalker do
  def nodes() do
    ["http://206.81.24.215:3013/v2"]
  end

  @doc """
   Configurable http client to allow simple test mocking - allow configuration
   of the module used for the get! request used to fetch the chain.
  """
  def http_client() do
    Application.get_env(:ae_canary, :fork_monitor_http_client)
  end

  def updateChainEnds() do
    uniqueChainEnds = getChainEnds()
    IO.inspect(Enum.map(uniqueChainEnds, fn e -> e.hash end), label: "chainEnds")

    danglingBranches = AeCanary.ForkMonitor.Model.unattachedBlocks()
    |> Enum.map(fn branch -> %{hash: branch.keyHash, nodeUrl: hd(nodes())} end)
    |> resolveBlocks()

    ## back trace blocks
    Enum.each(danglingBranches ++ uniqueChainEnds, fn chainEnd ->
      if chainEnd.block == false do
        IO.puts("Could not find block #{chainEnd.hash} on node #{chainEnd.nodeUrl}")
      else
        backTrack(chainEnd.nodeUrl, chainEnd.block, chainEnd.hash)
      end
    end)

    IO.puts("Finished initial insert")
  end

  defp backTrack(nodeUrl, chainEndBlock, chainEndHash) do
    insertBlock(chainEndBlock)
    prevBlock = resolveBlock(nodeUrl, chainEndBlock["prev_key_hash"])
    backTraceOnNode(nodeUrl, chainEndBlock, prevBlock, chainEndHash)
  end

  ## Create attrs as input to the Model.changeset and hence into the db
  defp prepForDb(block) do
    %{
      height: block["height"],
      keyHash: block["hash"],
      timestamp: DateTime.from_unix!(block["time"], :millisecond)
    }
  end

  defp backTraceOnNode(_nodeUrl, keyBlock, false, chainEndHash) do
    ## keyBlock was already installed, but we didn't find its prev block on the node
    ## This must be the origin block, so we are done with this chain
    IO.puts(
      "End of chain with hash #{keyBlock["hash"]} when prev is #{keyBlock["prev_key_hash"]} on node #{chainEndHash}"
    )

    :done
  end

  defp backTraceOnNode(nodeUrl, keyBlock, prevBlock, chainEndHash) do
    ## At this point keyBlock is already inserted, but until prevBlock
    ## is inserted we can't insert the foreign key reference to it from keyBlock
    case insertBlock(prevBlock) do
      :ok ->
        if rem(keyBlock["height"], 250) == 0 do
          IO.puts(
            "Inserted block at height #{prevBlock["height"]} with hash #{prevBlock["hash"]} following from chain end #{chainEndHash}"
          )
        end

        ## Now the prevBlock is stored we can insert the reference to it
        insertReference(keyBlock)
        newPrevBlock = resolveBlock(nodeUrl, prevBlock["prev_key_hash"])
        backTraceOnNode(nodeUrl, prevBlock, newPrevBlock, chainEndHash)

      :duplicate ->
        ## The prevBlock was already stored we can safely insert the reference to it
        insertReference(keyBlock)

        IO.puts(
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
        IO.puts(err, label: "Failed create block")
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
    Enum.map(blocks, fn block -> Map.put(block, :block, resolveBlock(block.nodeUrl, block.hash)) end)
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
