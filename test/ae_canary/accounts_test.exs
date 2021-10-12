defmodule AeCanary.AccountsTest do
  use AeCanary.DataCase

  alias AeCanary.Accounts

  describe "users" do
    alias AeCanary.Accounts.User

    @valid_user_roles [:admin, :user, :archived]

    @valid_attrs %{comment: "some comment", email: "some email", name: "some name", password: "some password", role: :admin}
    @update_attrs %{comment: "some updated comment", email: "some updated email", name: "some updated name", password: "some updated password", role: :user}
    @invalid_attrs %{comment: nil, email: nil, name: nil, pass_hash: nil, role: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [reset_virtual_fields(user)]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == reset_virtual_fields(reset_associated_field(user))
    end

    test "create_user/1 with valid data creates a user" do
      test_role =
        fn(role) ->
          assert {:ok, %User{} = user} = Accounts.create_user(%{@valid_attrs | role: role})
          assert user.comment == "some comment"
          assert user.email == "some email"
          assert user.name == "some name"
          assert {:ok, user} == Argon2.check_pass(user, "some password", hash_key: :pass_hash)
          assert user.role == role
        end
      Enum.each(@valid_user_roles, test_role)
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(%{@valid_attrs | role: :something_invalid})
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.comment == "some updated comment"
      assert user.email == "some updated email"
      assert user.name == "some updated name"
      assert {:ok, user} == Argon2.check_pass(user, "some updated password", hash_key: :pass_hash)
      assert user.role == :user
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert reset_virtual_fields(reset_associated_field(user)) == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end

  defp reset_virtual_fields(user) do
    %{user | password: nil}
  end

  defp reset_associated_field(user) do
    %{user | exchange_view: nil}
  end
end
