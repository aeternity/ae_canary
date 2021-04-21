defmodule AeCanaryWeb.Accounts.CheckAdmin do
  import Phoenix.Controller
  import Plug.Conn
  def init(opts), do: opts
  def call(conn, _opts) do
    current_user = Guardian.Plug.current_resource(conn)
    if current_user.role == :admin do
      conn
    else
      conn
      |> put_status(:not_found)
      |> put_resp_content_type("text/plain")
      |> send_resp(401, "unauthorized")
      |> halt
    end
  end
end

