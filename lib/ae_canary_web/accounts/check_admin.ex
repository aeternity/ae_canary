defmodule AeCanaryWeb.Accounts.CheckAdmin do
  import Phoenix.Controller
  import Plug.Conn
  def init(opts), do: opts
  def call(conn, _opts) do
    current_user = Guardian.Plug.current_resource(conn)

    is_admin =
      case current_user do
        nil -> false
        _ ->
          if current_user.role == :admin do
            true
          else
            false
          end
      end
    if is_admin do
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

