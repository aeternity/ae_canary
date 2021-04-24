defmodule AeCanaryWeb.SessionControllerTest do
  use AeCanaryWeb.ConnCase

  alias AeCanary.TestHelper, as: Helper
  import Helper, only: [create_user: 1, create_admin: 1, create_archived_user: 1]

  describe "User can login and log out" do
    setup [:create_user]

    test "Open login page", %{conn: conn} do
      conn = get(conn, Routes.session_path(conn, :new))
      assert html_response(conn, 200) =~ "Login Page"
    end

    test "Successful login", %{conn: conn, user: user} do
      conn = post(conn, Routes.session_path(conn, :login), user: %{email: user.email, password: Helper.default_password})
      assert redirected_to(conn) == Routes.page_path(conn, :index)
      conn = get(conn, Routes.page_path(conn, :index))
      assert html_response(conn, 200) =~ "Internal dashboard"
    end

    test "Unsuccessful login", %{conn: conn, user: user} do
      wrong_pass = "some wrong pass"
      assert Helper.default_password != wrong_pass
      conn = post(conn, Routes.session_path(conn, :login), user: %{email: user.email, password: wrong_pass})
      assert get_flash(conn, :error) == "invalid_credentials" 
      assert html_response(conn, 200) =~ "Login Page"
    end

    test "Logout", %{conn: conn, user: user} do
      conn = post(conn, Routes.session_path(conn, :login), user: %{email: user.email, password: Helper.default_password})
      conn = get(conn, Routes.session_path(conn, :logout))
      assert redirected_to(conn) == Routes.session_path(conn, :new)
      conn = get(conn, Routes.session_path(conn, :new))
      assert html_response(conn, 200) =~ "Login Page"
    end
  end

  describe "Admin can login and log out" do
    setup [:create_admin]

    test "Open login page", %{conn: conn} do
      conn = get(conn, Routes.session_path(conn, :new))
      assert html_response(conn, 200) =~ "Login Page"
    end

    test "Successful login", %{conn: conn, user: user} do
      conn = post(conn, Routes.session_path(conn, :login), user: %{email: user.email, password: Helper.default_password})
      assert redirected_to(conn) == Routes.page_path(conn, :index)
      conn = get(conn, Routes.page_path(conn, :index))
      assert html_response(conn, 200) =~ "Internal dashboard"
    end

    test "Unsuccessful login", %{conn: conn, user: user} do
      wrong_pass = "some wrong pass"
      assert Helper.default_password != wrong_pass
      conn = post(conn, Routes.session_path(conn, :login), user: %{email: user.email, password: wrong_pass})
      assert get_flash(conn, :error) == "invalid_credentials" 
      assert html_response(conn, 200) =~ "Login Page"
    end

    test "Logout", %{conn: conn, user: user} do
      conn = post(conn, Routes.session_path(conn, :login), user: %{email: user.email, password: Helper.default_password})
      conn = get(conn, Routes.session_path(conn, :logout))
      assert redirected_to(conn) == Routes.session_path(conn, :new)
      conn = get(conn, Routes.session_path(conn, :new))
      assert html_response(conn, 200) =~ "Login Page"
    end
  end

  describe "Archived user can not login" do
    setup [:create_archived_user]

    test "Open login page", %{conn: conn} do
      conn = get(conn, Routes.session_path(conn, :new))
      assert html_response(conn, 200) =~ "Login Page"
    end

    test "Successful login", %{conn: conn, user: user} do
      conn = post(conn, Routes.session_path(conn, :login), user: %{email: user.email, password: Helper.default_password})
      assert response(conn, 403) =~ "Your account had been blocked. Please contact support."
    end

    test "Unsuccessful login", %{conn: conn, user: user} do
      wrong_pass = "some wrong pass"
      assert Helper.default_password != wrong_pass
      conn = post(conn, Routes.session_path(conn, :login), user: %{email: user.email, password: wrong_pass})
      assert get_flash(conn, :error) == "invalid_credentials" 
      assert html_response(conn, 200) =~ "Login Page"
    end
  end


end
