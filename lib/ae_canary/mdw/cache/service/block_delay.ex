defmodule AeCanary.Mdw.Cache.Service.BlockDelay do
  use AeCanary.Mdw.Cache.Service, name: "Idleness Detector"

  @impl true
  def init(), do: nil

  @impl true
  def refresh_interval(), do: minutes(1)

  @impl true
  def cache_handle(), do: :block_delay

  @impl true
  def refresh(state) do
    IO.inspect(state, label: "Block Delay state")
    ## update DB
    {:ok, current_generation} = AeCanary.Node.Api.current_generation()

    case state do
      nil ->
        ## Bootstrap state on first run
        current_generation

      %{key_block: existingKeyBlock} ->
        newKeyBlock = current_generation.key_block
        ## Look for potential health problems
        if newKeyBlock.hash == existingKeyBlock.hash do
          ## No new keyblock yet
          ## 1. Check if we have gone too long without a new keyblock
          expiry_time = Timex.shift(
               Timex.from_unix(newKeyBlock.time, :millisecond),
               minutes: max_idle_config()
             )
          if Timex.after?(Timex.now(), expiry_time) do
            IO.inspect("Alert - top block too old")
          end

          state
        else
          ## It's a new keyblock. Check its health
          if current_generation.micro_blocks == [] do
            ## 2. The current generation has no microblocks
            IO.inspect("Alert no microblocks")
          else
            ## 3. None of the microblocks contain transactions
            IO.inspect("Maybe Empty microblocks")
          end

          current_generation
        end
    end
  end

  defp max_idle_config(), do: config(:alert_idle_minutes, 30)

  defp config(key, default) do
    case Application.fetch_env(:ae_canary, AeCanary.Mdw.Cache.Service.BlockDelay) do
      :error -> default
      {:ok, v} -> Keyword.get(v, key, default)
    end
  end
end
