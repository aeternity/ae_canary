defmodule AeCanary.Mdw.Cache.Service.ForkDetector do
  use AeCanary.Mdw.Cache.Service, name: "Fork Detector"

  @impl true
  def init(), do: []

  @impl true
  def refresh_interval(), do: minutes(3)

  @impl true
  def cache_handle(), do: :forks

  @impl true
  def refresh(prevForks) do
    ## Check for forks in the most recent 1000 keyblocks.
    ## if any of the forks have two or more branches longer than X keyblocks send notifications.
    ## store the notifications sent with the length and details of the branch points
    forks = AeCanary.ForkMonitor.Model.Detector.checkForForks()
    users = AeCanary.Accounts.list_users()
    {alerts, newForks} = AeCanary.ForkMonitor.Model.Alert.alertForForks(prevForks, forks)
    AeCanary.Mdw.Notifier.send_fork_notifications(alerts, users)
    newForks
  end
end
