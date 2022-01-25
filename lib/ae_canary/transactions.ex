defmodule AeCanary.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Ecto.Query, warn: false
  alias AeCanary.Repo

  alias AeCanary.Transactions.Spend

  defp aetto_to_ae(aetto), do: aetto / :math.pow(10, 18)

  def decode_spend!(json, utc_datetime, keyblock_hash) do
    %{"block_height" => height, "block_hash" => mb_hash, "hash" => tx_hash, "tx" => tx} = json

    %{
      "amount" => amount,
      "fee" => fee,
      "nonce" => nonce,
      "recipient_id" => recipient_id,
      "sender_id" => sender_id,
      "type" => "SpendTx"
    } = tx

    %Spend{
      hash: tx_hash,
      amount: aetto_to_ae(amount),
      fee: aetto_to_ae(fee),
      recipient_id: recipient_id,
      sender_id: sender_id,
      nonce: nonce,
      keyblock_hash: keyblock_hash,
      block_hash: mb_hash,
      block_height: height,
      micro_time: utc_datetime
    }
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
        dynamic([spend: s], ^dynamic and s.block_height >= ^value)

      {:date_from, value}, dynamic ->
        dynamic([spend: s], ^dynamic and fragment("date(?)", s.micro_time) >= ^value)

      {:to, value}, dynamic ->
        dynamic([spend: s], ^dynamic and s.block_height <= ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end

  def list_tx_hash_in_block(mh) do
    query =
      from s in Spend,
        where: s.block_hash == ^mh,
        select: s.hash

    Repo.all(query)
  end

  def any_transactions_in_keyblock?(keyblock_hash) do
    query =
      from s in Spend,
        where: s.keyblock_hash == ^keyblock_hash

    Repo.exists?(query)
  end

  def list_spend_txs_by(params) do
    query =
      from(s in Spend,
        as: :spend,
        order_by: [desc: s.micro_time]
      )
      |> where(^dynamic_where(params))

    Repo.all(query)
  end

  def delete_unattached_transactions_above_height(validHashes, height) do
    query =
      from s in Spend,
        where: s.block_height > ^height and s.hash not in ^validHashes

    Repo.delete_all(query)
  end

  def delete_transactions(tx_hashes) do
    query =
      from s in Spend,
        where: s.hash in ^tx_hashes

    Repo.delete_all(query)
  end

  def delete_spend_with_hash(tx_hash) do
    query =
      from s in Spend,
        where: s.hash == ^tx_hash

    Repo.delete_all(query)
  end

  @chunk_sz 100
  def delete_spend_below_height(height) do
    bottom_limit = height - @chunk_sz

    delete_query =
      from s in Spend,
        where: s.block_height < ^height and s.block_height >= ^bottom_limit

    case Repo.delete_all(delete_query) do
      {qty, _} when qty < @chunk_sz ->
        :ok

      _ ->
        delete_spend_below_height(bottom_limit)
    end
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
  def insert_spend(%Spend{} = spend) do
    case Repo.get(Spend, spend.hash) do
      nil ->
        Repo.insert(spend)

      existing ->
        attrs = %{
          keyblock_hash: spend.keyblock_hash,
          block_hash: spend.block_hash,
          block_height: spend.block_height,
          micro_time: spend.micro_time,
          nonce: spend.nonce
        }

        update_spend(%Spend{} = existing, attrs)
    end
  end

  def create_spend(attrs) do
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

  def delete_all() do
    Repo.delete_all(Spend)
  end

  def aggregated_for_address(:sender_id, address, from_date) do
    from(s in Spend,
      as: :spend,
      where: s.sender_id == ^address,
      where: fragment("date(?)", s.micro_time) >= ^from_date,
      group_by: fragment("date(?)", s.micro_time),
      select: {fragment("date(?)", s.micro_time), %{count: count(), sum: sum(s.amount)}}
    )
    |> Repo.all()
    |> Enum.into(%{})
  end

  def aggregated_for_address(:recipient_id, address, from_date) do
    from(s in Spend,
      where: s.recipient_id == ^address,
      where: fragment("date(?)", s.micro_time) >= ^from_date,
      group_by: fragment("date(?)", s.micro_time),
      select: {fragment("date(?)", s.micro_time), %{count: count(), sum: sum(s.amount)}}
    )
    |> Repo.all()
    |> Enum.into(%{})
  end
end
