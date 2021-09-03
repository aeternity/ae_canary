defmodule AeCanary.Repo.Migrations.UserExchangeView do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :exchange_view_id, references(:exchanges, prefix: "exchanges", on_delete: :nilify_all)
    end
  end
end
