defmodule AeCanary.Repo.Migrations.CreateDashboard do
  use Ecto.Migration

  def change do
    create_query = "CREATE TYPE dashboard_state AS ENUM ('normal', 'warning', 'danger')"
    drop_query = "DROP TYPE dashboard_state"
    execute(create_query, drop_query)
    create table(:dashboard) do
      add :state, :dashboard_state
      add :message, :string
      add :active, :boolean, default: false, null: false

      timestamps()
    end

  end
end
