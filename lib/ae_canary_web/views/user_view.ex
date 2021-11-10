defmodule AeCanaryWeb.UserView do
  use AeCanaryWeb, :view

  alias AeCanary.Exchanges.Exchange

  def exchanges_dropdown_values() do
    AeCanary.Exchanges.list_exchanges()
    |> Enum.map(fn %Exchange{id: id, name: name} -> {name, id} end)
    |> Enum.into(%{})
    |> Map.put("__All exchanges", all_exchanges_placeholder_value())
  end

  def all_exchanges_placeholder_value, do: -1
end
