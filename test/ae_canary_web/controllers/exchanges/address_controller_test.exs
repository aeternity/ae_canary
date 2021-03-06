defmodule AeCanaryWeb.Exchanges.AddressControllerTest do
  use AeCanaryWeb.ConnCase

  alias AeCanary.Exchanges

  @moduletag :authenticated

  @create_attrs %{addr: "some addr", comment: "some comment"}
  @update_attrs %{addr: "some updated addr", comment: "some updated comment"}
  @invalid_attrs %{addr: nil, comment: nil}

  def fixture(:address) do
    exchange = exchange_fixture()
    attrs = Map.put(@create_attrs, :exchange_id, exchange.id)
    {:ok, address} = Exchanges.create_address(attrs)
    address
  end

  @valid_exchange_attrs %{comment: "some comment", name: "some name"}

  def exchange_fixture(attrs \\ %{}) do
    {:ok, exchange} =
      attrs
      |> Enum.into(@valid_exchange_attrs)
      |> Exchanges.create_exchange()

    exchange
  end

  describe "index" do
    test "lists all addresses", %{conn: conn} do
      conn = get(conn, Routes.exchanges_address_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing on-chain addresses"
    end
  end

  describe "new address" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.exchanges_address_path(conn, :new))
      assert html_response(conn, 200) =~ "New Address"
    end
  end

  describe "create address" do
    test "redirects to show when data is valid", %{conn: conn} do
      exchange = exchange_fixture()
      attrs = Map.put(@create_attrs, :exchange_id, exchange.id)
      conn = post(conn, Routes.exchanges_address_path(conn, :create), address: attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.exchanges_address_path(conn, :show, id)

      conn = get(conn, Routes.exchanges_address_path(conn, :show, id))
      assert html_response(conn, 200) =~ "some addr"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.exchanges_address_path(conn, :create), address: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Address"
    end
  end

  describe "edit address" do
    setup [:create_address]

    test "renders form for editing chosen address", %{conn: conn, address: address} do
      conn = get(conn, Routes.exchanges_address_path(conn, :edit, address))
      assert html_response(conn, 200) =~ "Edit Address"
    end
  end

  describe "update address" do
    setup [:create_address]

    test "redirects when data is valid", %{conn: conn, address: address} do
      conn =
        put(conn, Routes.exchanges_address_path(conn, :update, address), address: @update_attrs)

      assert redirected_to(conn) == Routes.exchanges_address_path(conn, :show, address)

      conn = get(conn, Routes.exchanges_address_path(conn, :show, address))
      assert html_response(conn, 200) =~ "some updated addr"
    end

    test "renders errors when data is invalid", %{conn: conn, address: address} do
      conn =
        put(conn, Routes.exchanges_address_path(conn, :update, address), address: @invalid_attrs)

      assert html_response(conn, 200) =~ "Edit Address"
    end
  end

  describe "delete address" do
    setup [:create_address]

    test "deletes chosen address", %{conn: conn, address: address} do
      conn = delete(conn, Routes.exchanges_address_path(conn, :delete, address))
      assert redirected_to(conn) == Routes.exchanges_address_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.exchanges_address_path(conn, :show, address))
      end
    end
  end

  defp create_address(_) do
    address = fixture(:address)
    %{address: address}
  end
end
