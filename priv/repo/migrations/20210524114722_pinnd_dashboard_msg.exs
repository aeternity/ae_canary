defmodule AeCanary.Repo.Migrations.PinndDashboardMsg do
  use Ecto.Migration

  def change do
    alter table(:dashboard) do
      add :pinned, :boolean, default: false, null: false
    end
  end
end
