defmodule AeCanary.Repo.Migrations.CreateSpendTxs do
  use Ecto.Migration

  def change do
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
