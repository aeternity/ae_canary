defmodule AeCanary.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    execute "CREATE SCHEMA tainted_accounts"
    create table(:accounts, prefix: "tainted_accounts") do
      add :addr, :string
      add :from_height, :integer
      add :amount, :integer
      add :last_tx_height, :integer
      add :white_listed, :boolean, default: false, null: false
      add :comment, :string

      timestamps()
    end

  end
end
