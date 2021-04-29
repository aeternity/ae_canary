defmodule AeCanaryWeb.Exchanges.ExchangeView do
  use AeCanaryWeb, :view

  def exposure(aggregated), do: round(aggregated.deposit - aggregated.withdrawal)

  def alerts_for_past_7_days(exchanges) do
    Enum.filter(exchanges,
      fn(e) ->
        Enum.any?(e.addresses,
          fn(addr) ->
            Enum.any?(Map.delete(addr.amounts, "30"),
              fn({_, balance}) -> balance.deposit - balance.withdrawal > 1_000_000 end)
          end)
      end)
  end

end
