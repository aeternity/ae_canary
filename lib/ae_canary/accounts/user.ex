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
    field :email_big_deposits, :boolean, default: false
    field :email_boundaries, :boolean, default: false
    field :email_large_forks, :boolean, default: false
    field :email_idle, :boolean, default: false
    belongs_to :exchange_view, AeCanary.Exchanges.Exchange, references: :id

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :password,
      :pass_hash,
      :name,
      :role,
      :comment,
      :email_big_deposits,
      :email_boundaries,
      :email_large_forks,
      :email_idle
      :exchange_view_id
    ])
    |> put_password_hash()
    ## |> put_exchange_view(attrs)
    |> validate_required([:email, :pass_hash, :name, :role])
    |> foreign_key_constraint(:exchanges, name: :users_exchange_view_id_fkey)
    |> unique_constraint(:email)
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, pass_hash: Argon2.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset

  defp put_exchange_view(%Ecto.Changeset{valid?: true} = changeset, %{
         "exchange_view" => exchange_view
       }) do
    1 = put_assoc(changeset, :exchange_view, exchange_view)
  end

  defp put_exchange_view(changeset, _), do: changeset
end
