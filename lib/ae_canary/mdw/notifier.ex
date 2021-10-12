defmodule AeCanary.Mdw.Notifier do
  require Logger
  alias AeCanary.Accounts.User

  def send_fork_notifications(allForks, users) do
    Enum.each(allForks, fn {forkPoint, forks} ->
      send_fork_notifications(users, forkPoint, forks)
    end)
  end

  def send_idle_notifications(lastBlock, users, details) do
    interested_users = Enum.filter(users, fn u -> u.email_idle end)

    sent =
      AeCanary.Notifications.list_idle_events(:idle, lastBlock)
      |> Enum.map(fn n -> n.email end)
      |> MapSet.new()

    ## We still need to send to interested_users that are not yet in sent MapSet
    Enum.reject(interested_users, fn u -> MapSet.member?(sent, u.email) end)
    |> send_emails(:idle, "", lastBlock, details)
  end

  def send_idle_no_microblocks_notifications(lastBlock, users, details) do
    interested_users = Enum.filter(users, fn u -> u.email_idle end)

    sent =
      AeCanary.Notifications.list_idle_events(:idle_no_microblocks, lastBlock)
      |> Enum.map(fn n -> n.email end)
      |> MapSet.new()

    ## We still need to send to interested_users that are not yet in sent MapSet
    Enum.reject(interested_users, fn u -> MapSet.member?(sent, u.email) end)
    |> send_emails(:idle_no_microblocks, "", lastBlock, details)
  end

  def send_idle_no_transactions_notifications(lastBlock, users, details) do
    interested_users = Enum.filter(users, fn u -> u.email_idle end)

    sent =
      AeCanary.Notifications.list_idle_events(:idle_no_transactions, lastBlock)
      |> Enum.map(fn n -> n.email end)
      |> MapSet.new()

    ## We still need to send to interested_users that are not yet in sent MapSet
    Enum.reject(interested_users, fn u -> MapSet.member?(sent, u.email) end)
    |> send_emails(:idle_no_transactions, "", lastBlock, details)
  end

  def send_notifications(alerts_for_past_days, users) do
    alerts_for_past_days
    |> Enum.each(fn %{name: name, addresses: addresses} ->
      send_notications_for_addresses(name, addresses, users)
    end)
  end

  defp send_notications_for_addresses(name, addresses, users) do
    Enum.each(addresses, fn %{
                              addr: addr,
                              big_deposits: big_deposits,
                              over_the_boundaries: over_the_boundaries
                            } ->
      send_big_deposit_notifications(users, name, addr, big_deposits)
      send_over_the_boundaries_notifications(users, name, addr, over_the_boundaries)
    end)
  end

  defp send_big_deposit_notifications(users, name, addr, big_deposits) do
    interested_users = Enum.filter(users, fn u -> u.email_big_deposits end)

    Enum.each(big_deposits, fn %AeCanary.Transactions.Spend{} = tx ->
      ## Find any emails already sent for this event
      sent =
        AeCanary.Notifications.list_big_deposits(addr, tx.hash)
        |> Enum.map(fn n -> n.email end)
        |> MapSet.new()

      ## We still need to send to interested_users that are not yet in sent MapSet
      Enum.reject(interested_users, fn u -> MapSet.member?(sent, u.email) end)
      |> send_emails("big_deposit", name, addr, tx)
    end)
  end

  defp send_over_the_boundaries_notifications(users, name, addr, over_the_boundaries) do
    interested_users = Enum.filter(users, fn u -> u.email_boundaries end)

    Enum.each(over_the_boundaries, fn %{
                                        date: date,
                                        message: %{
                                          boundary: boundary,
                                          exposure: exposure,
                                          limit: limit
                                        }
                                      } = event ->
      ## Find any emails already sent for this event,
      sent =
        AeCanary.Notifications.list_over_boundaries(addr, boundary, date, exposure, limit)
        |> Enum.map(fn n -> n.email end)
        |> MapSet.new()

      ## We still need to send to interested_users that are not yet in sent MapSet
      Enum.reject(interested_users, fn u -> MapSet.member?(sent, u.email) end)
      |> send_emails("boundary", name, addr, event)
    end)
  end

  ## Send a single email for this forkPoint with details of all the forks
  defp send_fork_notifications(users, forkPoint, forks) do
    interested_users = Enum.filter(users, fn u -> u.email_large_forks end)

    ## We don't email if an email was already sent for this exact set of conditions.
    ## The algorithm to prevent duplicates is not persistent for forks - it's in the
    ## regular checker. This means after a restart of Canary duplicate fork emails
    ## will be sent to all users. This ought to be quite a rare event.....

    Enum.each(interested_users, fn %User{} = user ->
      case AeCanary.Email.fork_notification_email(user, forkPoint, forks)
           |> AeCanary.Mailer.deliver_now(response: true) do
        {:ok, _, _} ->
          Logger.info(
            "Email notification submitted to #{user.email} for Fork detection event from fork #{forkPoint}"
          )

          true

        {:error, _} ->
          Logger.error(
            "Email notification failed to #{user.email} for Fork detection event from fork #{forkPoint}"
          )

          false
      end
    end)
  end

  defp send_emails(users, event_type, name, addr, event) do
    Enum.each(users, fn %User{} = user ->
      sent =
        case AeCanary.Email.notification_email(user, name, addr, event)
             |> AeCanary.Mailer.deliver_now(response: true) do
          {:ok, _, _} ->
            Logger.info(
              "Email notification submitted to #{user.email} for #{event_type} event #{addr} #{event_detail(event)}"
            )

            true

          {:error, _} ->
            Logger.error(
              "Email notification failed to #{user.email} for #{event_type} event #{addr} #{event_detail(event)}"
            )

            false
        end

      {:ok, _} = store_notification(user.email, event_type, name, addr, event, sent)
    end)
  end

  defp store_notification(email, event_type, name, addr, event, sent) do
    %{email: email, event_type: event_type, name: name, addr: addr, sent: sent}
    |> Map.merge(event_attrs(event))
    |> AeCanary.Notifications.create_notification()
  end

  defp event_attrs(%AeCanary.Transactions.Spend{} = tx) do
    %{amount: tx.amount, tx_hash: tx.hash, event_datetime: tx.inserted_at}
  end

  defp event_attrs(%{message: msg, date: date}) do
    %{boundary: msg.boundary, exposure: msg.exposure, limit: msg.limit, event_date: date}
  end

  defp event_attrs(%{date: date}) do
    %{event_date: date}
  end

  defp event_attrs(%{event_type: :idle, generation: generation}) do
    %{tx_hash: generation["key_block"]["hash"]}
  end

  defp event_attrs(%{event_type: :idle_no_microblocks, generation: generation}) do
    %{tx_hash: generation["key_block"]["hash"]}
  end

  defp event_attrs(%{event_type: :idle_no_transactions, generation: generation}) do
    %{tx_hash: generation["key_block"]["hash"]}
  end

  defp event_detail(%AeCanary.Transactions.Spend{} = tx) do
    "tx hash: " <> tx.hash
  end

  defp event_detail(%{message: msg}) do
    "boundary: #{msg.boundary} exposure: #{msg.exposure}"
  end

  defp event_detail(%{event_type: :idle}) do
    "idle: no keyblocks for longer than threshold"
  end

  defp event_detail(%{event_type: :idle_no_microblocks}) do
    "idle_no_microblocks: no microblocks in latest keyblock"
  end

  defp event_detail(%{event_type: :idle_no_transactions}) do
    "idle_no_transactions: no transaction in any microblocks in the key block"
  end
end
