defmodule AeCanary.ForkMonitor.Model.Detector do
  alias AeCanary.ForkMonitor.Model

  @doc """
  Detect forks in the local database copy of the chain.
  Assumes the database is complete
  """
  def checkForForks() do
    ## Find all blocks that have the same parent as another block
    forkBeginningHashes = Model.duplicateParentHashes()

    height = Model.max_height()

    forkBeginnings = Model.forkBeginnings(height - 1000, forkBeginningHashes)

    Enum.map(forkBeginnings, fn startBlock ->
      fork =
        forwardSearch(startBlock.keyHash)
        |> List.flatten()
        |> Enum.sort_by(fn b -> b.height end)

      forkEndBlock = List.last(fork)

      %{
        forkLength: forkEndBlock.height - startBlock.height + 1,
        forkStart: startBlock,
        forkBranchPoint: startBlock.lastKeyHash,
        forkEnd: forkEndBlock
      }
    end)
  end

  defp forwardSearch(keyHash) do
    startBlock = Model.get_block!(keyHash)
    fork = [startBlock]
    allFutureBlocks = Model.allFutureBlocks(startBlock.height)

    ## Create a way to move the "wrong" way up the tree from Parent to Child
    lastKeyHashMapping =
      Enum.reduce(allFutureBlocks, Map.new(), fn block, acc ->
        case Map.get(acc, block.lastKeyHash) do
          nil ->
            Map.put(acc, block.lastKeyHash, [block.keyHash])

          entries ->
            Map.put(acc, block.lastKeyHash, [block.keyHash | entries])
        end
      end)

    ## and a simple map from hash to full block
    keyHashBlockMap =
      Enum.reduce(allFutureBlocks, Map.new(), fn block, acc ->
        Map.put(acc, block.keyHash, block)
      end)

    forwardSearch(keyHash, lastKeyHashMapping, keyHashBlockMap, fork)
  end

  defp forwardSearch(keyHash, lastKeyHashMapping, keyHashBlockMap, fork) do
    nextHashes = Map.get(lastKeyHashMapping, keyHash)

    case nextHashes do
      nil ->
        fork

      [nextHash] ->
        ## one next block, keep going
        block = Map.get(keyHashBlockMap, nextHash)
        forwardSearch(nextHash, lastKeyHashMapping, keyHashBlockMap, [block | fork])

      _ ->
        ## Multiple parents
        furtherForks = Enum.map(nextHashes, fn forkStartHash -> forwardSearch(forkStartHash) end)
        [furtherForks | fork]
    end
  end
end
