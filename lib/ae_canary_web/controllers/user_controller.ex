defmodule AeCanaryWeb.UserController do
  use AeCanaryWeb, :controller

  alias AeCanary.Accounts
  alias AeCanary.Accounts.User

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.html", user: user)
  end

  def show_my(conn, _) do
    user = current_user(conn)
    render(conn, "show.html", user: user, my_account: true)
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def edit_my(conn, _) do
    user = current_user(conn)
    changeset = Accounts.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset, my_account: true)
  end

  def update_my(conn, %{"user" => user_params}) do
    user = current_user(conn)

    sanitized_params = Map.take(user_params, ["name", "email"])
    case Accounts.update_user(user, sanitized_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.user_path(conn, :show_my))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset, my_account: true)
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: Routes.user_path(conn, :index))
  end

  def edit_password(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user(user)
    render(conn, "set_password.html", user: user, changeset: changeset)
  end
  
  def edit_my_password(conn, _) do
    user = current_user(conn)
    changeset = Accounts.change_user(user)
    render(conn, "set_password.html", user: user, changeset: changeset, my_account: true)
  end


  def set_password(conn, %{"id" => user_id, "user" => %{"password" => password}}) do
    user = Accounts.get_user!(user_id)

    case Accounts.update_user(user, %{password: password}) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "set_password.html", user: user, changeset: changeset)
    end
  end

  def set_my_password(conn, %{"user" => %{"password" => password}}) do
    user = current_user(conn)

    case Accounts.update_user(user, %{password: password}) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Your account had been updated successfully.")
        |> redirect(to: Routes.user_path(conn, :show_my))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "set_password.html", user: user, changeset: changeset, my_account: true)
    end
  end


  defp current_user(conn) do
    Map.get(conn.assigns, :current_user)
  end

end
