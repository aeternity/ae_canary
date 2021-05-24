defmodule :"Elixir.AeCanary.Repo.Migrations.AlterDashboard-dateAndNewTypes" do
  use Ecto.Migration

  def change do
    alter_query = "ALTER TYPE dashboard_state ADD VALUE 'success'"
    execute(alter_query)

    alter table(:dashboard) do
      add :date, :utc_datetime
    end
  end
end
