defmodule AeCanaryWeb.Exchanges.ExchangeController do
  use AeCanaryWeb, :controller

  alias AeCanary.Exchanges
  alias AeCanary.Exchanges.Exchange

  def index(conn, _params) do
    exchanges = Exchanges.list_exchanges()
    render(conn, "index.html", exchanges: exchanges)
  end

  def new(conn, _params) do
    changeset = Exchanges.change_exchange(%Exchange{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"exchange" => exchange_params}) do
    case Exchanges.create_exchange(exchange_params) do
      {:ok, exchange} ->
        conn
        |> put_flash(:info, "Exchange created successfully.")
        |> redirect(to: Routes.exchanges_exchange_path(conn, :show, exchange))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    exchange = Exchanges.get_exchange_and_preload!(id)
    render(conn, "show.html", exchange: exchange)
  end

  def edit(conn, %{"id" => id}) do
    exchange = Exchanges.get_exchange!(id)
    changeset = Exchanges.change_exchange(exchange)
    render(conn, "edit.html", exchange: exchange, changeset: changeset)
  end

  def update(conn, %{"id" => id, "exchange" => exchange_params}) do
    exchange = Exchanges.get_exchange!(id)

    case Exchanges.update_exchange(exchange, exchange_params) do
      {:ok, exchange} ->
        conn
        |> put_flash(:info, "Exchange updated successfully.")
        |> redirect(to: Routes.exchanges_exchange_path(conn, :show, exchange))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", exchange: exchange, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    exchange = Exchanges.get_exchange!(id)
    {:ok, _exchange} = Exchanges.delete_exchange(exchange)

    conn
    |> put_flash(:info, "Exchange deleted successfully.")
    |> redirect(to: Routes.exchanges_exchange_path(conn, :index))
  end

  def dashboard(conn, _) do
    render(conn, "big_dashboard.html")
  end
end
