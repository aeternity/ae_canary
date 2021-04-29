defmodule AeCanary.Exchanges.Address do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "exchanges"

  schema "addresses" do
    field :addr, :string
    field :comment, :string
    belongs_to :exchange, AeCanary.Exchanges.Exchange

    timestamps()
  end

  @doc false
  def changeset(address, attrs) do
    address
    |> cast(attrs, [:addr, :comment, :exchange_id])
    |> validate_required([:addr, :exchange_id])
  end
end
