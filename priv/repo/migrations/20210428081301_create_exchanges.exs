defmodule AeCanary.Repo.Migrations.CreateExchanges do
  use Ecto.Migration

  def change do
    execute "CREATE SCHEMA exchanges"

    create table(:exchanges, prefix: "exchanges") do
      add :name, :string
      add :comment, :string

      timestamps()
    end
  end
end
