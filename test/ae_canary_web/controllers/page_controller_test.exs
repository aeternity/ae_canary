defmodule AeCanaryWeb.PageControllerTest do
  use AeCanaryWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "This is the public dashboard."
  end
end
