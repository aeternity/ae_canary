defmodule AeCanary.Notifications do
  @moduledoc """
  The Notifications context.
  """

  import Ecto.Query, warn: false
  alias AeCanary.Repo

  alias AeCanary.Notifications.Notification

  @doc """
  Returns the list of notificationsx.

  ## Examples

      iex> list_notificationsx()
      [%Notification{}, ...]

  """
  def list_notifications do
    Repo.all(Notification)
  end

  @doc """
  Gets a single notification.

  Raises `Ecto.NoResultsError` if the Notification does not exist.

  ## Examples

      iex> get_notification!(123)
      %Notification{}

      iex> get_notification!(456)
      ** (Ecto.NoResultsError)

  """
  def get_notification!(id), do: Repo.get!(Notification, id)

  @doc """
  Gets all the notifications sent for a single big deposit event.

  ## Examples

      iex> list_big_deposits("ak_abcdef", "th_21212121")
      [%Notification{}]

  """
  def list_big_deposits(addr, tx_hash) do
    query =
      from n in Notification,
        where: n.event_type == :big_deposit and n.addr == ^addr and n.tx_hash == ^tx_hash

    Repo.all(query)
  end

  def list_over_boundaries(addr, boundary, date, exposure, limit) do
    exposure = Decimal.round(Decimal.from_float(exposure))
    limit = Decimal.round(Decimal.from_float(limit))

    query =
      from n in Notification,
        where:
          n.event_type == :boundary and n.addr == ^addr and n.boundary == ^boundary and
            n.exposure == ^exposure and
            n.limit == ^limit and
            n.event_date == ^date

    Repo.all(query)
  end

  def list_idle_events(event_type, lastBlock) do
    query =
      from n in Notification,
        where: n.event_type == ^event_type and n.addr == ^lastBlock

    Repo.all(query)
  end

  @doc """
  Creates a notification.

  ## Examples

      iex> create_notification(%{field: value})
      {:ok, %Notification{}}

      iex> create_notification(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_notification(attrs \\ %{}) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a notification.

  ## Examples

      iex> update_notification(notification, %{field: new_value})
      {:ok, %Notification{}}

      iex> update_notification(notification, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_notification(%Notification{} = notification, attrs) do
    notification
    |> Notification.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a notification.

  ## Examples

      iex> delete_notification(notification)
      {:ok, %Notification{}}

      iex> delete_notification(notification)
      {:error, %Ecto.Changeset{}}

  """
  def delete_notification(%Notification{} = notification) do
    Repo.delete(notification)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notification changes.

  ## Examples

      iex> change_notification(notification)
      %Ecto.Changeset{data: %Notification{}}

  """
  def change_notification(%Notification{} = notification, attrs \\ %{}) do
    Notification.changeset(notification, attrs)
  end
end
