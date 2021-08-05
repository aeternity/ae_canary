defmodule AeCanaryWeb.Exchanges.ExchangeView do
  use AeCanaryWeb, :view

  def apply_view_filter(all_exchanges, nil) do
    all_exchanges
  end
  def apply_view_filter(all_exchanges, exchange_view_id) do
    all_exchanges
    |> Enum.filter(&(&1.id == exchange_view_id))
  end
end
