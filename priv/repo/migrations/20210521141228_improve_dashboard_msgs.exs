defmodule AeCanary.Repo.Migrations.ImproveDashboardMsgs do
  use Ecto.Migration

  def change do
    alter table(:dashboard) do
      add :icon, :string
      add :title, :string
      add :is_public, :boolean
      add :footer, :string
    end

  end
end
