defmodule AeCanary.Repo.Migrations.AlterSpendTxsAddBlockDetails do
  use Ecto.Migration

  def up do

    drop table("spend_txs")

    flush()

    create table(:spend_txs, primary_key: false) do
      add :hash, :string, null: false, primary_key: true
      add :sender_id, :string
      add :recipient_id, :string
      add :nonce, :integer
      add :amount, :float
      add :fee, :float
      add :keyblock_hash, :string
      add :block_hash, :string
      add :block_height, :integer
      add :micro_time, :utc_datetime

      timestamps()
    end

    create index("spend_txs", [:sender_id], concurrently: false)
    create index("spend_txs", [:recipient_id], concurrently: false)
    create index("spend_txs", [:keyblock_hash], concurrently: false)
    create index("spend_txs", [:block_hash], concurrently: false)
  end

  ## Put it back how it was
  def down do
    drop table("spend_txs")

    flush()

    create table(:spend_txs) do
      add :hash, :string, primary_key: true
      add :sender_id, :string
      add :recipient_id, :string
      add :nonce, :integer
      add :amount, :float
      add :fee, :float

      timestamps()
    end

    create index("spend_txs", [:sender_id], concurrently: false)
    create index("spend_txs", [:recipient_id], concurrently: false)
  end
end
