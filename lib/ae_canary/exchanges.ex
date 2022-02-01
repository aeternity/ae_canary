defmodule AeCanary.Exchanges do
  @moduledoc """
  The Exchanges context.
  """

  import Ecto.Query, warn: false
  alias AeCanary.Repo

  alias AeCanary.Exchanges.Address
  alias AeCanary.Exchanges.Exchange

  def list_exchanges do
    Repo.all(Exchange)
  end

  def list_exchanges_and_addresses do
    Repo.all(Exchange) |> Repo.preload([:addresses])
  end

  def get_exchange!(id), do: Repo.get!(Exchange, id)

  def get_exchange_and_preload!(id), do: Repo.get!(Exchange, id) |> Repo.preload([:addresses])

  def create_exchange(attrs \\ %{}) do
    %Exchange{}
    |> Exchange.changeset(attrs)
    |> Repo.insert()
  end

  def update_exchange(%Exchange{} = exchange, attrs) do
    exchange
    |> Exchange.changeset(attrs)
    |> Repo.update()
  end

  def delete_exchange(%Exchange{} = exchange) do
    Repo.delete(exchange)
  end

  def change_exchange(%Exchange{} = exchange, attrs \\ %{}) do
    Exchange.changeset(exchange, attrs)
  end

  def list_addresses do
    Repo.all(Address)
  end

  def get_address!(id), do: Repo.get!(Address, id)

  def get_address_and_exchange!(id), do: Repo.get!(Address, id) |> Repo.preload([:exchange])

  def create_address(attrs \\ %{}) do
    %Address{}
    |> Address.changeset(attrs)
    |> Repo.insert()
  end

  def update_address(%Address{} = address, attrs) do
    address
    |> Address.changeset(attrs)
    |> Repo.update()
  end

  def delete_address(%Address{} = address) do
    Repo.delete(address)
  end

  def change_address(%Address{} = address, attrs \\ %{}) do
    Address.changeset(address, attrs)
  end
end
