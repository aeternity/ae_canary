defmodule AeCanaryWeb.PageControllerTest do
  use AeCanaryWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "In order to see the functionality"
  end
end
