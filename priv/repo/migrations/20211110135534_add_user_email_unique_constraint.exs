defmodule AeCanary.Repo.Migrations.AddUserEmailUniqueConstraint do
  use Ecto.Migration

  def up do
    create unique_index(:users, [:email])
  end

  def down do
    drop unique_index(:users, [:email])
  end
end
