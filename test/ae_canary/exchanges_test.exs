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

  describe "addresses" do
    alias AeCanary.Exchanges.Address

    @valid_attrs %{addr: "some addr", comment: "some comment"}
    @update_attrs %{addr: "some updated addr", comment: "some updated comment"}
    @invalid_attrs %{addr: nil, comment: nil}

    def address_fixture(attrs \\ %{}) do
      exchange = exchange_fixture()
      attrs = Map.put(attrs, :exchange_id, exchange.id)

      {:ok, address} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Exchanges.create_address()

      address
    end

    test "list_addresses/0 returns all addresses" do
      address = address_fixture()
      assert Exchanges.list_addresses() == [address]
    end

    test "get_address!/1 returns the address with given id" do
      address = address_fixture()
      assert Exchanges.get_address!(address.id) == address
    end

    test "create_address/1 with valid data creates a address" do
      exchange = exchange_fixture()
      attrs = Map.put(@valid_attrs, :exchange_id, exchange.id)
      assert {:ok, %Address{} = address} = Exchanges.create_address(attrs)
      assert address.addr == "some addr"
      assert address.comment == "some comment"
    end

    test "create_address/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Exchanges.create_address(@invalid_attrs)
    end

    test "update_address/2 with valid data updates the address" do
      address = address_fixture()
      assert {:ok, %Address{} = address} = Exchanges.update_address(address, @update_attrs)
      assert address.addr == "some updated addr"
      assert address.comment == "some updated comment"
    end

    test "update_address/2 with invalid data returns error changeset" do
      address = address_fixture()
      assert {:error, %Ecto.Changeset{}} = Exchanges.update_address(address, @invalid_attrs)
      assert address == Exchanges.get_address!(address.id)
    end

    test "delete_address/1 deletes the address" do
      address = address_fixture()
      assert {:ok, %Address{}} = Exchanges.delete_address(address)
      assert_raise Ecto.NoResultsError, fn -> Exchanges.get_address!(address.id) end
    end

    test "change_address/1 returns a address changeset" do
      address = address_fixture()
      assert %Ecto.Changeset{} = Exchanges.change_address(address)
    end
  end
end
