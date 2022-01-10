defmodule AeCanary.Repo.Migrations.AddBackfillFlagToBlock do
  use Ecto.Migration

  def up do
    alter table(:blocks) do
      add :backfill, :boolean, default: false
    end
  end

  def down do
    alter table(:blocks) do
      remove :backfill
    end
  end
end
