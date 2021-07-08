defmodule AeCanary.ForkMonitorTest do
  use AeCanary.DataCase

  alias AeCanary.ForkMonitor.Model

  test "Insert with branches and detect forks" do
    Model.ChainWalker.updateChainEnds()

    branch_points = Model.duplicateParentHashes()

    assert 2 = length(branch_points)
    assert true = Enum.member?(branch_points, "end-main-4")
    assert true = Enum.member?(branch_points, "end-main-3")

    assert 100 = maxHeight = Model.max_height()

    forkBeginnings = Model.forkBeginnings(maxHeight - 1000, branch_points)

    assert 4 = length(forkBeginnings)

    assert [
             %{forkEnd: "end-main", forkLength: 3, forkStart: "end-main-2"},
             %{forkEnd: "end-main", forkLength: 4, forkStart: "end-main-3"},
             %{forkEnd: "end1", forkLength: 3, forkStart: "end1-2"},
             %{forkEnd: "end2", forkLength: 3, forkStart: "end2-2"}
           ] = Enum.sort(Model.Detector.checkForForks())
  end

  test "Resume insertion after incomplete initial insert" do
    Model.ChainWalker.updateChainEnds()
    assert 11 = length(Model.list_blocks())

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
    assert 10 = length(Model.list_blocks())

    ## and two dangling blocks - the genesis block and our newly detached one
    assert 2 = length(Model.unattachedBlocks())

    ## re-run the startup insertion routine
    Model.ChainWalker.updateChainEnds()

    ## now we have everything again
    assert 11 = length(Model.list_blocks())

    ## For good measure make sure fork detection still works on the chain
    branch_points = Model.duplicateParentHashes()

    assert 2 = length(branch_points)
    assert true = Enum.member?(branch_points, "end-main-4")
    assert true = Enum.member?(branch_points, "end-main-3")

    assert 100 = maxHeight = Model.max_height()

    forkBeginnings = Model.forkBeginnings(maxHeight - 1000, branch_points)

    assert 4 = length(forkBeginnings)

    assert [
             %{forkEnd: "end-main", forkLength: 3, forkStart: "end-main-2"},
             %{forkEnd: "end-main", forkLength: 4, forkStart: "end-main-3"},
             %{forkEnd: "end1", forkLength: 3, forkStart: "end1-2"},
             %{forkEnd: "end2", forkLength: 3, forkStart: "end2-2"}
           ] = Enum.sort(Model.Detector.checkForForks())
  end
end
