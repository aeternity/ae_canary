defmodule AeCanary.Settings.Dashboard do
  use Ecto.Schema
  import Ecto.Changeset

  schema "dashboard" do
    field :active, :boolean, default: false
    field :icon, :string
    field :title, :string
    field :footer, :string
    field :message, :string
    field :state, :string
    field :is_public, :boolean, default: false
    field :date, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(dashboard, attrs) do
    dashboard
    |> cast(attrs, [:state, :message, :active, :icon, :title, :footer, :is_public, :date])
    |> validate_required([:state, :message, :active, :title])
  end
end
