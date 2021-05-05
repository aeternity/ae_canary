defmodule AeCanary.Mdw.Api do

  alias AeCanary.Transactions
  alias AeCanary.Transactions.Tx

  @limit 50

  defmodule Status do
    @derive [Poison.Encoder]
    defstruct [:mdw_version, :node_version, :node_height, :node_syncing, :mdw_synced]
    @type t() :: %__MODULE__{
      mdw_version: String.t,
      node_version: String.t,
      node_height: integer(),
      node_syncing: boolean(),
      mdw_synced: boolean()}
  end

  @spec status() :: {:ok, %Status{}} | :not_found | {:error, String.t}
  def status() do
    get("status")
  end

  def outgoing_spend_txs(sender_id) do
    paged_get_all("txs/backward?spend.sender_id=#{sender_id}&limit=#{@limit}", &Tx.decode/1)
  end

  def outgoing_spend_txs(sender_id, from, to) when from > to do
    outgoing_spend_txs(sender_id, to, from)
  end
  def outgoing_spend_txs(sender_id, from, to) do
    old_locations = Transactions.list_locations_of_spend_txs_by(%{sender_id: sender_id, select: :location, from: from, to: to})
    maybe_insert =
      fn(new_batch) -> Transactions.maybe_insert_list(new_batch, old_locations) end
    delete_old =
      fn() -> Enum.each(old_locations, &Transactions.delete_tx_by_location/1) end
    paged_update_db("txs/gen/#{to}-#{from}?spend.sender_id=#{sender_id}&limit=#{@limit}", &Tx.decode/1, maybe_insert, delete_old)
    Transactions.list_locations_of_spend_txs_by(%{sender_id: sender_id, select: :tx_and_location, from: from, to: to})
  end

  def incoming_spend_txs(recipient_id) do
    old_locations = Transactions.list_locations_of_spend_txs_by(%{recipient_id: recipient_id, select: :location})
    maybe_insert =
      fn(new_batch) -> Transactions.maybe_insert_list(new_batch, old_locations) end
    delete_old =
      fn() -> Enum.each(old_locations, &Transactions.delete_tx_by_location/1) end
    paged_update_db("txs/backward?spend.recipient_id=#{recipient_id}&limit=#{@limit}", &Tx.decode/1, maybe_insert, delete_old)
    Transactions.list_txs_of_spend_txs_by(%{recipient_id: recipient_id, select: :tx_and_location})
  end

  def incoming_spend_txs(sender_id, from, to) when from > to do
    incoming_spend_txs(sender_id, to, from)
  end
  def incoming_spend_txs(recipient_id, from, to) do
    old_locations = Transactions.list_locations_of_spend_txs_by(%{recipient_id: recipient_id, select: :location, from: from, to: to})
    maybe_insert =
      fn(new_batch) -> Transactions.maybe_insert_list(new_batch, old_locations) end
    delete_old =
      fn() -> Enum.each(old_locations, &Transactions.delete_tx_by_location/1) end
    paged_update_db("txs/gen/#{to}-#{from}?spend.recipient_id=#{recipient_id}&limit=#{@limit}", &Tx.decode/1, maybe_insert, delete_old)
    Transactions.list_locations_of_spend_txs_by(%{recipient_id: recipient_id, select: :tx_and_location, from: from, to: to})
  end

  defp paged_get_all(uri, decode, accum \\ []) do
    case get(uri) do
      {:ok, %{data: data, next: nil}} ->
        [Enum.map(data, decode) | accum]
        |> Enum.reverse()
        |> List.flatten()
        |> (fn res -> {:ok, res} end).()
      {:ok, %{data: data, next: next_uri}} ->
        paged_get_all(next_uri, decode, [Enum.map(data, decode) | accum])
      err -> err
    end
  end

  defp paged_update_db(uri, decode, maybe_insert, delete_old) do
    case get(uri) do
      {:ok, %{data: data, next: nil}} ->
        res =
          Enum.map(data, decode)
          |> maybe_insert.()
        case res do
          :inserted_all -> ## forked all records
            delete_old.()
          :ok -> :ok
        end
      {:ok, %{data: data, next: next_uri}} ->
        res =
          Enum.map(data, decode)
          |> maybe_insert.()
        case res do
          :inserted_all -> ## all records are new, read next batch
            paged_update_db(next_uri, decode, maybe_insert, delete_old)
          :ok -> ## we found previous tx, abort fetching more txs
            :ok
        end
      err -> err
    end
  end

  defp get(uri) do
    mdw = Application.fetch_env!(:ae_canary, :mdw_url)
    case HTTPoison.get(mdw <> uri) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, parse_body(body)} 
      {:ok, %HTTPoison.Response{status_code: status_code, body: reason}} ->
        {:error_code, status_code, reason}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp parse_body(body) do
    body
    |> Poison.decode!(%{keys: :atoms})
  end

end
