defmodule AeCanary.Mdw.Api do

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

  defmodule Tx do
    defmodule Spend do
      @derive [Poison.Encoder]
      defstruct [:amount, :fee, :type, :sender_id, :recipient_id]
      @type t() :: %__MODULE__{
        amount: integer(),
        fee: integer(),
        type: String.t,
        sender_id: String.t,
        recipient_id: String.t}
    end
    @derive [Poison.Encoder]
    defstruct [:block_hash, :block_height, :hash, :micro_time, :tx]
    @type t() :: %__MODULE__{
      block_hash: String.t,
      block_height: String.t,
      hash: String.t,
      micro_time: integer(),
      tx: Spend.t}
  end

  @spec status() :: {:ok, %Status{}} | :not_found | {:error, String.t}
  def status() do
    get("status", %Status{})
  end

  def outgoing_spend_txs(sender_id) do
    paged_get("txs/backward?spend.sender_id=#{sender_id}&limit=#{@limit}", %{"data" => [%Tx{tx: %Tx.Spend{}}]})
  end

  def outgoing_spend_txs(sender_id, from, to) when from > to do
    outgoing_spend_txs(sender_id, to, from)
  end
  def outgoing_spend_txs(sender_id, from, to) do
    paged_get("txs/gen/#{to}-#{from}?spend.sender_id=#{sender_id}&limit=#{@limit}", %{"data" => [%Tx{tx: %Tx.Spend{}}]})
  end

  def incoming_spend_txs(sender_id) do
    paged_get("txs/backward?spend.recipient_id=#{sender_id}&limit=#{@limit}", %{"data" => [%Tx{tx: %Tx.Spend{}}]})
  end

  def incoming_spend_txs(sender_id, from, to) when from > to do
    incoming_spend_txs(sender_id, to, from)
  end
  def incoming_spend_txs(sender_id, from, to) do
    paged_get("txs/gen/#{to}-#{from}?spend.recipient_id=#{sender_id}&limit=#{@limit}", %{"data" => [%Tx{tx: %Tx.Spend{}}]})
  end

  defp paged_get(uri, expected_fields, accum \\ []) do
    case get(uri, expected_fields) do
      {:ok, %{"data" => data, "next" => nil}} ->
        [data | accum]
        |> Enum.reverse()
        |> List.flatten()
        |> (fn res -> {:ok, res} end).()
      {:ok, %{"data" => data, "next" => next_uri}} ->
        paged_get(next_uri, expected_fields, [data, accum])
      err -> err
    end
  end

  defp get(uri, expected_fields) do
    mdw = Application.fetch_env!(:ae_canary, :mdw_url)
    case HTTPoison.get(mdw <> uri) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, parse_body(body, expected_fields)} 
      {:ok, %HTTPoison.Response{status_code: status_code, body: reason}} ->
        {:error_code, status_code, reason}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp parse_body(body, schema) do
    body
    |> Poison.decode!(as: schema)
  end

end
