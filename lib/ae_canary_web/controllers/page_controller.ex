defmodule AeCanaryWeb.PageController do
  use AeCanaryWeb, :controller

  def index(conn, _params) do
    case Map.get(conn.assigns, :current_user) do
      nil ->
        render(conn, "index.html")
      _ ->
        render(conn, "protected.html")
    end
  end
end
