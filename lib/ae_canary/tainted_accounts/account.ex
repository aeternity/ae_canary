defmodule AeCanary.TaintedAccounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "tainted_accounts"

  schema "accounts" do
    field :addr, :string
    field :amount, :integer
    field :comment, :string
    field :from_height, :integer
    field :last_tx_height, :integer
    field :white_listed, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:addr, :from_height, :amount, :last_tx_height, :white_listed, :comment])
    |> validate_required([:addr, :from_height, :white_listed])
  end
end
