defmodule AeCanary.Exchanges.Exchange do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "exchanges"

  schema "exchanges" do
    field :comment, :string
    field :name, :string
    has_many :addresses, AeCanary.Exchanges.Address 

    timestamps()
  end

  @doc false
  def changeset(exchange, attrs) do
    exchange
    |> cast(attrs, [:name, :comment])
    |> validate_required([:name])
  end
end
