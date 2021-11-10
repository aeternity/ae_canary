defmodule AeCanaryWeb.Exchanges.AddressController do
  use AeCanaryWeb, :controller

  alias AeCanary.Exchanges
  alias AeCanary.Exchanges.Address

  def index(conn, _params) do
    addresses = Exchanges.list_addresses()
    render(conn, "index.html", addresses: addresses)
  end

  def new(conn, _params) do
    changeset = Exchanges.change_address(%Address{})
    render(conn, "new.html", changeset: changeset)
  end

  def new_by_exchange(conn, %{"exchange_id" => exchange_id}) do
    changeset = Exchanges.change_address(%Address{exchange_id: exchange_id})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"address" => address_params}) do
    case Exchanges.create_address(address_params) do
      {:ok, address} ->
        conn
        |> put_flash(:info, "Address created successfully.")
        |> redirect(to: Routes.exchanges_address_path(conn, :show, address))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    address = Exchanges.get_address_and_exchange!(id)
    render(conn, "show.html", address: address)
  end

  def edit(conn, %{"id" => id}) do
    address = Exchanges.get_address!(id)
    changeset = Exchanges.change_address(address)
    render(conn, "edit.html", address: address, changeset: changeset)
  end

  def update(conn, %{"id" => id, "address" => address_params}) do
    address = Exchanges.get_address!(id)

    case Exchanges.update_address(address, address_params) do
      {:ok, address} ->
        conn
        |> put_flash(:info, "Address updated successfully.")
        |> redirect(to: Routes.exchanges_address_path(conn, :show, address))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", address: address, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    address = Exchanges.get_address!(id)
    {:ok, _address} = Exchanges.delete_address(address)

    conn
    |> put_flash(:info, "Address deleted successfully.")
    |> redirect(to: Routes.exchanges_address_path(conn, :index))
  end
end
