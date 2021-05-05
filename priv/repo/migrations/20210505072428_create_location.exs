defmodule AeCanary.Repo.Migrations.CreateLocation do
  use Ecto.Migration

  def change do
    create table(:tx_location) do
      add :block_hash, :string
      add :block_height, :integer
      add :micro_time, :utc_datetime
      add :tx_hash, :string
      add :tx_type, :string

      timestamps()
    end
  end
end
