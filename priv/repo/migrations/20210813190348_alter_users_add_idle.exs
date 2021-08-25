defmodule AeCanary.Repo.Migrations.AlterUsersAddIdle do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :email_idle, :boolean, default: false
    end
  end
end
