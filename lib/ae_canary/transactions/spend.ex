defmodule AeCanary.Transactions.Spend do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:hash, :string, autogenerate: false}
  schema "spend_txs" do
    field :amount, :float
    field :fee, :float
    field :nonce, :integer
    field :recipient_id, :string
    field :sender_id, :string

    timestamps()
  end

  @doc false
  def changeset(spend, attrs) do
    spend
    |> cast(attrs, [:hash, :sender_id, :recipient_id, :nonce, :amount, :fee])
    |> validate_required([:hash, :sender_id, :recipient_id, :nonce, :amount, :fee])
  end
end
