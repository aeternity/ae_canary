defmodule AeCanaryWeb.TaintedAccounts.AccountControllerTest do
  use AeCanaryWeb.ConnCase

  alias AeCanary.TaintedAccounts

  @moduletag :authenticated

  @create_attrs %{
    addr: "some addr",
    amount: 42,
    comment: "some comment",
    from_height: 42,
    last_tx_height: 42,
    white_listed: true
  }
  @update_attrs %{
    addr: "some updated addr",
    amount: 43,
    comment: "some updated comment",
    from_height: 43,
    last_tx_height: 43,
    white_listed: false
  }
  @invalid_attrs %{
    addr: nil,
    amount: nil,
    comment: nil,
    from_height: nil,
    last_tx_height: nil,
    white_listed: nil
  }

  def fixture(:account) do
    {:ok, account} = TaintedAccounts.create_account(@create_attrs)
    account
  end

  describe "index" do
    test "lists all accounts", %{conn: conn} do
      conn = get(conn, Routes.tainted_accounts_account_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing tainted accounts"
    end
  end

  describe "new account" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.tainted_accounts_account_path(conn, :new))
      assert html_response(conn, 200) =~ "New tainted account"
    end
  end

  describe "create account" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn =
        post(conn, Routes.tainted_accounts_account_path(conn, :create), account: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.tainted_accounts_account_path(conn, :show, id)

      conn = get(conn, Routes.tainted_accounts_account_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Account"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.tainted_accounts_account_path(conn, :create), account: @invalid_attrs)

      assert html_response(conn, 200) =~ "New tainted account"
    end
  end

  describe "edit account" do
    setup [:create_account]

    test "renders form for editing chosen account", %{conn: conn, account: account} do
      conn = get(conn, Routes.tainted_accounts_account_path(conn, :edit, account))
      assert html_response(conn, 200) =~ "Edit tainted account"
    end
  end

  describe "update account" do
    setup [:create_account]

    test "redirects when data is valid", %{conn: conn, account: account} do
      conn =
        put(conn, Routes.tainted_accounts_account_path(conn, :update, account),
          account: @update_attrs
        )

      assert redirected_to(conn) == Routes.tainted_accounts_account_path(conn, :show, account)

      conn = get(conn, Routes.tainted_accounts_account_path(conn, :show, account))
      assert html_response(conn, 200) =~ "some updated addr"
    end

    test "renders errors when data is invalid", %{conn: conn, account: account} do
      conn =
        put(conn, Routes.tainted_accounts_account_path(conn, :update, account),
          account: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit tainted account"
    end
  end

  describe "delete account" do
    setup [:create_account]

    test "deletes chosen account", %{conn: conn, account: account} do
      conn = delete(conn, Routes.tainted_accounts_account_path(conn, :delete, account))
      assert redirected_to(conn) == Routes.tainted_accounts_account_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.tainted_accounts_account_path(conn, :show, account))
      end
    end
  end

  defp create_account(_) do
    account = fixture(:account)
    %{account: account}
  end
end
