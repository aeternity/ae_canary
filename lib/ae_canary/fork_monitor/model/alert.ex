defmodule AeCanary.ForkMonitor.Model.Alert do
  require Logger

  @minumum_fork_length 2
  @max_length_history 10

  @doc """
   Compare previously known forks with the current list of forks and see if any fork has
   grown.

   Returns details of any alerts that need to be sent and a new set of known forks
  """
  def alertForForks(previousForks, forks) do
    forks
    ## First group the latest set of forks by their branch point
    |> Enum.group_by(fn fork -> fork.forkBranchPoint end)
    ## Consider only branch points where at least two of the forks are longer than 2 blocks
    ## This will likely include the normal main fork and at least one other in each case
    |> Enum.filter(fn {_, forks} ->
      Enum.count(forks, fn fork -> fork.forkLength >= @minumum_fork_length end) >= 2
    end)
    |> Enum.reduce({[], %{}}, fn {branchPoint, forks}, {alerts, acc} ->
      ## Have we seen any forks from this branch point before?
      previousMatch =
        Enum.find(previousForks, fn {prevBranchPoint, _prevFork} ->
          branchPoint == prevBranchPoint
        end)

      case previousMatch do
        nil ->
          ## A completely new fork appeared with at least 2 branches more than 2 blocks long.
          ## Could be the first indication of an attack
          Logger.info("New branch point #{branchPoint}")
          ## Start recording recent forkLengths against each fork so we can track progress
          forks =
            Enum.map(forks, fn fork -> Map.put(fork, :recentLengths, [fork.forkLength]) end)
            |> Enum.sort(fn a, b -> a.forkLength >= b.forkLength end)

          {[{branchPoint, forks} | alerts], Map.put(acc, branchPoint, forks)}

        {_, prevForks} ->
          ## Compare the forks originating at this branchpoint to the previous set at the same place
          ## It's a concern if:
          ##  - another new fork has appeared that's longer than 2 blocks
          ##  - two or more known forks are growing - at least one has increased in length
          ##    this time, and another grew in the last few blocks

          ## Find the forks that are new this time around from this branchPoint.
          ## Put all the new ones in an alert
          {updatedForks, newForks} =
            Enum.split_with(forks, fn fork ->
              Enum.find(prevForks, fn pf -> pf.forkStart == fork.forkStart end)
            end)

          ## For the new ones start recording recent forkLengths against each fork
          newForks =
            Enum.map(newForks, fn fork -> Map.put(fork, :recentLengths, [fork.forkLength]) end)

          ## Update the forkLength history in forks we have seen before, only keeping the
          ## most recent @max_length_history
          updatedForks =
            Enum.map(updatedForks, fn fork ->
              prev = Enum.find(prevForks, fn pf -> pf.forkStart == fork.forkStart end)

              lengths =
                if length(prev.recentLengths) >= @max_length_history do
                  [fork.forkLength | Enum.slice(prev.recentLengths, 0, @max_length_history - 1)]
                else
                  [fork.forkLength | prev.recentLengths]
                end

              Map.put(fork, :recentLengths, lengths)
            end)

          ## from the previously seen forks grab the ones that grew this time
          growingForks =
            Enum.filter(updatedForks, fn updatedFork ->
              prev = Enum.find(prevForks, fn pf -> pf.forkStart == updatedFork.forkStart end)
              updatedFork.forkLength > prev.forkLength
            end)

          ## One of the growing forks *should* just be the normal main trunk of the chain
          ## If only one fork grew use an extra heuristic to decide if this is alertable
          alertsFromExisting =
            case growingForks do
              [] ->
                []

              [growingFork] ->
                ## One fork grew, did any of the others grow recently?
                [
                  growingFork
                  | Enum.filter(updatedForks, fn fork ->
                      fork.forkStart != growingFork.forkStart && fork_grew_recently?(fork)
                    end)
                ]

              [_ | _] ->
                ## More than one fork grew. Alert with all of them
                growingForks
            end

          newAlerts =
            case newForks ++ alertsFromExisting do
              [] ->
                alerts

              multipleAlerts ->
                sorted = Enum.sort(multipleAlerts, fn a, b -> a.forkLength >= b.forkLength end)
                Logger.info("Growing forks from hash: #{branchPoint}")
                [{branchPoint, sorted} | alerts]
            end

          {newAlerts, Map.put(acc, branchPoint, newForks ++ updatedForks)}
      end
    end)
  end

  ## return false if all the values in the list are the same - no growth seen
  defp fork_grew_recently?(%{recentLengths: []}) do
    false
  end

  defp fork_grew_recently?(%{recentLengths: [val | recentLengths]}) do
    not Enum.all?(recentLengths, fn len -> len == val end)
  end
end
