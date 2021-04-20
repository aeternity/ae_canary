defmodule AeCanary.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Argon2

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :pass_hash, :string
    field :name, :string
    field :comment, :string
    field :role, Ecto.Enum, values: [:admin, :user, :archived]

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :pass_hash, :name, :role, :comment])
    |> put_password_hash()
    |> validate_required([:email, :pass_hash, :name, :role, :comment])
    |> unique_constraint(:email)

  end
  
  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, pass_hash: Argon2.hash_pwd_salt(password))
  end
  defp put_password_hash(changeset), do: changeset

end
