defmodule AeCanary.TaintedAccountsTest do
  use AeCanary.DataCase

  alias AeCanary.TaintedAccounts

  describe "accounts" do
    alias AeCanary.TaintedAccounts.Account

    @valid_attrs %{addr: "some addr", amount: 42, comment: "some comment", from_height: 42, last_tx_height: 42, white_listed: true}
    @update_attrs %{addr: "some updated addr", amount: 43, comment: "some updated comment", from_height: 43, last_tx_height: 43, white_listed: false}
    @invalid_attrs %{addr: nil, amount: nil, comment: nil, from_height: nil, last_tx_height: nil, white_listed: nil}

    def account_fixture(attrs \\ %{}) do
      {:ok, account} =
        attrs
        |> Enum.into(@valid_attrs)
        |> TaintedAccounts.create_account()

      account
    end

    test "list_accounts/0 returns all accounts" do
      account = account_fixture()
      assert TaintedAccounts.list_accounts() == [account]
    end

    test "get_account!/1 returns the account with given id" do
      account = account_fixture()
      assert TaintedAccounts.get_account!(account.id) == account
    end

    test "create_account/1 with valid data creates a account" do
      assert {:ok, %Account{} = account} = TaintedAccounts.create_account(@valid_attrs)
      assert account.addr == "some addr"
      assert account.amount == 42
      assert account.comment == "some comment"
      assert account.from_height == 42
      assert account.last_tx_height == 42
      assert account.white_listed == true
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = TaintedAccounts.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = account_fixture()
      assert {:ok, %Account{} = account} = TaintedAccounts.update_account(account, @update_attrs)
      assert account.addr == "some updated addr"
      assert account.amount == 43
      assert account.comment == "some updated comment"
      assert account.from_height == 43
      assert account.last_tx_height == 43
      assert account.white_listed == false
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = account_fixture()
      assert {:error, %Ecto.Changeset{}} = TaintedAccounts.update_account(account, @invalid_attrs)
      assert account == TaintedAccounts.get_account!(account.id)
    end

    test "delete_account/1 deletes the account" do
      account = account_fixture()
      assert {:ok, %Account{}} = TaintedAccounts.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> TaintedAccounts.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset" do
      account = account_fixture()
      assert %Ecto.Changeset{} = TaintedAccounts.change_account(account)
    end
  end
end
