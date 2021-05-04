defmodule AeCanaryWeb.TaintedAccounts.AccountController do
  use AeCanaryWeb, :controller

  alias AeCanary.TaintedAccounts
  alias AeCanary.TaintedAccounts.Account

  def index(conn, _params) do
    accounts = TaintedAccounts.list_accounts()
    render(conn, "index.html", accounts: accounts)
  end

  def new(conn, _params) do
    changeset = TaintedAccounts.change_account(%Account{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"account" => account_params}) do
    case TaintedAccounts.create_account(account_params) do
      {:ok, account} ->
        conn
        |> put_flash(:info, "Account created successfully.")
        |> redirect(to: Routes.tainted_accounts_account_path(conn, :show, account))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    account = TaintedAccounts.get_account!(id)
    render(conn, "show.html", account: account)
  end

  def edit(conn, %{"id" => id}) do
    account = TaintedAccounts.get_account!(id)
    changeset = TaintedAccounts.change_account(account)
    render(conn, "edit.html", account: account, changeset: changeset)
  end

  def update(conn, %{"id" => id, "account" => account_params}) do
    account = TaintedAccounts.get_account!(id)

    case TaintedAccounts.update_account(account, account_params) do
      {:ok, account} ->
        conn
        |> put_flash(:info, "Account updated successfully.")
        |> redirect(to: Routes.tainted_accounts_account_path(conn, :show, account))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", account: account, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    account = TaintedAccounts.get_account!(id)
    {:ok, _account} = TaintedAccounts.delete_account(account)

    conn
    |> put_flash(:info, "Account deleted successfully.")
    |> redirect(to: Routes.tainted_accounts_account_path(conn, :index))
  end
end
