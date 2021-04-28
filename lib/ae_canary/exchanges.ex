defmodule AeCanary.Exchanges do
  @moduledoc """
  The Exchanges context.
  """

  import Ecto.Query, warn: false
  alias AeCanary.Repo

  alias AeCanary.Exchanges.Exchange

  @doc """
  Returns the list of exchanges.

  ## Examples

      iex> list_exchanges()
      [%Exchange{}, ...]

  """
  def list_exchanges do
    Repo.all(Exchange)
  end

  @doc """
  Gets a single exchange.

  Raises `Ecto.NoResultsError` if the Exchange does not exist.

  ## Examples

      iex> get_exchange!(123)
      %Exchange{}

      iex> get_exchange!(456)
      ** (Ecto.NoResultsError)

  """
  def get_exchange!(id), do: Repo.get!(Exchange, id)

  @doc """
  Creates a exchange.

  ## Examples

      iex> create_exchange(%{field: value})
      {:ok, %Exchange{}}

      iex> create_exchange(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_exchange(attrs \\ %{}) do
    %Exchange{}
    |> Exchange.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a exchange.

  ## Examples

      iex> update_exchange(exchange, %{field: new_value})
      {:ok, %Exchange{}}

      iex> update_exchange(exchange, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_exchange(%Exchange{} = exchange, attrs) do
    exchange
    |> Exchange.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a exchange.

  ## Examples

      iex> delete_exchange(exchange)
      {:ok, %Exchange{}}

      iex> delete_exchange(exchange)
      {:error, %Ecto.Changeset{}}

  """
  def delete_exchange(%Exchange{} = exchange) do
    Repo.delete(exchange)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking exchange changes.

  ## Examples

      iex> change_exchange(exchange)
      %Ecto.Changeset{data: %Exchange{}}

  """
  def change_exchange(%Exchange{} = exchange, attrs \\ %{}) do
    Exchange.changeset(exchange, attrs)
  end
end
