ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(AeCanary.Repo, :manual)

defmodule AeCanary.TestHelper do
  use AeCanaryWeb.ConnCase

  alias AeCanary.Accounts

  @email "joe@doe.com"
  @password "some password"
  @create_user_attrs %{
    comment: "Good guy Joe",
    email: @email,
    name: "Joe Doe",
    password: @password,
    role: "user"
  }

  def create_user_(attrs), do: create_account("user", attrs)

  def create_admin_(attrs), do: create_account("admin", attrs)

  def create_archived_user_(attrs), do: create_account("archived", attrs)

  def create_user(_), do: create_user_(%{})

  def create_admin(_), do: create_admin_(%{})

  def create_archived_user(_), do: create_archived_user_(%{})

  defp create_account(role, attrs) do
    {:ok, user} =
      attrs
      |> Enum.into(%{@create_user_attrs | role: role})
      |> Accounts.create_user()

    %{user: user}
  end

  def login(%{conn: conn}) do
    conn =
      post(conn, Routes.session_path(conn, :login), user: %{email: @email, password: @password})

    %{conn: conn}
  end

  def logout(%{conn: conn}) do
    conn = get(conn, Routes.session_path(conn, :logout))
    %{conn: conn}
  end

  def default_password, do: @password
end
