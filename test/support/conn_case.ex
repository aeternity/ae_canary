defmodule AeCanaryWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use AeCanaryWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import AeCanaryWeb.ConnCase

      alias AeCanaryWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint AeCanaryWeb.Endpoint
    end
  end

  @default_opts [
    store: :cookie,
    key: "secretkey",
    encryption_salt: "encrypted cookie salt",
    signing_salt: "signing salt"
  ]

  @signing_opts Plug.Session.init(Keyword.put(@default_opts, :encrypt, false))

  @create_attrs %{
    comment: "some comment",
    email: "some email",
    name: "some name",
    pass_hash: "some pass_hash",
    role: "admin"
  }

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(AeCanary.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(AeCanary.Repo, {:shared, self()})
    end

    {conn, user} =
      if tags[:authenticated] do
        {:ok, user} = AeCanary.Accounts.create_user(@create_attrs)

        conn =
          Phoenix.ConnTest.build_conn()
          |> Plug.Session.call(@signing_opts)
          |> Plug.Conn.fetch_session()
          |> AeCanaryWeb.Accounts.Guardian.Plug.sign_in(user)

        {conn, user}
      else
        {Phoenix.ConnTest.build_conn(), nil}
      end

    {:ok, conn: conn, user: user}
  end
end
