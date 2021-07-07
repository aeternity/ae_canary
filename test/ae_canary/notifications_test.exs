defmodule AeCanary.NotificationsTest do
  use AeCanary.DataCase

  alias AeCanary.Notifications

  describe "notifications" do
    alias AeCanary.Notifications.Notification

    @valid_attrs %{
      addr: "some addr",
      amount: 120.5,
      boundary: "upper",
      event_type: "boundary",
      exposure: 120.7,
      limit: 120.3,
      tx_hash: "some tx_hash",
      event_date: ~D[2021-06-17],
      event_datetime: ~U[2021-06-17 15:15:51.095096Z]
    }
    @update_attrs %{
      addr: "some updated addr",
      amount: 456.7,
      boundary: "lower",
      event_type: "big_deposit",
      exposure: 456.7,
      limit: 456.870835528854899254093987364832,
      tx_hash: "some updated tx_hash",
      event_date: ~D[2021-06-18],
      event_datetime: ~U[2021-06-18 15:15:51.095096Z]
    }
    @invalid_attrs %{
      addr: nil,
      amount: nil,
      boundary: nil,
      event_type: nil,
      exposure: nil,
      limit: nil,
      tx_hash: nil,
      event_date: nil
    }

    def notification_fixture(attrs \\ %{}) do
      {:ok, notification} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Notifications.create_notification()

      notification
    end

    test "list_notifications/0 returns all notifications" do
      notification = notification_fixture()
      assert Notifications.list_notifications() == [notification]
    end

    test "get_notification!/1 returns the notification with given id" do
      notification = notification_fixture()
      assert Notifications.get_notification!(notification.id) == notification
    end

    test "list_over_boundaries/5 returns the notification with given parameters" do
      notification = notification_fixture()

      assert Notifications.list_over_boundaries(
               "some addr",
               "upper",
               ~D[2021-06-17],
               120.7,
               120.3
             ) == [notification]
    end

    test "list_big_deposits/2 returns the notification with given parameters" do
      notification = notification_fixture(@update_attrs)

      assert Notifications.list_big_deposits("some updated addr", "some updated tx_hash") == [
               notification
             ]
    end

    test "create_notification/1 with valid data creates a notification" do
      assert {:ok, %Notification{} = notification} =
               Notifications.create_notification(@valid_attrs)

      assert notification.addr == "some addr"
      assert notification.amount == Decimal.new(121)
      assert notification.boundary == :upper
      assert notification.event_type == :boundary
      assert notification.exposure == Decimal.new(121)
      assert notification.limit == Decimal.new(120)
      assert notification.tx_hash == "some tx_hash"
    end

    test "create_notification/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notifications.create_notification(@invalid_attrs)
    end

    test "update_notification/2 with valid data updates the notification" do
      notification = notification_fixture()

      assert {:ok, %Notification{} = notification} =
               Notifications.update_notification(notification, @update_attrs)

      assert notification.addr == "some updated addr"
      assert notification.amount == Decimal.new(457)
      assert notification.boundary == :lower
      assert notification.event_type == :big_deposit
      assert notification.exposure == Decimal.new(457)
      assert notification.limit == Decimal.new(457)
      assert notification.tx_hash == "some updated tx_hash"
    end

    test "update_notification/2 with invalid data returns error changeset" do
      notification = notification_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Notifications.update_notification(notification, @invalid_attrs)

      assert notification == Notifications.get_notification!(notification.id)
    end

    test "delete_notification/1 deletes the notification" do
      notification = notification_fixture()
      assert {:ok, %Notification{}} = Notifications.delete_notification(notification)
      assert_raise Ecto.NoResultsError, fn -> Notifications.get_notification!(notification.id) end
    end

    test "change_notification/1 returns a notification changeset" do
      notification = notification_fixture()
      assert %Ecto.Changeset{} = Notifications.change_notification(notification)
    end
  end
end
