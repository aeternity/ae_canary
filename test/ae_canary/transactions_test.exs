defmodule AeCanary.TransactionsTest do
  use AeCanary.DataCase

  alias AeCanary.Transactions

  describe "spend_txs" do
    alias AeCanary.Transactions.Spend

    @valid_attrs %{
      amount: 42,
      fee: 42,
      hash: "some hash",
      nonce: 42,
      recipient_id: "some recipient_id",
      sender_id: "some sender_id"
    }
    @update_attrs %{
      amount: 43,
      fee: 43,
      hash: "some updated hash",
      nonce: 43,
      recipient_id: "some updated recipient_id",
      sender_id: "some updated sender_id"
    }
    @invalid_attrs %{
      amount: nil,
      fee: nil,
      hash: nil,
      nonce: nil,
      recipient_id: nil,
      sender_id: nil
    }

    def spend_fixture(attrs \\ %{}) do
      {:ok, spend} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Transactions.create_spend()

      spend
    end

    test "list_spend_txs/0 returns all spend_txs" do
      spend = spend_fixture()
      assert Transactions.list_spend_txs() == [spend]
    end

    test "get_spend!/1 returns the spend with given id" do
      spend = spend_fixture()
      assert Transactions.get_spend!(spend.hash) == spend
    end

    test "create_spend/1 with valid data creates a spend" do
      assert {:ok, %Spend{} = spend} = Transactions.create_spend(@valid_attrs)
      assert spend.amount == 42
      assert spend.fee == 42
      assert spend.hash == "some hash"
      assert spend.nonce == 42
      assert spend.recipient_id == "some recipient_id"
      assert spend.sender_id == "some sender_id"
    end

    test "create_spend/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Transactions.create_spend(@invalid_attrs)
    end

    test "update_spend/2 with valid data updates the spend" do
      spend = spend_fixture()
      assert {:ok, %Spend{} = spend} = Transactions.update_spend(spend, @update_attrs)
      assert spend.amount == 43
      assert spend.fee == 43
      assert spend.hash == "some updated hash"
      assert spend.nonce == 43
      assert spend.recipient_id == "some updated recipient_id"
      assert spend.sender_id == "some updated sender_id"
    end

    test "update_spend/2 with invalid data returns error changeset" do
      spend = spend_fixture()
      assert {:error, %Ecto.Changeset{}} = Transactions.update_spend(spend, @invalid_attrs)
      assert spend == Transactions.get_spend!(spend.hash)
    end

    test "delete_spend/1 deletes the spend" do
      spend = spend_fixture()
      assert {:ok, %Spend{}} = Transactions.delete_spend(spend)
      assert_raise Ecto.NoResultsError, fn -> Transactions.get_spend!(spend.hash) end
    end

    test "change_spend/1 returns a spend changeset" do
      spend = spend_fixture()
      assert %Ecto.Changeset{} = Transactions.change_spend(spend)
    end
  end

  describe "location" do
    alias AeCanary.Transactions.Location

    @valid_attrs %{
      block_hash: "some block_hash",
      block_height: 100,
      micro_time: "2010-04-17T14:00:00Z",
      tx_hash: "some tx_hash"
    }
    @update_attrs %{
      block_hash: "some updated block_hash",
      block_height: 101,
      micro_time: "2011-05-18T15:01:01Z",
      tx_hash: "some updated tx_hash"
    }
    @invalid_attrs %{block_hash: nil, block_height: nil, micro_time: nil, tx_hash: nil}

    def location_fixture(attrs \\ %{}) do
      {:ok, location} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Transactions.create_location()

      location
    end

    test "list_location/0 returns all location" do
      location = location_fixture()
      assert Transactions.list_location() == [location]
    end

    test "get_location!/1 returns the location with given id" do
      location = location_fixture()
      assert Transactions.get_location!(location.id) == location
    end

    test "create_location/1 with valid data creates a location" do
      assert {:ok, %Location{} = location} = Transactions.create_location(@valid_attrs)
      assert location.block_hash == "some block_hash"
      assert location.block_height == 100
      assert location.micro_time == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert location.tx_hash == "some tx_hash"
    end

    test "create_location/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Transactions.create_location(@invalid_attrs)
    end

    test "update_location/2 with valid data updates the location" do
      location = location_fixture()
      assert {:ok, %Location{} = location} = Transactions.update_location(location, @update_attrs)
      assert location.block_hash == "some updated block_hash"
      assert location.block_height == 101
      assert location.micro_time == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert location.tx_hash == "some updated tx_hash"
    end

    test "update_location/2 with invalid data returns error changeset" do
      location = location_fixture()
      assert {:error, %Ecto.Changeset{}} = Transactions.update_location(location, @invalid_attrs)
      assert location == Transactions.get_location!(location.id)
    end

    test "delete_location/1 deletes the location" do
      location = location_fixture()
      assert {:ok, %Location{}} = Transactions.delete_location(location)
      assert_raise Ecto.NoResultsError, fn -> Transactions.get_location!(location.id) end
    end

    test "change_location/1 returns a location changeset" do
      location = location_fixture()
      assert %Ecto.Changeset{} = Transactions.change_location(location)
    end
  end
end
