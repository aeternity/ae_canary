defmodule AeCanaryWeb.DashboardControllerTest do
  use AeCanaryWeb.ConnCase

  alias AeCanary.Settings

  @create_attrs %{active: true, message: "some message", state: "some state"}
  @update_attrs %{active: false, message: "some updated message", state: "some updated state"}
  @invalid_attrs %{active: nil, message: nil, state: nil}

  def fixture(:dashboard) do
    {:ok, dashboard} = Settings.create_dashboard(@create_attrs)
    dashboard
  end

  describe "index" do
    test "lists all dashboard", %{conn: conn} do
      conn = get(conn, Routes.dashboard_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Dashboard"
    end
  end

  describe "new dashboard" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.dashboard_path(conn, :new))
      assert html_response(conn, 200) =~ "New Dashboard"
    end
  end

  describe "create dashboard" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.dashboard_path(conn, :create), dashboard: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.dashboard_path(conn, :show, id)

      conn = get(conn, Routes.dashboard_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Dashboard"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.dashboard_path(conn, :create), dashboard: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Dashboard"
    end
  end

  describe "edit dashboard" do
    setup [:create_dashboard]

    test "renders form for editing chosen dashboard", %{conn: conn, dashboard: dashboard} do
      conn = get(conn, Routes.dashboard_path(conn, :edit, dashboard))
      assert html_response(conn, 200) =~ "Edit Dashboard"
    end
  end

  describe "update dashboard" do
    setup [:create_dashboard]

    test "redirects when data is valid", %{conn: conn, dashboard: dashboard} do
      conn = put(conn, Routes.dashboard_path(conn, :update, dashboard), dashboard: @update_attrs)
      assert redirected_to(conn) == Routes.dashboard_path(conn, :show, dashboard)

      conn = get(conn, Routes.dashboard_path(conn, :show, dashboard))
      assert html_response(conn, 200) =~ "some updated message"
    end

    test "renders errors when data is invalid", %{conn: conn, dashboard: dashboard} do
      conn = put(conn, Routes.dashboard_path(conn, :update, dashboard), dashboard: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Dashboard"
    end
  end

  describe "delete dashboard" do
    setup [:create_dashboard]

    test "deletes chosen dashboard", %{conn: conn, dashboard: dashboard} do
      conn = delete(conn, Routes.dashboard_path(conn, :delete, dashboard))
      assert redirected_to(conn) == Routes.dashboard_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.dashboard_path(conn, :show, dashboard))
      end
    end
  end

  defp create_dashboard(_) do
    dashboard = fixture(:dashboard)
    %{dashboard: dashboard}
  end
end
