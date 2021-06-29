defmodule AeCanary.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :event_type, :string
      add :event_date, :date
      add :event_datetime, :utc_datetime
      add :email, :string
      add :sent, :boolean
      add :delivered, :boolean
      add :addr, :string
      add :boundary, :string
      add :exposure, :float
      add :limit, :float
      add :tx_hash, :string
      add :amount, :float

      timestamps()
    end

  end
end
