defmodule AeCanary.ForkMonitor.Model.Alert do
  require Logger

  @minumum_fork_length 2

  @doc """
   Compare previously known forks with the current list of forks and see if any fork has
   grown.

   Returns details of any alerts that need to be sent
  """
  def alertForForks([], _forks) do
    []
  end

  def alertForForks(previousForks, forks) do
    forks
    |> Enum.sort(fn a, b -> a.forkLength >= b.forkLength end)
    ## Filter longest fork (its not a fork, its the main chain)
    |> tl()
    ## Consider only forks longer than 2 blocks
    |> Enum.filter(fn fork -> fork.forkLength >= @minumum_fork_length end)
    |> Enum.reduce([], fn fork, acc ->
      previousMatch =
        Enum.find(previousForks, fn %{forkStart: forkStart} ->
          forkStart.keyHash == fork.forkStart.keyHash
        end)

      cond do
        previousMatch == nil ->
          Logger.info(
            "Could not find previous fork for #{fork.forkStart.keyHash} with length #{fork.forkLength}"
          )

          acc

        previousMatch.forkLength < fork.forkLength ->
          Logger.error(
            "Found a Fork. Length: #{fork.forkLength} from #{fork.forkStart.lastKeyHash} to #{fork.forkEnd.keyHash}"
          )

          [fork | acc]

        previousMatch.forkLength >= fork.forkLength ->
          Logger.info(
            "Fork is not growing in length. Length: #{fork.forkLength} from #{fork.forkStart.lastKeyHash} to #{fork.forkEnd.keyHash}"
          )

          acc
      end
    end)
  end
end
