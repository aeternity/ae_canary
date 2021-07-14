defmodule AeCanary.ForkMonitorTest do
  use AeCanary.DataCase

  alias AeCanary.ForkMonitor.Model
  alias AeCanary.ForkMonitor.Model.Block

  test "Insert with branches and detect forks" do
    Model.ChainWalker.updateChainEnds(50_000)

    branch_points = Model.duplicateParentHashes()

    assert ["end-main-10", "end-main-4"] = Enum.sort(branch_points)

    assert 14 = maxHeight = Model.max_height()

    forkBeginnings = Model.forkBeginnings(maxHeight - 1000, branch_points)

    assert 4 = length(forkBeginnings)

    assert [
             %{keyhash: "end-main-3", lastKeyHash: "end-main-4"},
             %{keyhash: "end-main-9", lastKeyHash: "end-main-10"},
             %{keyhash: "end1-2", lastKeyHash: "end-main-4"},
             %{keyhash: "end2-2", lastKeyHash: "end-main-10"}
           ] =
             forkBeginnings
             |> Enum.map(fn b -> %{keyhash: b.keyHash, lastKeyHash: b.lastKeyHash} end)
             |> Enum.sort()

    assert [
             %{
               forkBranchPoint: "end-main-10",
               forkEnd: %Block{keyHash: "end2"},
               forkLength: 3,
               forkStart: %Block{keyHash: "end2-2"}
             },
             %{
               forkBranchPoint: "end-main-10",
               forkEnd: %Block{keyHash: "end-main"},
               forkLength: 10,
               forkStart: %Block{keyHash: "end-main-9"}
             },
             %{
               forkBranchPoint: "end-main-4",
               forkEnd: %Block{keyHash: "end1"},
               forkLength: 3,
               forkStart: %Block{keyHash: "end1-2"}
             },
             %{
               forkBranchPoint: "end-main-4",
               forkEnd: %Block{keyHash: "end-main"},
               forkLength: 4,
               forkStart: %Block{keyHash: "end-main-3"}
             }
           ] = Enum.sort(Model.Detector.checkForForks())
  end

  test "Resume insertion after incomplete initial insert" do
    Model.ChainWalker.updateChainEnds(50_000)
    assert 21 = length(Model.list_blocks())

    ## We have the full tree. Break a link in the chain to simulate an
    ## incomplete insertion run. This will leave one of the branches dangling

    ## Unlink end1-1 from its parent (end1-2)
    fork1Block = Model.get_block!("end1-1")
    attrs = %{lastKeyHash: nil}
    {:ok, _} = Model.update_block(fork1Block, attrs)

    ## then delete the unlinked parent block
    fork1MiddleBlock = Model.get_block!("end1-2")
    Model.delete_block(fork1MiddleBlock)

    ## We should now have one block fewer
    assert 20 = length(Model.list_blocks())

    ## and two dangling blocks - the genesis block and our newly detached one
    assert 2 = length(Model.unattachedBlocks())

    ## re-run the startup insertion routine
    Model.ChainWalker.updateChainEnds(50_000)

    ## now we have everything again
    assert 21 = length(Model.list_blocks())

    ## For good measure make sure fork detection still works on the chain
    branch_points = Model.duplicateParentHashes()

    assert ["end-main-10", "end-main-4"] = Enum.sort(branch_points)

    assert 14 = maxHeight = Model.max_height()

    forkBeginnings = Model.forkBeginnings(maxHeight - 1000, branch_points)

    assert 4 = length(forkBeginnings)

    assert [
             %{
               forkBranchPoint: "end-main-10",
               forkEnd: %Block{keyHash: "end2"},
               forkLength: 3,
               forkStart: %Block{keyHash: "end2-2"}
             },
             %{
               forkBranchPoint: "end-main-10",
               forkEnd: %Block{keyHash: "end-main"},
               forkLength: 10,
               forkStart: %Block{keyHash: "end-main-9"}
             },
             %{
               forkBranchPoint: "end-main-4",
               forkEnd: %Block{keyHash: "end1"},
               forkLength: 3,
               forkStart: %Block{keyHash: "end1-2"}
             },
             %{
               forkBranchPoint: "end-main-4",
               forkEnd: %Block{keyHash: "end-main"},
               forkLength: 4,
               forkStart: %Block{keyHash: "end-main-3"}
             }
           ] = Enum.sort(Model.Detector.checkForForks())
  end

  test "Insertion stops at very small configured max depth" do
    Model.ChainWalker.updateChainEnds(2)
    assert 5 = length(Model.list_blocks())
  end

  test "Insertion stops between forks" do
    Model.ChainWalker.updateChainEnds(6)
    assert 10 = length(Model.list_blocks())
  end

  test "Detect forks in partial tree" do
    Model.ChainWalker.updateChainEnds(6)
    branch_points = Model.duplicateParentHashes()

    assert ["end-main-4"] = Enum.sort(branch_points)

    assert 14 = maxHeight = Model.max_height()

    forkBeginnings = Model.forkBeginnings(maxHeight - 1000, branch_points)

    assert 2 = length(forkBeginnings)

    assert [
             %{
               forkBranchPoint: "end-main-4",
               forkEnd: %Block{keyHash: "end1"},
               forkLength: 3,
               forkStart: %Block{keyHash: "end1-2"}
             },
             %{
               forkBranchPoint: "end-main-4",
               forkEnd: %Block{keyHash: "end-main"},
               forkLength: 4,
               forkStart: %Block{keyHash: "end-main-3"}
             }
           ] = Enum.sort(Model.Detector.checkForForks())
  end

  test "Delete old blocks starting in the middle of a fork" do
    Model.ChainWalker.updateChainEnds(50_000)
    assert 21 = length(Model.list_blocks())
    Model.delete_below_height(6)
    assert 14 = length(Model.list_blocks())
  end

  test "Alert identified when fork goes from length 2 to 3" do
    Model.ChainWalker.updateChainEnds(50_000)

    ## Delete the top block from one of the forks to reduce its length to 2
    topBlock = Model.get_block!("end1")
    Model.delete_block(topBlock)

    assert [
             %{
               forkBranchPoint: "end-main-10",
               forkEnd: %Block{keyHash: "end2"},
               forkLength: 3,
               forkStart: %Block{keyHash: "end2-2"}
             },
             %{
               forkBranchPoint: "end-main-10",
               forkEnd: %Block{keyHash: "end-main"},
               forkLength: 10,
               forkStart: %Block{keyHash: "end-main-9"}
             },
             %{
               forkBranchPoint: "end-main-4",
               # Only reaches end1-1 not end1
               forkEnd: %Block{keyHash: "end1-1"},
               # This one now only length 2
               forkLength: 2,
               forkStart: %Block{keyHash: "end1-2"}
             },
             %{
               forkBranchPoint: "end-main-4",
               forkEnd: %Block{keyHash: "end-main"},
               forkLength: 4,
               forkStart: %Block{keyHash: "end-main-3"}
             }
           ] = prevForks = Enum.sort(Model.Detector.checkForForks())

    ## Re-run the updater to re-add the third block to the fork
    Model.ChainWalker.updateChainEnds(50_000)

    forks = Model.Detector.checkForForks()

    ## Now we have our alert. Fork length went from 2 to 3
    assert [
             %{
               forkBranchPoint: "end-main-4",
               forkEnd: %Block{
                 height: 13,
                 keyHash: "end1"
               },
               forkLength: 3,
               forkStart: %Block{
                 height: 11,
                 keyHash: "end1-2"
               }
             }
           ] = AeCanary.ForkMonitor.Model.Alert.alertForForks(prevForks, forks)
  end
end
