defmodule AeCanary.Transactions.Spend do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:hash, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :hash}
  schema "spend_txs" do
    field :amount, :float
    field :fee, :float
    field :nonce, :integer
    field :recipient_id, :string
    field :sender_id, :string
    field :keyblock_hash, :string
    field :block_hash, :string
    field :block_height, :integer
    field :micro_time, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(spend, attrs) do
    spend
    |> cast(attrs, [
      :hash,
      :keyblock_hash,
      :block_hash,
      :block_height,
      :micro_time,
      :sender_id,
      :recipient_id,
      :nonce,
      :amount,
      :fee
    ])
    |> validate_required([
      :hash,
      :keyblock_hash,
      :block_hash,
      :block_height,
      :micro_time,
      :sender_id,
      :recipient_id,
      :nonce,
      :amount,
      :fee
    ])
  end
end
