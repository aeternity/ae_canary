defmodule AeCanary.Repo.Migrations.CreateBlocks do
  use Ecto.Migration

  def change do
    create table(:blocks, primary_key: false) do
      add(:height, :integer)
      add(:keyHash, :string, null: false, primary_key: true)
      add(:lastKeyHash, references(:blocks, column: :keyHash, on_update: :update_all, type: :string))
      add(:timestamp, :utc_datetime)

      timestamps()
    end

  end
end
