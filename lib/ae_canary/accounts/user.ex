defmodule AeCanary.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :pass_hash, :string
    field :name, :string
    field :comment, :string
    field :role, Ecto.Enum, values: [:admin, :user, :archived]

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :pass_hash, :name, :role, :comment])
    |> validate_required([:email, :pass_hash, :name, :role, :comment])
  end
end
