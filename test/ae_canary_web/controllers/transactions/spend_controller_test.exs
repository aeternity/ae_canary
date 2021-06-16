defmodule AeCanaryWeb.Transactions.SpendControllerTest do
  use AeCanaryWeb.ConnCase

  alias AeCanary.Transactions

  @create_attrs %{
    amount: 42,
    fee: 42,
    hash: "some_hash",
    nonce: 42,
    recipient_id: "some recipient_id",
    sender_id: "some sender_id"
  }
  @update_attrs %{
    amount: 43,
    fee: 43,
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

  @moduletag :authenticated

  def fixture(:spend) do
    {:ok, spend} = Transactions.create_spend(@create_attrs)
    spend
  end

  describe "index" do
    test "lists all spend_txs", %{conn: conn} do
      conn = get(conn, Routes.transactions_spend_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Spend txs"
    end
  end

  describe "new spend" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.transactions_spend_path(conn, :new))
      assert html_response(conn, 200) =~ "New Spend"
    end
  end

  describe "create spend" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.transactions_spend_path(conn, :create), spend: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.transactions_spend_path(conn, :show, id)

      conn = get(conn, Routes.transactions_spend_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Spend"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.transactions_spend_path(conn, :create), spend: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Spend"
    end
  end

  describe "edit spend" do
    setup [:create_spend]

    test "renders form for editing chosen spend", %{conn: conn, spend: spend} do
      conn = get(conn, Routes.transactions_spend_path(conn, :edit, spend))
      assert html_response(conn, 200) =~ "Edit Spend"
    end
  end

  describe "update spend" do
    setup [:create_spend]

    test "redirects when data is valid", %{conn: conn, spend: spend} do
      conn = put(conn, Routes.transactions_spend_path(conn, :update, spend), spend: @update_attrs)
      ## This would cause the test harness some trouble if we also updated the hash
      ## - we would then be updating the primary key so would need to use the new spend after here
      ## It should be enough to show that we can update the sender_id
      assert redirected_to(conn) == Routes.transactions_spend_path(conn, :show, spend)

      conn = get(conn, Routes.transactions_spend_path(conn, :show, spend))
      assert html_response(conn, 200) =~ "some updated sender_id"
    end

    test "renders errors when data is invalid", %{conn: conn, spend: spend} do
      conn =
        put(conn, Routes.transactions_spend_path(conn, :update, spend), spend: @invalid_attrs)

      assert html_response(conn, 200) =~ "Edit Spend"
    end
  end

  describe "delete spend" do
    setup [:create_spend]

    test "deletes chosen spend", %{conn: conn, spend: spend} do
      conn = delete(conn, Routes.transactions_spend_path(conn, :delete, spend))
      assert redirected_to(conn) == Routes.transactions_spend_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.transactions_spend_path(conn, :show, spend))
      end
    end
  end

  defp create_spend(_) do
    spend = fixture(:spend)
    %{spend: spend}
  end
end
