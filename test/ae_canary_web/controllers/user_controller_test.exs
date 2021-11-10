defmodule AeCanaryWeb.UserControllerTest do
  use AeCanaryWeb.ConnCase

  alias AeCanary.Accounts
  alias AeCanary.TestHelper, as: Helper
  import Helper, only: [create_user: 1, create_admin: 1, login: 1]

  @create_test_attrs %{
    comment: "test comment",
    email: "test email",
    name: "test name",
    pass_hash: "test pass_hash",
    role: "user"
  }
  @create_attrs %{
    comment: "some comment",
    email: "some email",
    name: "some name",
    pass_hash: "some pass_hash",
    role: "admin"
  }
  @update_attrs %{
    comment: "some updated comment",
    email: "some updated email",
    name: "some updated name",
    pass_hash: "some updated pass_hash",
    role: "user"
  }
  @invalid_attrs %{comment: nil, email: nil, name: nil, pass_hash: nil, role: nil}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  describe "Admin user has full access" do
    setup [:create_admin, :create_test_user, :login]

    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Users"
    end

    test "new user: renders form", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :new))
      assert html_response(conn, 200) =~ "New User"
    end

    test "create user: redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.user_path(conn, :show, id)

      conn = get(conn, Routes.user_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show User"
    end

    test "create user: renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert html_response(conn, 200) =~ "New User"
    end

    test "edit user: renders form for editing chosen user", %{conn: conn, test_user: user} do
      conn = get(conn, Routes.user_path(conn, :edit, user))
      assert html_response(conn, 200) =~ "Edit User"
    end

    test "update user: redirects when data is valid", %{conn: conn, test_user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      assert redirected_to(conn) == Routes.user_path(conn, :show, user)

      conn = get(conn, Routes.user_path(conn, :show, user))
      assert html_response(conn, 200) =~ "some updated comment"
    end

    test "update user: renders errors when data is invalid", %{conn: conn, test_user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit User"
    end

    test "deletes user", %{conn: conn, test_user: user} do
      conn = delete(conn, Routes.user_path(conn, :delete, user))
      assert redirected_to(conn) == Routes.user_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.user_path(conn, :show, user))
      end
    end
  end

  describe "Regular user has no access" do
    setup [:create_user, :create_test_user, :login]

    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))
      assert response(conn, 401) =~ "unauthorized"
    end

    test "new user: renders form", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :new))
      assert response(conn, 401) =~ "unauthorized"
    end

    test "create user: redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      assert response(conn, 401) =~ "unauthorized"
    end

    test "create user: renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert response(conn, 401) =~ "unauthorized"
    end

    test "edit user: renders form for editing chosen user", %{conn: conn, test_user: user} do
      conn = get(conn, Routes.user_path(conn, :edit, user))
      assert response(conn, 401) =~ "unauthorized"
    end

    test "update user: redirects when data is valid", %{conn: conn, test_user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      assert response(conn, 401) =~ "unauthorized"
    end

    test "update user: renders errors when data is invalid", %{conn: conn, test_user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
      assert response(conn, 401) =~ "unauthorized"
    end

    test "deletes user", %{conn: conn, test_user: user} do
      conn = delete(conn, Routes.user_path(conn, :delete, user))
      assert response(conn, 401) =~ "unauthorized"
    end
  end

  describe "Not logged  users have no access" do
    setup [:create_test_user]

    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))
      assert response(conn, 401) =~ "unauthenticated"
    end

    test "new user: renders form", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :new))
      assert response(conn, 401) =~ "unauthenticated"
    end

    test "create user: redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      assert response(conn, 401) =~ "unauthenticated"
    end

    test "create user: renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert response(conn, 401) =~ "unauthenticated"
    end

    test "edit user: renders form for editing chosen user", %{conn: conn, test_user: user} do
      conn = get(conn, Routes.user_path(conn, :edit, user))
      assert response(conn, 401) =~ "unauthenticated"
    end

    test "update user: redirects when data is valid", %{conn: conn, test_user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      assert response(conn, 401) =~ "unauthenticated"
    end

    test "update user: renders errors when data is invalid", %{conn: conn, test_user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
      assert response(conn, 401) =~ "unauthenticated"
    end

    test "deletes user", %{conn: conn, test_user: user} do
      conn = delete(conn, Routes.user_path(conn, :delete, user))
      assert response(conn, 401) =~ "unauthenticated"
    end
  end

  defp create_test_user(_) do
    %{user: user} = Helper.create_user_(@create_test_attrs)
    %{test_user: user}
  end
end
