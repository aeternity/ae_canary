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
    field :amount, :decimal
    field :boundary, Ecto.Enum, values: [:upper, :lower]
    field :delivered, :boolean
    field :email, :string
    field :event_datetime, :utc_datetime
    field :event_date, :date

    field :event_type, Ecto.Enum,
      values: [:big_deposit, :boundary, :fork, :idle, :idle_no_microblocks, :idle_no_transactions]

    field :exposure, :decimal
    field :limit, :decimal
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
    |> update_change(:exposure, fn e -> round_decimal(e) end)
    |> update_change(:limit, fn e -> round_decimal(e) end)
    |> update_change(:amount, fn e -> round_decimal(e) end)
    |> validate_required([:event_type])
  end

  defp round_decimal(nil), do: nil
  defp round_decimal(%Decimal{} = decimal), do: Decimal.round(decimal)
end
