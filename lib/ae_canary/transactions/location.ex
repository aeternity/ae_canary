defmodule AeCanary.Transactions.Location do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tx_location" do
    field :block_hash, :string
    field :block_height, :integer
    field :micro_time, :utc_datetime
    field :tx_hash, :string
    field :tx_type, Ecto.Enum, values: [:spend]

    timestamps()
  end

  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, [:block_hash, :block_height, :micro_time, :tx_hash])
    |> validate_required([:block_hash, :block_height, :micro_time, :tx_hash])
  end
end
