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
end
