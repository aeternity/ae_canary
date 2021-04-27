defmodule AeCanary.Mdw do
 @timeout 60000

  def poolboy_spec do
    [
      name: {:local, :mdw_worker},
      worker_module: AeCanary.Mdw.Worker,
      size: 20,
      max_overflow: 5
    ]
  end

  def fetch(fetch_fun) do
    :poolboy.transaction(
      :mdw_worker,
      fn pid ->
        AeCanary.Mdw.Worker.exec(pid, fetch_fun)
      end,
      @timeout)
  end

  def async_fetch(fetch_fun, callback) do
    Task.start_link(
      fn ->
        res = fetch(fetch_fun)
        callback.(res)
      end)
  end

end
