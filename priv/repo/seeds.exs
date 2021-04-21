# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     AeCanary.Repo.insert!(%AeCanary.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias AeCanary.Accounts

Enum.each(
  [ %{email: "admin", password: "admin", name: "Admin", comment: "This is a test admin account", role: :admin},
    %{email: "user", password: "user", name: "User", comment: "This is a test user account", role: :user},
    %{email: "archived", password: "archived", name: "User", comment: "This is a test archived account", role: :archived}],
  &Accounts.create_user/1)
