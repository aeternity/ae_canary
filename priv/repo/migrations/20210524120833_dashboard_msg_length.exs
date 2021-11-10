defmodule AeCanary.Repo.Migrations.DashboardMsgLength do
  use Ecto.Migration

  def change do
    alter table(:dashboard) do
      modify :message, :text
    end
  end
end
