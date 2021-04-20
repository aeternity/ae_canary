defmodule AeCanary.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create_query = "CREATE TYPE user_role AS ENUM ('admin', 'user', 'archived')"
    drop_query = "DROP TYPE user_role"
    execute(create_query, drop_query)

    create table(:users) do
      add :email, :string
      add :pass_hash, :string
      add :name, :string
      add :role, :user_role
      add :comment, :string

      timestamps()
    end

  end
end
