defmodule AeCanary.TransactionWalkerTest do
  use AeCanary.DataCase

  alias AeCanary.Transactions

  alias AeCanary.ForkMonitor.Model
  alias AeCanary.ForkMonitor.Model.TransactionWalker

  alias AeCanary.Repo

  setup do
    build_chain()
  end

  defp build_chain(hash \\ "end-main"), do: build_chain(hash, [])

  defp build_chain("", chain),
    do:
      Enum.each(chain, fn block ->
        Model.create_block(%{
          height: block.height,
          keyHash: block.hash,
          lastKeyHash: block.prev_key_hash
        })
      end)

  defp build_chain(hash, chain) do
    block = AeCanary.MockChain.get_block(hash)
    build_chain(block.prev_key_hash, [block | chain])
  end

  test "Insert transactions for given chain end" do
    TransactionWalker.update_spend_transactions_from_chain_end("end-main")

    assert 4 == Transactions.list_spend_txs() |> length()

    assert ["th_mh_end-main_tx1", "th_mh_end-main_tx2"] ==
             Transactions.list_tx_hash_in_block("mh_end-main") |> Enum.sort()

    assert ["th_mh_end-main-7"] == Transactions.list_tx_hash_in_block("mh_end-main-7")
    assert ["th_mh_end-main-13"] == Transactions.list_tx_hash_in_block("mh_end-main-13")
  end

  test "Insert transactions for new blocks" do
    TransactionWalker.update_spend_transactions_from_chain_end("end-main-7")

    assert 2 == Transactions.list_spend_txs() |> length()
    assert [] == Transactions.list_tx_hash_in_block("mh_end-main")
    assert ["th_mh_end-main-7"] == Transactions.list_tx_hash_in_block("mh_end-main-7")
    assert ["th_mh_end-main-13"] == Transactions.list_tx_hash_in_block("mh_end-main-13")

    TransactionWalker.update_spend_transactions_from_chain_end("end-main")

    assert 4 == Transactions.list_spend_txs() |> length()

    assert ["th_mh_end-main_tx1", "th_mh_end-main_tx2"] ==
             Transactions.list_tx_hash_in_block("mh_end-main") |> Enum.sort()

    assert ["th_mh_end-main-7"] == Transactions.list_tx_hash_in_block("mh_end-main-7")
    assert ["th_mh_end-main-13"] == Transactions.list_tx_hash_in_block("mh_end-main-13")
  end

  test "Insert transaction below always_sync_height" do
    assert 0 == Transactions.list_spend_txs() |> length()
    TransactionWalker.update_spend_transactions_from_chain_end("end-main", 1)
    assert 4 == Transactions.list_spend_txs() |> length()
  end

  test "Add missing transactions" do
    TransactionWalker.update_spend_transactions_from_chain_end("end-main")
    assert 4 == Transactions.list_spend_txs() |> length()

    {1, nil} = Transactions.delete_transactions(["th_mh_end-main_tx2"])
    assert 3 == Transactions.list_spend_txs() |> length()

    TransactionWalker.update_spend_transactions_from_chain_end("end-main")
    assert 4 == Transactions.list_spend_txs() |> length()
  end

  test "Delete transaction not present on chain" do
    TransactionWalker.update_spend_transactions_from_chain_end("end-main")
    assert 4 == Transactions.list_spend_txs() |> length()

    tx = Transactions.get_spend!("th_mh_end-main_tx1")
    new_tx = Map.replace!(tx, :hash, "th_mh_end-main_tx3")
    Repo.insert!(new_tx)

    assert 5 == Transactions.list_spend_txs() |> length()

    assert ["th_mh_end-main_tx1", "th_mh_end-main_tx2", "th_mh_end-main_tx3"] ==
             Transactions.list_tx_hash_in_block("mh_end-main") |> Enum.sort()

    TransactionWalker.update_spend_transactions_from_chain_end("end-main", 1)
    assert 4 == Transactions.list_spend_txs() |> length()

    assert ["th_mh_end-main_tx1", "th_mh_end-main_tx2"] ==
             Transactions.list_tx_hash_in_block("mh_end-main") |> Enum.sort()
  end

  test "Drop transactions not present on main fork" do
    assert 15 = length(Model.list_blocks())

    build_chain("end2")
    assert 18 = length(Model.list_blocks())

    TransactionWalker.update_spend_transactions_from_chain_end("end2")

    assert 2 == Transactions.list_spend_txs() |> length()
    assert ["th_mh_end2"] == Transactions.list_tx_hash_in_block("mh_end2")
    assert ["th_mh_end-main-13"] == Transactions.list_tx_hash_in_block("mh_end-main-13")

    TransactionWalker.update_spend_transactions_from_chain_end("end-main")

    assert 4 == Transactions.list_spend_txs() |> length()
    assert [] == Transactions.list_tx_hash_in_block("mh_end2")
  end

  test "Drop transactions below unattached block" do
    TransactionWalker.update_spend_transactions_from_chain_end("end-main")
    assert 4 == Transactions.list_spend_txs() |> length()

    block11 = Model.get_block_at_height!(11)
    Model.update_block(block11, %{"lastKeyHash" => nil})

    TransactionWalker.update_spend_transactions_from_chain_end("end-main")
    assert 2 == Transactions.list_spend_txs() |> length()
  end
end
