defmodule AeCanary.EmailIdleDetectionTest do
  use AeCanary.DataCase
  use Bamboo.Test

  @users [
    %{
      email: "test1@domain",
      password: "pass",
      name: "Test user all",
      email_big_deposits: false,
      email_boundaries: false,
      email_large_forks: true,
      email_idle: true,
      role: :admin
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

  test "Idle detection email sent for no keyblocks beyond time limit" do
    users_fixture()

    initial_state = AeCanary.Mdw.Cache.Service.IdleDetector.refresh(nil)

    ## Hack the stored expiry time to be in the past. Bad, test depends on
    ## internal structure of state, but it does test what we need it to
    older_expiry = Timex.now() |> Timex.shift(minutes: -60)

    shifted_initial = %{initial_state | expiry_time: older_expiry}

    AeCanary.Mdw.Cache.Service.IdleDetector.refresh(shifted_initial)

    assert_email_delivered_with(
      subject: "[AeCanary] Idle chain detected",
      to: [{"Test user all", "test1@domain"}],
      html_body: ~r/The Aeternity blockchain has not created a new key block for/
    )
  end

  test "Idle detection email sent for no microblocks in last mined block" do
    users_fixture()

    initial_state = AeCanary.Mdw.Cache.Service.IdleDetector.refresh(nil)

    ## Hack the stored state to look like it was a different older key block
    hacked_state = put_in(initial_state, [:generation, "key_block", "hash"], "old_hash")

    AeCanary.Mdw.Cache.Service.IdleDetector.refresh(hacked_state)

    assert_email_delivered_with(
      subject: "[AeCanary] Idle chain no microblocks detected",
      to: [{"Test user all", "test1@domain"}],
      html_body: ~r/The Aeternity blockchain newest key block does not contain any microblocks/
    )
  end

  test "Idle detection email sent for no transactions in any of the microblocks in last mined block" do
    users_fixture()

    initial_state = AeCanary.Mdw.Cache.Service.IdleDetector.refresh(nil)

    ## Hack the stored state to look like it was a different older key block
    hacked_state = put_in(initial_state, [:generation, "key_block", "hash"], "old_hash")

    ## And hack the lookup of the current generation to refer to a previous keyblock with
    ## Some microblocks. Process dict used here to control the test http endpoint without
    ## polluting the real API. Risk of collision between test cases ought to be small..
    Process.put(:prev_key_hash, "kh_prev_with_microblocks")
    AeCanary.Mdw.Cache.Service.IdleDetector.refresh(hacked_state)
    Process.delete(:prev_key_hash)

    assert_email_delivered_with(
      subject: "[AeCanary] Idle chain no transactions detected in keyblock",
      to: [{"Test user all", "test1@domain"}],
      html_body: ~r/The Aeternity blockchain newest key block does not contain any microblocks/
    )
  end
end
