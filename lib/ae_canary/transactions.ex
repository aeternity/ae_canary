defmodule AeCanary.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Ecto.Query, warn: false
  alias AeCanary.Repo

  alias AeCanary.Transactions.Spend
  alias AeCanary.Transactions.Location

  defmodule Tx do
    defstruct [:location, :tx]
    defp aetto_to_ae(aetto), do: aetto / :math.pow(10, 18)

    def decode(json) do
      %{block_height: height, block_hash: mb_hash, micro_time: time, hash: tx_hash, tx: tx0} =
        json

      {tx, tx_type} =
        case tx0 do
          %{
            type: "SpendTx",
            amount: amount,
            fee: fee,
            recipient_id: recipient_id,
            sender_id: sender_id
          } ->
            {%Spend{
               hash: tx_hash,
               amount: aetto_to_ae(amount),
               fee: aetto_to_ae(fee),
               recipient_id: recipient_id,
               sender_id: sender_id
             }, :spend}
        end

      utc_datetime =
        time
        |> DateTime.from_unix!(:millisecond)
        |> DateTime.truncate(:second)

      location = %Location{
        block_hash: mb_hash,
        block_height: height,
        micro_time: utc_datetime,
        tx_hash: tx_hash,
        tx_type: tx_type
      }

      %Tx{location: location, tx: tx}
    end
  end

  @doc """
  Returns the list of spend_txs.

  ## Examples

      iex> list_spend_txs()
      [%Spend{}, ...]

  """
  def list_spend_txs do
    Repo.all(Spend)
  end

  def dynamic_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:recipient_id, value}, dynamic ->
        dynamic([spend: s], ^dynamic and s.recipient_id == ^value)

      {:sender_id, value}, dynamic ->
        dynamic([spend: s], ^dynamic and s.sender_id == ^value)

      {:amount_at_least, value}, dynamic ->
        dynamic([spend: s], ^dynamic and s.amount >= ^value)

      {:from, value}, dynamic ->
        dynamic([location: l], ^dynamic and l.block_height >= ^value)

      {:date_from, value}, dynamic ->
        dynamic([location: l], ^dynamic and fragment("date(?)", l.micro_time) >= ^value)

      {:to, value}, dynamic ->
        dynamic([location: l], ^dynamic and l.block_height <= ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end

  def list_locations_of_spend_txs_by(params) do
    query =
      case params[:select] do
        :location ->
          from(l in Location,
            as: :location,
            join: s in Spend,
            as: :spend,
            on: l.tx_hash == s.hash,
            order_by: [desc: l.micro_time],
            select: l
          )
          |> where(^dynamic_where(params))

        :tx_and_location ->
          from(l in Location,
            as: :location,
            join: s in Spend,
            as: :spend,
            on: l.tx_hash == s.hash,
            order_by: [desc: l.micro_time],
            select: %Tx{location: l, tx: s}
          )
          |> where(^dynamic_where(params))
      end

    Repo.all(query)
  end

  @doc """
  Gets a single spend.

  Raises `Ecto.NoResultsError` if the Spend does not exist.

  ## Examples

      iex> get_spend!(123)
      %Spend{}

      iex> get_spend!(456)
      ** (Ecto.NoResultsError)

  """
  def get_spend!(id), do: Repo.get!(Spend, id)

  @doc """
  Creates a spend.

  ## Examples

      iex> create_spend(%{field: value})
      {:ok, %Spend{}}

      iex> create_spend(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_spend(attrs \\ %{}) do
    %Spend{}
    |> Spend.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a spend.

  ## Examples

      iex> update_spend(spend, %{field: new_value})
      {:ok, %Spend{}}

      iex> update_spend(spend, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_spend(%Spend{} = spend, attrs) do
    spend
    |> Spend.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a spend.

  ## Examples

      iex> delete_spend(spend)
      {:ok, %Spend{}}

      iex> delete_spend(spend)
      {:error, %Ecto.Changeset{}}

  """
  def delete_spend(%Spend{} = spend) do
    Repo.delete(spend)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking spend changes.

  ## Examples

      iex> change_spend(spend)
      %Ecto.Changeset{data: %Spend{}}

  """
  def change_spend(%Spend{} = spend, attrs \\ %{}) do
    Spend.changeset(spend, attrs)
  end

  @doc """
  Returns the list of location.

  ## Examples

      iex> list_location()
      [%Location{}, ...]

  """
  def list_location do
    Repo.all(Location)
  end

  @doc """
  Gets a single location.

  Raises `Ecto.NoResultsError` if the Location does not exist.

  ## Examples

      iex> get_location!(123)
      %Location{}

      iex> get_location!(456)
      ** (Ecto.NoResultsError)

  """
  def get_location!(id), do: Repo.get!(Location, id)

  @doc """
  Creates a location.

  ## Examples

      iex> create_location(%{field: value})
      {:ok, %Location{}}

      iex> create_location(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_location(attrs \\ %{}) do
    %Location{}
    |> Location.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a location.

  ## Examples

      iex> update_location(location, %{field: new_value})
      {:ok, %Location{}}

      iex> update_location(location, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_location(%Location{} = location, attrs) do
    location
    |> Location.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a location.

  ## Examples

      iex> delete_location(location)
      {:ok, %Location{}}

      iex> delete_location(location)
      {:error, %Ecto.Changeset{}}

  """
  def delete_location(%Location{} = location) do
    Repo.delete(location)
  end

  def delete_all() do
    Repo.delete_all(Location)
    Repo.delete_all(Spend)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking location changes.

  ## Examples

      iex> change_location(location)
      %Ecto.Changeset{data: %Location{}}

  """
  def change_location(%Location{} = location, attrs \\ %{}) do
    Location.changeset(location, attrs)
  end

  def delete_tx_by_location(location) do
    Repo.delete(location)

    case location.tx_type do
      :spend -> %Spend{hash: location.tx_hash} |> Repo.delete()
    end
  end

  def maybe_insert_list([], _old_list) do
    :inserted_all
  end

  def maybe_insert_list([top | new_batch_tail], old_list) do
    %Tx{location: location, tx: tx} = top
    ## TODO detect reincluded txs
    case Enum.find_index(old_list, fn l -> l.tx_hash == location.tx_hash end) do
      ## new transaction
      nil ->
        Repo.insert(location)

        case tx do
          %Spend{} -> Repo.insert(tx)
        end

        maybe_insert_list(new_batch_tail, old_list)

      ## last inserted transaction
      0 ->
        :ok

      ## some txs were kicked out
      idx ->
        Enum.slice(old_list, 1..(idx - 1))
        |> Enum.each(&delete_tx_by_location/1)

        :ok
    end
  end

  def aggregated_for_addresses(role, addresses, from_date) do
    query =
      case role do
        :sender_id ->
          from(l in Location,
            as: :location,
            join: s in Spend,
            as: :spend,
            on: l.tx_hash == s.hash,
            where: s.sender_id in ^addresses and fragment("date(?)", l.micro_time) >= ^from_date,
            group_by: [s.sender_id, fragment("date(?)", l.micro_time)],
            select: %{
              address: s.sender_id,
              date: fragment("date(?)", l.micro_time),
              txs: count(),
              sum: sum(s.amount)
            }
          )

        :recipient_id ->
          from(l in Location,
            as: :location,
            join: s in Spend,
            as: :spend,
            on: l.tx_hash == s.hash,
            where:
              s.recipient_id in ^addresses and fragment("date(?)", l.micro_time) >= ^from_date,
            group_by: [s.recipient_id, fragment("date(?)", l.micro_time)],
            select: %{
              address: s.recipient_id,
              date: fragment("date(?)", l.micro_time),
              txs: count(),
              sum: sum(s.amount)
            }
          )
      end

    query
    |> Repo.all()
  end
end
