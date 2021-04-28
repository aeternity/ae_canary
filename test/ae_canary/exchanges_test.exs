defmodule AeCanary.ExchangesTest do
  use AeCanary.DataCase

  alias AeCanary.Exchanges

  describe "exchanges" do
    alias AeCanary.Exchanges.Exchange

    @valid_attrs %{comment: "some comment", name: "some name"}
    @update_attrs %{comment: "some updated comment", name: "some updated name"}
    @invalid_attrs %{comment: nil, name: nil}

    def exchange_fixture(attrs \\ %{}) do
      {:ok, exchange} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Exchanges.create_exchange()

      exchange
    end

    test "list_exchanges/0 returns all exchanges" do
      exchange = exchange_fixture()
      assert Exchanges.list_exchanges() == [exchange]
    end

    test "get_exchange!/1 returns the exchange with given id" do
      exchange = exchange_fixture()
      assert Exchanges.get_exchange!(exchange.id) == exchange
    end

    test "create_exchange/1 with valid data creates a exchange" do
      assert {:ok, %Exchange{} = exchange} = Exchanges.create_exchange(@valid_attrs)
      assert exchange.comment == "some comment"
      assert exchange.name == "some name"
    end

    test "create_exchange/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Exchanges.create_exchange(@invalid_attrs)
    end

    test "update_exchange/2 with valid data updates the exchange" do
      exchange = exchange_fixture()
      assert {:ok, %Exchange{} = exchange} = Exchanges.update_exchange(exchange, @update_attrs)
      assert exchange.comment == "some updated comment"
      assert exchange.name == "some updated name"
    end

    test "update_exchange/2 with invalid data returns error changeset" do
      exchange = exchange_fixture()
      assert {:error, %Ecto.Changeset{}} = Exchanges.update_exchange(exchange, @invalid_attrs)
      assert exchange == Exchanges.get_exchange!(exchange.id)
    end

    test "delete_exchange/1 deletes the exchange" do
      exchange = exchange_fixture()
      assert {:ok, %Exchange{}} = Exchanges.delete_exchange(exchange)
      assert_raise Ecto.NoResultsError, fn -> Exchanges.get_exchange!(exchange.id) end
    end

    test "change_exchange/1 returns a exchange changeset" do
      exchange = exchange_fixture()
      assert %Ecto.Changeset{} = Exchanges.change_exchange(exchange)
    end
  end
end
