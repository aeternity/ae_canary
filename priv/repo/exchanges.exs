alias AeCanary.Exchanges

[ %{name: "Huobi", comment: nil, addresses: [%{addr: "ak_vKdT14HCiLCxuT3M7vf3QREyUbQTr1u6Pz49ba9EhaD6uDqWs"}]},
  %{name: "gate.io", comment: nil, addresses: [%{addr: "ak_2tNbVhpU6Bo3xGBJYATnqc62uXjR8yBv9e63TeYCpa6ASgEz94"},
                                                %{addr: "ak_6sssiKcg7AywyJkfSdHz52RbDUq5cZe4V4hcvghXnrPz4H4Qg"}]},
  %{name: "Binance", comment: nil, addresses: [%{addr: "ak_dnzaNnchT7f3YT3CtrQ7GUjqGT6VaHzPxpf2efHWPuEAWKcht"}]},
  %{name: "Bithumb", comment: nil, addresses: [%{addr: "ak_2kGjej4M4YCPpK6yxhaTP6Kyxejd6w22wdMcUQkhNRuZy2JchH", comment: "address for deposits"},
                                                %{addr: "ak_3jgongnfUibKiXBUVCtwXMWbM8hzifRm6C1E4Fp3mKbAT7ZQ9", comment: "temporary address"},
                                                %{addr: "ak_Tmwf23kcVVXvJwb79G68wBtyEL9iTSGQRzZz4DJxwTxJWbM1", comment: "address for withdrawals"}
                                              ]},
  %{name: "ZB.com", comment: nil, addresses: [%{addr: "ak_6HzvyAruY8Wehw5amSNULMX2DD4nGikJ31HmKksYNkWms8EVR"},
                                                %{addr: "ak_2mggc8gkx9nhkciBtYbq39T6Jzd7WBms6jgYoLAAeRNgdy3Md6"}]},
  %{name: "CoinEX", comment: nil, addresses: [%{addr: "ak_3oCNr4upswn5sRVpqdpuiCwxqwRU1tok2xLjLLy9vjvYRdVNd"}]},
  %{name: "BigONE", comment: nil, addresses: [%{addr: "ak_2jAKqpercZZhfJ397yBuWfxZXfdCUGSkDiJuNtokNeeDV1Y13q"}]},
  %{name: "Coinw", comment: nil, addresses: [%{addr: "ak_N1a9HyfqpbvWV5vGejWMduf4yn8yeiXNz6AzU22iwGDT35NXh"}]}
]
|> Enum.each(
  fn(props) ->
    {:ok, exchange} = Exchanges.create_exchange(props)
    Enum.each(props.addresses,
      fn(address) ->
        Exchanges.create_address(Map.put(address, :exchange_id, exchange.id)) end)
  end)
