defmodule AeCanaryWeb.DashboardController do
  use AeCanaryWeb, :controller

  alias AeCanary.Settings
  alias AeCanary.Settings.Dashboard

  def index(conn, _params) do
    dashboard = Settings.list_dashboard()
    render(conn, "index.html", dashboards: dashboard)
  end

  def new(conn, _params) do
    changeset = Settings.change_dashboard(%Dashboard{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"dashboard" => dashboard_params}) do
    case Settings.create_dashboard(dashboard_params) do
      {:ok, dashboard} ->
        conn
        |> put_flash(:info, "Dashboard created successfully.")
        |> redirect(to: Routes.dashboard_path(conn, :show, dashboard))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    dashboard = Settings.get_dashboard!(id)
    render(conn, "show.html", dashboard: dashboard)
  end

  def edit(conn, %{"id" => id}) do
    dashboard = Settings.get_dashboard!(id)
    changeset = Settings.change_dashboard(dashboard)
    render(conn, "edit.html", dashboard: dashboard, changeset: changeset)
  end

  def update(conn, %{"id" => id, "dashboard" => dashboard_params}) do
    dashboard = Settings.get_dashboard!(id)

    case Settings.update_dashboard(dashboard, dashboard_params) do
      {:ok, dashboard} ->
        conn
        |> put_flash(:info, "Dashboard updated successfully.")
        |> redirect(to: Routes.dashboard_path(conn, :show, dashboard))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", dashboard: dashboard, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    dashboard = Settings.get_dashboard!(id)
    {:ok, _dashboard} = Settings.delete_dashboard(dashboard)

    conn
    |> put_flash(:info, "Dashboard deleted successfully.")
    |> redirect(to: Routes.dashboard_path(conn, :index))
  end

  def toggle_active(conn, %{"id" => id}) do
    dashboard = Settings.get_dashboard!(id)

    case Settings.update_dashboard(dashboard, %{active: ! dashboard.active}) do
      {:ok, dashboard} ->
        conn
        |> redirect(to: Routes.dashboard_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", dashboard: dashboard, changeset: changeset)
    end
  end
end
