defmodule AeCanaryWeb.SessionController do
  use AeCanaryWeb, :controller

  alias AeCanary.{Accounts, Accounts.User}
  alias AeCanaryWeb.Accounts.Guardian

  def new(conn, _) do
    changeset = Accounts.change_user(%User{})
    maybe_user = Guardian.Plug.current_resource(conn)
    if maybe_user do
      redirect(conn, to: "/protected")
    else
      render(conn, "new.html", changeset: changeset, action: Routes.session_path(conn, :login))
    end
  end

  def login(conn, %{"user" => %{"email" => email, "password" => password}}) do
    Accounts.authenticate_user(email, password)
    |> login_reply(conn)
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out() #This module's full name is AeCanaryWeb.Accounts.Guardian.Plug,
    |> redirect(to: "/login")   #and the arguments specfied in the Guardian.Plug.sign_out()
  end                           #docs are not applicable here

  defp login_reply({:ok, %User{role: :archived}}, conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(403, "Your account had been blocked. Please contact support.")
  end
  defp login_reply({:ok, user}, conn) do
    conn
    |> put_flash(:info, "Welcome back, #{user.name}!")
    |> Guardian.Plug.sign_in(user)   #This module's full name is AeCanaryWeb.Accounts.Guardian.Plug,
    |> redirect(to: "/protected")    #and the arguments specified in the Guardian.Plug.sign_in()
  end                                #docs are not applicable here.
  defp login_reply({:error, reason}, conn) do
    conn
    |> put_flash(:error, to_string(reason))
    |> new(%{})
  end
end

