defmodule AeCanaryWeb.Exchanges.ExchangeControllerTest do
  use AeCanaryWeb.ConnCase

  alias AeCanary.Exchanges

  @moduletag :authenticated

  @create_attrs %{comment: "some comment", name: "some name"}
  @update_attrs %{comment: "some updated comment", name: "some updated name"}
  @invalid_attrs %{comment: nil, name: nil}

  def fixture(:exchange) do
    {:ok, exchange} = Exchanges.create_exchange(@create_attrs)
    exchange
  end

  describe "index" do
    test "lists all exchanges", %{conn: conn} do
      conn = get(conn, Routes.exchanges_exchange_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Exchanges"
    end
  end

  describe "new exchange" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.exchanges_exchange_path(conn, :new))
      assert html_response(conn, 200) =~ "New Exchange"
    end
  end

  describe "create exchange" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.exchanges_exchange_path(conn, :create), exchange: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.exchanges_exchange_path(conn, :show, id)

      conn = get(conn, Routes.exchanges_exchange_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Exchange created successfully"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.exchanges_exchange_path(conn, :create), exchange: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Exchange"
    end
  end

  describe "edit exchange" do
    setup [:create_exchange]

    test "renders form for editing chosen exchange", %{conn: conn, exchange: exchange} do
      conn = get(conn, Routes.exchanges_exchange_path(conn, :edit, exchange))
      assert html_response(conn, 200) =~ "Edit Exchange"
    end
  end

  describe "update exchange" do
    setup [:create_exchange]

    test "redirects when data is valid", %{conn: conn, exchange: exchange} do
      conn =
        put(conn, Routes.exchanges_exchange_path(conn, :update, exchange), exchange: @update_attrs)

      assert redirected_to(conn) == Routes.exchanges_exchange_path(conn, :show, exchange)

      conn = get(conn, Routes.exchanges_exchange_path(conn, :show, exchange))
      assert html_response(conn, 200) =~ "some updated comment"
    end

    test "renders errors when data is invalid", %{conn: conn, exchange: exchange} do
      conn =
        put(conn, Routes.exchanges_exchange_path(conn, :update, exchange),
          exchange: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Exchange"
    end
  end

  describe "delete exchange" do
    setup [:create_exchange]

    test "deletes chosen exchange", %{conn: conn, exchange: exchange} do
      conn = delete(conn, Routes.exchanges_exchange_path(conn, :delete, exchange))
      assert redirected_to(conn) == Routes.exchanges_exchange_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.exchanges_exchange_path(conn, :show, exchange))
      end
    end
  end

  defp create_exchange(_) do
    exchange = fixture(:exchange)
    %{exchange: exchange}
  end
end
