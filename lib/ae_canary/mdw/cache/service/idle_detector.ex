defmodule AeCanary.Mdw.Cache.Service.IdleDetector do
  use AeCanary.Mdw.Cache.Service, name: "Idleness Detector"

  @impl true
  def init(), do: nil

  @impl true
  def refresh_interval(), do: minutes(1)

  @impl true
  def cache_handle(), do: :block_delay

  @impl true
  def refresh(state) do
    ## update DB
    {:ok, current_generation} = AeCanary.Node.Api.current_generation()

    case state do
      nil ->
        ## Bootstrap state on first run
        block_time = Timex.from_unix(current_generation["key_block"]["time"], :millisecond)
        expiry_time = Timex.shift(block_time, minutes: max_idle_config())
        minutes_since_last = Timex.diff(Timex.now(), block_time, :minutes)

        %{
          generation: current_generation,
          block_time: block_time,
          expiry_time: expiry_time,
          delay_minutes: minutes_since_last,
          config_delay: max_idle_config()
        }

      %{generation: %{"key_block" => storedKeyBlock}} = state ->
        currentKeyBlock = current_generation["key_block"]
        minutes_since_last = Timex.diff(Timex.now(), state.block_time, :minutes)
        ## Look for potential health problems
        if currentKeyBlock["hash"] == storedKeyBlock["hash"] do
          ## No new keyblock yet
          ## 1. Check if we have gone too long without a new keyblock

          if Timex.after?(Timex.now(), state.expiry_time) do
            users = AeCanary.Accounts.list_users()

            AeCanary.Mdw.Notifier.send_idle_notifications(
              currentKeyBlock["hash"],
              users,
              Map.put(state, :event_type, :idle)
            )
          end

          %{state | delay_minutes: minutes_since_last}
        else
          ## It's a new keyblock. We assume the previous keyblock is now fully mined
          ## so we can check its health
          {:ok, prevGeneration} =
            AeCanary.Node.Api.generations_at_hash(currentKeyBlock["prev_key_hash"])

          if prevGeneration["micro_blocks"] == [] do
            ## 2. The likely fully mined previous generation has no microblocks
            users = AeCanary.Accounts.list_users()

            AeCanary.Mdw.Notifier.send_idle_no_microblocks_notifications(
              prevGeneration["key_block"]["hash"],
              users,
              Map.put(state, :event_type, :idle_no_microblocks)
            )
          else
            ## 3. Check if any microblocks contain transactions
            ## Fetch each microblock in turn until one is found that includes at least one tx
            ## If none of them contain any transactions that's worth notifying
            case any_transactions?(prevGeneration["micro_blocks"]) do
              true ->
                :ok

              false ->
                users = AeCanary.Accounts.list_users()

                AeCanary.Mdw.Notifier.send_idle_no_transactions_notifications(
                  prevGeneration["key_block"]["hash"],
                  users,
                  Map.put(state, :event_type, :idle_no_transactions)
                )
            end
          end

          block_time = Timex.from_unix(current_generation["key_block"]["time"], :millisecond)
          expiry_time = Timex.shift(block_time, minutes: max_idle_config())
          minutes_since_last = Timex.diff(Timex.now(), block_time, :minutes)

          %{
            generation: current_generation,
            block_time: block_time,
            expiry_time: expiry_time,
            delay_minutes: minutes_since_last,
            config_delay: max_idle_config()
          }
        end
    end
  end

  defp any_transactions?(micro_blocks) do
    Enum.any?(micro_blocks, fn micro_block -> transaction_count(micro_block) > 0 end)
  end

  defp transaction_count(micro_block) do
    case AeCanary.Node.Api.transaction_count(micro_block) do
      {:ok, %{"count" => count}} ->
        count

      _ ->
        0
    end
  end

  defp max_idle_config(), do: config(:alert_idle_minutes, 30)

  defp config(key, default) do
    case Application.fetch_env(:ae_canary, AeCanary.Mdw.Cache.Service.IdleDetector) do
      :error -> default
      {:ok, v} -> Keyword.get(v, key, default)
    end
  end
end
