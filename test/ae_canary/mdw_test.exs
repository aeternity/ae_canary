defmodule AeCanary.MdwTest do
  use AeCanary.DataCase

  alias AeCanary.Mdw

  @name {:local, :mdw_worker}

  describe "Admin user has full access" do
    setup [:start_poolboy]
    test "Run a fetch" do
      fun = fn -> :ok end
      assert :ok = Mdw.fetch(fun)
    end
    test "Run an async task" do
      fun = fn -> :ok end
      pid = self()
      callback = fn(res)-> send(pid, res) end
      Mdw.async_fetch(fun, callback)
      assert_receive :ok, 1000
      :ok
    end
    test "Run a couple of async tasks" do
      pid = self()
      callback = fn(res)-> send(pid, res) end
      total_jobs = 10
      Enum.each(0..total_jobs,
        fn(i) ->
          Mdw.async_fetch(
            fn ->
              ## each job takes between 101ms and 200ms
              :timer.sleep(:rand.uniform(100) + 100)
              {:ok, i}
            end,
            callback)
          end)
      sleep_time = 300
      ## the total amount of time running tasks sequentially would be at least
      ## 101 * total_jobs; this test relies on having more than one CPU
      assert 101 * total_jobs > sleep_time
      :timer.sleep(sleep_time)
      Enum.each(0..total_jobs,
        fn(i) -> assert_received {:ok, ^i} end)
      :ok
    end
  end

  defp init_spec() do
    [
      name: @name,
      worker_module: AeCanary.Mdw.Worker,
      size: 20,
      max_overflow: 5
    ]
  end

  defp start_poolboy(_) do
    :poolboy.init({init_spec(), []})
    :ok
  end
end

