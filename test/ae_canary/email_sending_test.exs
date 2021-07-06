defmodule AeCanary.EmailDeliveryTest do
  use AeCanary.DataCase
  use Bamboo.Test

  @alerts_for_last_days [
    %{
      addresses: [
        %{
          addr: "ak_6sssiKcg7AywyJkfSdHz52RbDUq5cZe41234567890",
          big_deposits: [
            %AeCanary.Transactions.Tx{
              location: %AeCanary.Transactions.Location{
                block_hash: "mh_GoiWvJ7kCXnatAH5ct7ZLpYFdqNgYtcfGdUqDRjjPwBWjCCT5",
                block_height: 440_849,
                id: 10,
                inserted_at: ~N[2021-06-14 15:33:16],
                micro_time: ~U[2021-06-09 04:50:09Z],
                tx_hash: "th_21M5vaTkBhJNNMHPLXtWXZTjsWKv977QXfyg3VD1234567890",
                tx_type: :spend,
                updated_at: ~N[2021-06-14 15:33:16]
              },
              tx: %AeCanary.Transactions.Spend{
                amount: 640_356.1757720001,
                fee: 2.800000000176e-5,
                hash: "th_21M5vaTkBhJNNMHPLXtWXZTjsWKv977QXfyg3VD1234567890",
                inserted_at: ~N[2021-06-14 15:33:16],
                nonce: nil,
                recipient_id: "ak_6sssiKcg7AywyJkfSdHz52RbDUq5cZe41234567890",
                sender_id: "ak_TgZUru3fNkobL678ZmpsqxTz7nFayoLNJB2E1234567890",
                updated_at: ~N[2021-06-14 15:33:16]
              }
            }
          ],
          id: 4,
          over_the_boundaries: [
            %{
              date: ~D[2021-06-09],
              message: %{
                boundary: "upper",
                exposure: 658_154.4069819901,
                limit: 585_680.2016684201
              }
            }
          ]
        }
      ],
      id: 2,
      name: "gate.io"
    },
    %{
      addresses: [
        %{
          addr: "ak_dnzaNnchT7f3YT3CtrQ7GUjqGT6VaHzPxpf21234567890",
          big_deposits: [],
          id: 5,
          over_the_boundaries: [
            %{
              date: ~D[2021-06-09],
              message: %{
                boundary: "upper",
                exposure: 20.73282081,
                limit: 11.543029944999994
              }
            }
          ]
        }
      ],
      id: 3,
      name: "Binance"
    }
  ]


  @users [
    %{
      email: "test1@domain",
      password: "pass",
      name: "Test user all",
      email_big_deposits: true,
      email_boundaries: true,
      email_large_forks: false,
      role: :admin
    },
    %{
      email: "test2@domain",
      password: "pass",
      name: "Test user only deposits",
      email_big_deposits: true,
      email_boundaries: false,
      email_large_forks: false,
      role: :user
    },
    %{
      email: "test3@domain",
      password: "pass",
      name: "Test user only boundaries",
      email_big_deposits: false,
      email_boundaries: true,
      email_large_forks: false,
      role: :user
    }
  ]

  def users_fixture() do
      Enum.map(@users, fn attrs ->
        {:ok, user} =
        %{}
        |> Enum.into(attrs)
        |> AeCanary.Accounts.create_user()

      user
      end)
    end

  test "Notifications sent only to subscribed users" do
      users = users_fixture()
      AeCanary.Mdw.Notifier.send_notifications(@alerts_for_last_days, users)
      assert_email_delivered_with(subject: "[AeCanary] Large deposit notification", to: [{"Test user all", "test1@domain"}])
      assert_email_delivered_with(subject: "[AeCanary] Large deposit notification", to: [{"Test user only deposits", "test2@domain"}])
      assert_email_delivered_with(subject: "[AeCanary] Boundary crossed notification", to: [{"Test user all", "test1@domain"}])
      assert_email_delivered_with(subject: "[AeCanary] Boundary crossed notification", to: [{"Test user only boundaries", "test3@domain"}])
      assert_email_delivered_with(subject: "[AeCanary] Boundary crossed notification", to: [{"Test user all", "test1@domain"}])
      assert_email_delivered_with(subject: "[AeCanary] Boundary crossed notification", to: [{"Test user only boundaries", "test3@domain"}])

      assert 6 = length(AeCanary.Notifications.list_notifications())
  end

  test "Notifications sent only once" do
      users = users_fixture()
      AeCanary.Mdw.Notifier.send_notifications(@alerts_for_last_days, users)
      assert_email_delivered_with(subject: "[AeCanary] Large deposit notification", to: [{"Test user all", "test1@domain"}], html_body: ~r/test.host/)
      assert_email_delivered_with(subject: "[AeCanary] Large deposit notification", to: [{"Test user only deposits", "test2@domain"}], html_body: ~r/test.host/)
      assert_email_delivered_with(subject: "[AeCanary] Boundary crossed notification", to: [{"Test user all", "test1@domain"}], html_body: ~r/test.host/)
      assert_email_delivered_with(subject: "[AeCanary] Boundary crossed notification", to: [{"Test user only boundaries", "test3@domain"}], html_body: ~r/test.host/)
      assert_email_delivered_with(subject: "[AeCanary] Boundary crossed notification", to: [{"Test user all", "test1@domain"}], html_body: ~r/test.host/)
      assert_email_delivered_with(subject: "[AeCanary] Boundary crossed notification", to: [{"Test user only boundaries", "test3@domain"}], html_body: ~r/test.host/)

      assert 6 = length(AeCanary.Notifications.list_notifications())

      AeCanary.Mdw.Notifier.send_notifications(@alerts_for_last_days, users)

      assert_no_emails_delivered()

      assert 6 = length(AeCanary.Notifications.list_notifications())
  end
end
