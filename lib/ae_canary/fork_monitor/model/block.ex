defmodule AeCanary.ForkMonitor.Model.Block do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:keyHash, :string, autogenerate: false}

  schema "blocks" do
    field :height, :integer
    field :timestamp, :utc_datetime
    field :backfill, :boolean

    belongs_to(:last, AeCanary.ForkMonitor.Model.Block,
      foreign_key: :lastKeyHash,
      references: :keyHash,
      type: :string
    )

    timestamps()
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, [:height, :keyHash, :lastKeyHash, :timestamp, :backfill])
    |> validate_required([:height, :keyHash])
    |> unique_constraint(:keyHash, name: :blocks_pkey)
  end
end
