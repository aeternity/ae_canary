defmodule AeCanary.Node.Api do
  @moduledoc """
  API for talking directly to an aeternity node rather than middleware
  """

  def status(), do: get("v2/status")

  def current_generation() do
    get("v2/generations/current")
  end

  def chain_ends() do
    get("v2/status/chain-ends")
  end

  def key_block_at_hash(hash) do
    get("v2/key-blocks/hash/" <> hash)
  end

  def generations_at_hash(hash) do
    get("v2/generations/hash/" <> hash)
  end

  def transaction_count(microblock_hash) do
    get("v2/micro-blocks/hash/" <> microblock_hash <> "/transactions/count")
  end

  defp get(uri) do
    node = Application.fetch_env!(:ae_canary, :node_url)

    url = URI.merge(node, uri) |> to_string()

    case http_client().get(url) do
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
    |> Poison.decode!()
  end

  @doc """
   Configurable http client to allow simple test mocking - allow configuration
   of the module used for the get! request used to fetch the chain.
  """
  def http_client() do
    {:ok, v} = Application.fetch_env(:ae_canary, AeCanary.ForkMonitor)
    Keyword.get(v, :fork_monitor_http_client)
  end
end
