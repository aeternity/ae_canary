defmodule AeCanary.Repo.Migrations.AlterUserAddEmailPrefs do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :email_big_deposits, :boolean, default: false
      add :email_boundaries, :boolean, default: false
      add :email_large_forks, :boolean, default: false
    end
  end
end
