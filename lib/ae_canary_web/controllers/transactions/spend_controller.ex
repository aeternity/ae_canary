defmodule AeCanaryWeb.Transactions.SpendController do
  use AeCanaryWeb, :controller

  alias AeCanary.Transactions
  alias AeCanary.Transactions.Spend

  def index(conn, _params) do
    spend_txs = Transactions.list_spend_txs()
    render(conn, "index.html", spend_txs: spend_txs)
  end

  def new(conn, _params) do
    changeset = Transactions.change_spend(%Spend{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"spend" => spend_params}) do
    case Transactions.create_spend(spend_params) do
      {:ok, spend} ->
        conn
        |> put_flash(:info, "Spend created successfully.")
        |> redirect(to: Routes.transactions_spend_path(conn, :show, spend))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    spend = Transactions.get_spend!(id)
    render(conn, "show.html", spend: spend)
  end

  def edit(conn, %{"id" => id}) do
    spend = Transactions.get_spend!(id)
    changeset = Transactions.change_spend(spend)
    render(conn, "edit.html", spend: spend, changeset: changeset)
  end

  def update(conn, %{"id" => id, "spend" => spend_params}) do
    spend = Transactions.get_spend!(id)

    case Transactions.update_spend(spend, spend_params) do
      {:ok, spend} ->
        conn
        |> put_flash(:info, "Spend updated successfully.")
        |> redirect(to: Routes.transactions_spend_path(conn, :show, spend))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", spend: spend, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    spend = Transactions.get_spend!(id)
    {:ok, _spend} = Transactions.delete_spend(spend)

    conn
    |> put_flash(:info, "Spend deleted successfully.")
    |> redirect(to: Routes.transactions_spend_path(conn, :index))
  end
end
