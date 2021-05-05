defmodule AeCanaryWeb.Transactions.LocationController do
  use AeCanaryWeb, :controller

  alias AeCanary.Transactions
  alias AeCanary.Transactions.Location

  def index(conn, _params) do
    location = Transactions.list_location()
    render(conn, "index.html", location: location)
  end

  def new(conn, _params) do
    changeset = Transactions.change_location(%Location{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"location" => location_params}) do
    case Transactions.create_location(location_params) do
      {:ok, location} ->
        conn
        |> put_flash(:info, "Location created successfully.")
        |> redirect(to: Routes.transactions_location_path(conn, :show, location))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    location = Transactions.get_location!(id)
    render(conn, "show.html", location: location)
  end

  def edit(conn, %{"id" => id}) do
    location = Transactions.get_location!(id)
    changeset = Transactions.change_location(location)
    render(conn, "edit.html", location: location, changeset: changeset)
  end

  def update(conn, %{"id" => id, "location" => location_params}) do
    location = Transactions.get_location!(id)

    case Transactions.update_location(location, location_params) do
      {:ok, location} ->
        conn
        |> put_flash(:info, "Location updated successfully.")
        |> redirect(to: Routes.transactions_location_path(conn, :show, location))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", location: location, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    location = Transactions.get_location!(id)
    {:ok, _location} = Transactions.delete_location(location)

    conn
    |> put_flash(:info, "Location deleted successfully.")
    |> redirect(to: Routes.transactions_location_path(conn, :index))
  end
end
