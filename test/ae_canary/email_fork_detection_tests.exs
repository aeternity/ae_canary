defmodule AeCanary.EmailForkDetectionTest do
  use AeCanary.DataCase
  use Bamboo.Test

  alias AeCanary.ForkMonitor.Model

  @users [
    %{
      email: "test1@domain",
      password: "pass",
      name: "Test user all",
      email_big_deposits: false,
      email_boundaries: false,
      email_large_forks: true,
      role: :admin
    }
  ]

  def forks_fixture() do
    Model.ChainWalker.updateChainEnds(50_000)

    ## Delete the top blocks from one of the forks to reduce its length to 1
    topBlock = Model.get_block!("end1")
    Model.delete_block(topBlock)
    nextBlock = Model.get_block!("end1-1")
    Model.delete_block(nextBlock)

    Enum.sort(Model.Detector.checkForForks())
  end

  def users_fixture() do
    Enum.map(@users, fn attrs ->
      {:ok, user} =
        %{}
        |> Enum.into(attrs)
        |> AeCanary.Accounts.create_user()

      user
    end)
  end

  test "Fork detection emails sent for initial fork and new fork" do
    users = users_fixture()
    forks = forks_fixture()

    {alerts, updatedForks} = AeCanary.ForkMonitor.Model.Alert.alertForForks([], forks)
    AeCanary.Mdw.Notifier.send_fork_notifications(alerts, users)

    assert_email_delivered_with(
      subject: "[AeCanary] Fork detected",
      to: [{"Test user all", "test1@domain"}],
      html_body: ~r/Fork detected starting at end-main-10/
    )

    Model.ChainWalker.updateChainEnds(50_000)

    forks = Enum.sort(Model.Detector.checkForForks())

    {alerts, newForks} = AeCanary.ForkMonitor.Model.Alert.alertForForks(updatedForks, forks)
    AeCanary.Mdw.Notifier.send_fork_notifications(alerts, users)

    assert_email_delivered_with(
      subject: "[AeCanary] Fork detected",
      to: [{"Test user all", "test1@domain"}],
      html_body: ~r/Fork detected starting at end-main-4/
    )

    {alerts, _newForks} = AeCanary.ForkMonitor.Model.Alert.alertForForks(newForks, forks)
    AeCanary.Mdw.Notifier.send_fork_notifications(alerts, users)
    assert_no_emails_delivered()
  end
end
