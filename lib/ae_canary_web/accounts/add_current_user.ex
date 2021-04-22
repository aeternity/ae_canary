defmodule AeCanaryWeb.Accounts.AddCurrentUser do
  import Plug.Conn
  def init(opts), do: opts
  def call(conn, _opts) do
    conn
    |> assign(:current_user, Guardian.Plug.current_resource(conn))  
  end
end

