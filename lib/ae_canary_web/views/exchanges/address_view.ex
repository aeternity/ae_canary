defmodule AeCanaryWeb.Exchanges.AddressView do
  use AeCanaryWeb, :view

  alias AeCanary.Exchanges.Exchange

  def dropdown_values() do
    AeCanary.Exchanges.list_exchanges()
    |> Enum.map(
      fn %Exchange{id: id, name: name} -> {name, id} end)
    |> Enum.into(%{})
  end
end
