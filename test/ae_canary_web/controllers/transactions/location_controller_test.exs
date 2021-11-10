defmodule AeCanaryWeb.Transactions.LocationControllerTest do
  use AeCanaryWeb.ConnCase

  alias AeCanary.Transactions

  @moduletag :authenticated

  @create_attrs %{
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

  def fixture(:location) do
    {:ok, location} = Transactions.create_location(@create_attrs)
    location
  end

  describe "index" do
    test "lists all location", %{conn: conn} do
      conn = get(conn, Routes.transactions_location_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Location"
    end
  end

  describe "new location" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.transactions_location_path(conn, :new))
      assert html_response(conn, 200) =~ "New Location"
    end
  end

  describe "create location" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.transactions_location_path(conn, :create), location: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.transactions_location_path(conn, :show, id)

      conn = get(conn, Routes.transactions_location_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Location"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.transactions_location_path(conn, :create), location: @invalid_attrs)

      assert html_response(conn, 200) =~ "New Location"
    end
  end

  describe "edit location" do
    setup [:create_location]

    test "renders form for editing chosen location", %{conn: conn, location: location} do
      conn = get(conn, Routes.transactions_location_path(conn, :edit, location))
      assert html_response(conn, 200) =~ "Edit Location"
    end
  end

  describe "update location" do
    setup [:create_location]

    test "redirects when data is valid", %{conn: conn, location: location} do
      conn =
        put(conn, Routes.transactions_location_path(conn, :update, location),
          location: @update_attrs
        )

      assert redirected_to(conn) == Routes.transactions_location_path(conn, :show, location)

      conn = get(conn, Routes.transactions_location_path(conn, :show, location))
      assert html_response(conn, 200) =~ "some updated block_hash"
    end

    test "renders errors when data is invalid", %{conn: conn, location: location} do
      conn =
        put(conn, Routes.transactions_location_path(conn, :update, location),
          location: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Location"
    end
  end

  describe "delete location" do
    setup [:create_location]

    test "deletes chosen location", %{conn: conn, location: location} do
      conn = delete(conn, Routes.transactions_location_path(conn, :delete, location))
      assert redirected_to(conn) == Routes.transactions_location_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.transactions_location_path(conn, :show, location))
      end
    end
  end

  defp create_location(_) do
    location = fixture(:location)
    %{location: location}
  end
end
