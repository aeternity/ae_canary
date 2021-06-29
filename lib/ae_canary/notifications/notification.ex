defmodule AeCanary.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @doc """
  Db Table definition for historical notifications

  It's a bit of a mishmash of fields useful for big deposits and boundary breaches,
  and potentially other kinds of things. But


  """
  schema "notifications" do
    field :addr, :string
    field :amount, :float
    field :boundary, Ecto.Enum, values: [:upper, :lower]
    field :delivered, :boolean
    field :email, :string
    field :event_datetime, :utc_datetime
    field :event_date, :date
    field :event_type, Ecto.Enum, values: [:big_deposit, :boundary, :fork]
    field :exposure, :float
    field :limit, :float
    field :sent, :boolean
    field :tx_hash, :string

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [
      :event_type,
      :event_date,
      :event_datetime,
      :addr,
      :delivered,
      :email,
      :sent,
      :boundary,
      :exposure,
      :limit,
      :tx_hash,
      :amount
    ])
    |> validate_required([:event_type])
  end
end
