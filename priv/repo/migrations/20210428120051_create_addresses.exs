defmodule AeCanary.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses, prefix: "exchanges") do
      add :addr, :string
      add :comment, :string
      add :exchange_id, references(:exchanges, on_delete: :nothing)

      timestamps()
    end

    create index(:addresses, [:exchange_id], prefix: "exchanges")
  end
end
