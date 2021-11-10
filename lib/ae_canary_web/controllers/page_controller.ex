defmodule AeCanaryWeb.PageController do
  use AeCanaryWeb, :controller

  def index(conn, _params) do
    case Map.get(conn.assigns, :current_user) do
      nil ->
        render(conn, "index.html", dashboard_msgs: AeCanary.Settings.active_dashboard_messages())

      _ ->
        render(conn, "protected.html",
          dashboard_msgs: AeCanary.Settings.active_dashboard_messages()
        )
    end
  end
end
