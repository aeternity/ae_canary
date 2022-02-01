defmodule AeCanary.ServiceExchangeTest do
  use AeCanary.DataCase

  alias AeCanary.Mdw.Cache.Service.Exchange
  alias AeCanary.Transactions

  def deposit(time, amount, hash, addr) do
    {:ok, _} =
      Transactions.create_spend(%{
        amount: amount,
        fee: 1,
        hash: hash,
        nonce: 1,
        recipient_id: addr,
        sender_id: "ak_random",
        block_hash: "some block_hash",
        keyblock_hash: "some keyblock_hash",
        block_height: 100,
        micro_time: time
      })
  end

  def withdrawal(time, amount, hash, addr) do
    {:ok, _} =
      Transactions.create_spend(%{
        amount: amount,
        fee: 1,
        hash: hash,
        nonce: 1,
        recipient_id: "ak_random",
        sender_id: addr,
        block_hash: "some block_hash",
        keyblock_hash: "some keyblock_hash",
        block_height: 100,
        micro_time: time
      })
  end

  test "address_data/2 without transactions" do
    dates = [~D[2022-01-01], ~D[2022-01-02]]

    assert %{
             big_deposits: [],
             dataset: [
               %{
                 date: ~D[2022-01-02],
                 deposits_count: 0,
                 deposits_sum: 0,
                 exposure: 0,
                 tx_count: 0,
                 withdrawals_count: 0,
                 withdrawals_sum: 0
               },
               %{
                 date: ~D[2022-01-01],
                 deposits_count: 0,
                 deposits_sum: 0,
                 exposure: 0,
                 tx_count: 0,
                 withdrawals_count: 0,
                 withdrawals_sum: 0
               }
             ],
             has_txs: false,
             over_the_boundaries: [],
             upper_boundaries: [0, 0]
           } == Exchange.address_data("some_random_address", dates)
  end

  test "address_data/2 with transactions" do
    addr = "someaddress"

    deposit(@jan4, 30, "hash_d_4_30", addr)
    deposit(@jan2, 10, "hash_d_2_10", addr)
    withdrawal(@jan4, 10, "hash_w_4_10", addr)
    withdrawal(@jan3, 5, "hash_w_3_05", addr)

    dates = [~D[2022-01-01], ~D[2022-01-02], ~D[2022-01-03], ~D[2022-01-04]]

    assert %{
             big_deposits: [],
             dataset: [
               %{
                 date: ~D[2022-01-04],
                 deposits_count: 1,
                 deposits_sum: 30.0,
                 exposure: 20.0,
                 tx_count: 2,
                 withdrawals_count: 1,
                 withdrawals_sum: 10.0
               },
               %{
                 date: ~D[2022-01-03],
                 deposits_count: 0,
                 deposits_sum: 0,
                 exposure: -5.0,
                 tx_count: 1,
                 withdrawals_count: 1,
                 withdrawals_sum: 5.0
               },
               %{
                 date: ~D[2022-01-02],
                 deposits_count: 1,
                 deposits_sum: 10.0,
                 exposure: 10.0,
                 tx_count: 1,
                 withdrawals_count: 0,
                 withdrawals_sum: 0
               },
               %{
                 date: ~D[2022-01-01],
                 deposits_count: 0,
                 deposits_sum: 0,
                 exposure: 0,
                 tx_count: 0,
                 withdrawals_count: 0,
                 withdrawals_sum: 0
               }
             ],
             has_txs: true,
             over_the_boundaries: [],
             upper_boundaries: [35.0, 50.0]
           } == Exchange.address_data(addr, dates)
  end

  test "address_data/2 returns big deposits" do
    addr = "someaddress"
    amount = Exchange.suspicious_deposits_threshold()
    deposit(@jan1, amount, "hash_big", addr)
    deposit(@jan1, amount - 1, "hash_not_so-big", addr)

    dates = [~D[2022-01-01]]
    assert %{big_deposits: [deposit]} = Exchange.address_data(addr, dates)
    assert %AeCanary.Transactions.Spend{hash: "hash_big"} = deposit
  end

  test "address_data/2 returns upper boundaries" do
    addr = "someaddress"
    deposit(@jan1, 110, "hash_1", addr)
    deposit(@jan2, 101, "hash_2", addr)
    deposit(@jan3, 102, "hash_3", addr)
    deposit(@jan4, 101, "hash_4", addr)
    deposit(@jan5, 103, "hash_5", addr)

    dates = [~D[2022-01-01], ~D[2022-01-02], ~D[2022-01-03], ~D[2022-01-04], ~D[2022-01-05]]

    assert %{
             over_the_boundaries: [
               %{
                 date: ~D[2022-01-01],
                 message: %{boundary: "upper", exposure: 110.0, limit: 109.0}
               }
             ],
             upper_boundaries: [106.0, 109.0]
           } = Exchange.address_data(addr, dates)
  end

  test "address_data/2 returns lower boundaries" do
    addr = "someaddress"
    deposit(@jan1, 108, "hash_1", addr)
    deposit(@jan2, 101, "hash_2", addr)
    deposit(@jan3, 102, "hash_3", addr)
    deposit(@jan4, 101, "hash_4", addr)
    deposit(@jan5, 103, "hash_5", addr)

    dates = [~D[2022-01-01], ~D[2022-01-02], ~D[2022-01-03], ~D[2022-01-04], ~D[2022-01-05]]

    assert %{
             over_the_boundaries: [
               %{
                 date: ~D[2022-01-01],
                 message: %{boundary: "lower", exposure: 108.0, limit: 106.0}
               }
             ],
             upper_boundaries: [106.0, 109.0]
           } = Exchange.address_data(addr, dates)
  end

  test "addresses_data/2 without transactions" do
    addresses = [%{addr: "some_addr_1"}, %{addr: "some_addr_2"}]
    dates = [~D[2022-01-01], ~D[2022-01-02]]

    assert %{
             addresses: [%{addr: "some_addr_1"}, %{addr: "some_addr_2"}],
             aggregated: aggregated,
             has_txs_past_days: false,
             txs: 0,
             upper_boundaries: [0, 0]
           } = Exchange.addresses_data(addresses, dates)

    assert [
             %{
               date: ~D[2022-01-02],
               deposits_count: 0,
               deposits_sum: 0,
               exposure: 0,
               tx_count: 0,
               withdrawals_count: 0,
               withdrawals_sum: 0
             },
             %{
               date: ~D[2022-01-01],
               deposits_count: 0,
               deposits_sum: 0,
               exposure: 0,
               tx_count: 0,
               withdrawals_count: 0,
               withdrawals_sum: 0
             }
           ] == aggregated
  end

  test "addresses_data/2 with transactions" do
    addr1 = "some_addr_1"
    addr2 = "some_addr_2"

    deposit(@jan4, 30, "hash_d_4_30_1", addr1)
    deposit(@jan4, 30, "hash_d_4_30_2", addr2)
    deposit(@jan2, 10, "hash_d_2_10_1", addr1)
    deposit(@jan2, 10, "hash_d_2_10_2", addr2)

    withdrawal(@jan4, 10, "hash_w_4_10_1", addr1)
    withdrawal(@jan4, 10, "hash_w_4_10_2", addr2)
    withdrawal(@jan3, 5, "hash_w_3_05_1", addr1)
    withdrawal(@jan3, 5, "hash_w_3_05_2", addr2)

    addresses = [%{addr: addr1}, %{addr: addr2}]
    dates = [~D[2022-01-01], ~D[2022-01-02], ~D[2022-01-03], ~D[2022-01-04]]

    assert %{
             addresses: [%{addr: "some_addr_1"}, %{addr: "some_addr_2"}],
             aggregated: aggregated,
             has_txs_past_days: true,
             txs: 8,
             upper_boundaries: [70.0, 100.0]
           } = Exchange.addresses_data(addresses, dates)

    assert [
             %{
               date: ~D[2022-01-04],
               deposits_count: 2,
               deposits_sum: 60.0,
               exposure: 40.0,
               tx_count: 4,
               withdrawals_count: 2,
               withdrawals_sum: 20.0
             },
             %{
               date: ~D[2022-01-03],
               deposits_count: 0,
               deposits_sum: 0,
               exposure: -10.0,
               tx_count: 2,
               withdrawals_count: 2,
               withdrawals_sum: 10.0
             },
             %{
               date: ~D[2022-01-02],
               deposits_count: 2,
               deposits_sum: 20.0,
               exposure: 20.0,
               tx_count: 2,
               withdrawals_count: 0,
               withdrawals_sum: 0
             },
             %{
               date: ~D[2022-01-01],
               deposits_count: 0,
               deposits_sum: 0,
               exposure: 0,
               tx_count: 0,
               withdrawals_count: 0,
               withdrawals_sum: 0
             }
           ] == aggregated
  end

  test "no alerts" do
    addresses = [%{id: 1, addr: "some_addr_1"}, %{id: 2, addr: "some_addr_2"}]
    exchanges = [%{id: 1, name: "ex_1", addresses: addresses}]

    dates = [~D[2022-01-01], ~D[2022-01-02]]

    data = Exchange.exchanges_data(exchanges, dates)
    assert [] == Exchange.alerts(data, ~D[2022-01-02])
  end

  test "alerts for big deposit" do
    addresses = [%{id: 1, addr: "some_addr_1"}, %{id: 2, addr: "some_addr_2"}]
    exchanges = [%{id: 1, name: "ex_1", addresses: addresses}]

    dates = [~D[2022-01-01], ~D[2022-01-02]]

    amount = Exchange.suspicious_deposits_threshold()
    deposit(@jan1, amount, "hash_big_jan_1", "some_addr_1")
    deposit(@jan2, amount, "hash_big_jan_2", "some_addr_1")

    data = Exchange.exchanges_data(exchanges, dates)

    assert [
             %{
               id: 1,
               name: "ex_1",
               addresses: [
                 %{
                   id: 1,
                   addr: "some_addr_1",
                   over_the_boundaries: [],
                   big_deposits: big_deposits
                 }
               ]
             }
           ] = Exchange.alerts(data, ~D[2022-01-02])

    assert [%{hash: "hash_big_jan_2"}] = big_deposits
  end

  test "alerts for boundaries" do
    addr = "some_addr_1"
    deposit(@jan1, 103, "hash_5", addr)
    deposit(@jan2, 101, "hash_2", addr)
    deposit(@jan3, 102, "hash_3", addr)
    deposit(@jan4, 101, "hash_4", addr)
    deposit(@jan5, 108, "hash_1", addr)

    addresses = [%{id: 1, addr: addr}, %{id: 2, addr: "some_addr_2"}]
    exchanges = [%{id: 1, name: "ex_1", addresses: addresses}]
    dates = [~D[2022-01-01], ~D[2022-01-02], ~D[2022-01-03], ~D[2022-01-04], ~D[2022-01-05]]

    data = Exchange.exchanges_data(exchanges, dates)

    assert [
             %{
               id: 1,
               name: "ex_1",
               addresses: [
                 %{
                   id: 1,
                   addr: "some_addr_1",
                   over_the_boundaries: boundaries,
                   big_deposits: []
                 }
               ]
             }
           ] = Exchange.alerts(data, ~D[2022-01-02])

    assert [%{date: ~D[2022-01-05], message: %{boundary: "lower", exposure: 108.0, limit: 106.0}}] =
             boundaries
  end
end
