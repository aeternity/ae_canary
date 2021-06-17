defmodule AeCanary.SettingsTest do
  use AeCanary.DataCase

  alias AeCanary.Settings

  describe "dashboard" do
    alias AeCanary.Settings.Dashboard

    @valid_attrs %{active: true, title: "some title", message: "some message", state: "normal"}
    @update_attrs %{active: false, title: "some updated title", message: "some updated message", state: "warning"}
    @invalid_attrs %{active: nil, title: nil, message: nil, state: nil}

    def dashboard_fixture(attrs \\ %{}) do
      {:ok, dashboard} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Settings.create_dashboard()

      dashboard
    end

    test "list_dashboard/0 returns all dashboard" do
      dashboard = dashboard_fixture()
      assert Settings.list_dashboard() == [dashboard]
    end

    test "get_dashboard!/1 returns the dashboard with given id" do
      dashboard = dashboard_fixture()
      assert Settings.get_dashboard!(dashboard.id) == dashboard
    end

    test "create_dashboard/1 with valid data creates a dashboard" do
      assert {:ok, %Dashboard{} = dashboard} = Settings.create_dashboard(@valid_attrs)
      assert dashboard.active == true
      assert dashboard.message == "some message"
      assert dashboard.state == "normal"
    end

    test "create_dashboard/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Settings.create_dashboard(@invalid_attrs)
    end

    test "update_dashboard/2 with valid data updates the dashboard" do
      dashboard = dashboard_fixture()
      assert {:ok, %Dashboard{} = dashboard} = Settings.update_dashboard(dashboard, @update_attrs)
      assert dashboard.active == false
      assert dashboard.message == "some updated message"
      assert dashboard.state == "warning"
    end

    test "update_dashboard/2 with invalid data returns error changeset" do
      dashboard = dashboard_fixture()
      assert {:error, %Ecto.Changeset{}} = Settings.update_dashboard(dashboard, @invalid_attrs)
      assert dashboard == Settings.get_dashboard!(dashboard.id)
    end

    test "delete_dashboard/1 deletes the dashboard" do
      dashboard = dashboard_fixture()
      assert {:ok, %Dashboard{}} = Settings.delete_dashboard(dashboard)
      assert_raise Ecto.NoResultsError, fn -> Settings.get_dashboard!(dashboard.id) end
    end

    test "change_dashboard/1 returns a dashboard changeset" do
      dashboard = dashboard_fixture()
      assert %Ecto.Changeset{} = Settings.change_dashboard(dashboard)
    end
  end
end
