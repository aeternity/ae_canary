defmodule AeCanary.ForkMonitor.Model do
  import Ecto.Query, warn: false

  alias AeCanary.Repo
  alias AeCanary.ForkMonitor.Model.Block

  def block_exists?(hash) do
    query = from n in Block, where: n.keyHash == ^hash

    Repo.exists?(query)
  end

  def count_blocks() do
    query = from n in Block, select: count("*")
    Repo.one(query)
  end

  def list_blocks() do
    Repo.all(Block)
  end

  def get_block!(hash) do
    Repo.get_by!(Block, keyHash: hash)
  end

  def get_block_at_height!(height) do
    Repo.get_by!(Block, height: height)
  end

  def get_linked_keyblocks_above_height(hash, height) do
    keyblocks_above_height(hash, height, [])
  end

  defp keyblocks_above_height(hash, height, acc) do
    block = get_block!(hash)

    if block.height > height do
      keyblocks_above_height(block.lastKeyHash, height, [block | acc])
    else
      Enum.reverse(acc)
    end
  end

  @doc """
  Find all the hashes that are branch points in the tree,
  identified as those blocks that share a previous hash with at least one other block
  """
  def duplicateParentHashes() do
    query =
      from n in Block,
        group_by: n.lastKeyHash,
        select: n.lastKeyHash,
        having: count("*") > 1

    Repo.all(query)
  end

  def max_height() do
    query = from n in Block, select: max(n.height)

    case Repo.one(query) do
      nil -> 0
      height -> height
    end
  end

  @doc """
  Given the list of hashes that are branch points find the blocks that
  start the branches, including only those above startHeight
  """
  def forkBeginnings(startHeight, forkBeginningHashes) do
    query =
      from n in Block,
        where: n.lastKeyHash in ^forkBeginningHashes and n.height > ^startHeight

    Repo.all(query)
  end

  def allFutureBlocks(height) do
    query =
      from n in Block,
        where: n.height > ^height

    Repo.all(query)
  end

  def unattachedBlocks() do
    query =
      from n in Block,
        where: is_nil(n.lastKeyHash)

    Repo.all(query)
  end

  def create_block(attrs) do
    %Block{}
    |> Block.changeset(attrs)
    |> Repo.insert(returning: [:keyHash])
  end

  def update_block(%Block{} = block, attrs) do
    block
    |> Block.changeset(attrs)
    |> Repo.update()
  end

  def delete_block(%Block{} = block) do
    Repo.delete!(block)
  end

  @doc """
  Purge blocks below a certain height. First unlink the blocks at that height
  then remove everything below
  """
  @chunk_sz 100
  def delete_below_height(height) do
    query =
      from n in Block,
        where: n.height == ^height

    blocks = Repo.all(query)

    Enum.each(blocks, fn block ->
      ## Unlink parent
      attrs = %{lastKeyHash: nil}
      {:ok, _} = update_block(block, attrs)
    end)

    delete_below_height_in_chunks(height, @chunk_sz)
  end

  defp delete_below_height_in_chunks(height, chunk_sz) do
    bottom_limit = height - chunk_sz
    delete_query =
      from n in Block,
        where: n.height < ^height and n.height >= ^bottom_limit

    case Repo.delete_all(delete_query) do
      {qty, _} when qty < chunk_sz ->
        :ok
      _ ->
        delete_below_height_in_chunks(bottom_limit, chunk_sz)
    end
  end

  @doc """
  Utility function for artificially causing a fork by inserting dummy nodes in
  the database.
  """
  def inject_fork(starting_depth, length) do
    startHeight = max_height() - starting_depth
    forkPoint = get_block_at_height!(startHeight)
    indexes = 0..length
    forkHash = forkPoint.keyHash
    newForkPrefix = String.slice(forkHash, 0, String.length(forkHash) - 8) <> "----"
    inject_blocks(newForkPrefix, forkHash, startHeight, indexes)
  end

  def extend_fork(topHash, start_index, length) do
    block = AeCanary.ForkMonitor.Model.get_block!(topHash)
    end_index = start_index + length
    indexes = start_index..end_index
    newForkPrefix = String.slice(topHash, 0, String.length(topHash) - 8) <> "----"
    inject_blocks(newForkPrefix, topHash, block.height + 1, indexes)
  end

  defp inject_blocks(newForkPrefix, forkHash, startHeight, indexes) do
    Enum.reduce(indexes, forkHash, fn i, prevHash ->
      hash = newForkPrefix <> String.pad_leading(Integer.to_string(i), 4, "0")

      create_attrs = %{
        height: startHeight + i,
        keyHash: hash,
        timestamp: DateTime.utc_now()
      }

      create_block(create_attrs)

      block = AeCanary.ForkMonitor.Model.get_block!(hash)
      attrs = %{lastKeyHash: prevHash}
      update_block(block, attrs)

      hash
    end)
  end
end
