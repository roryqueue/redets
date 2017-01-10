defmodule FakeRedisTest do
  use ExUnit.Case
  doctest FakeRedis

  setup do
    {:ok, connection} = FakeRedis.start_link

    %{conn: connection}
  end

  test "set/2, get/1, getset/2: set and get basic values", %{conn: conn} do
    first_val = "FIRSTVAL"
    second_val = "SECONDVAL"

    assert "OK" = FakeRedis.command!(conn, ~w(SET TESTKEY #{first_val}))
    assert first_val === FakeRedis.command!(conn, ~w(GET TESTKEY))
    assert first_val === FakeRedis.command!(conn, ~w(GETSET TESTKEY #{second_val}))
    assert second_val === FakeRedis.command!(conn, ~w(GET TESTKEY))
  end

  test "mset/2, mget/1: set and get many values", %{conn: conn} do
    first_key = "FIRSTKEY"
    second_key = "SECONDKEY"
    third_key = "THIRDKEY"
    empty_key = "EMPTYKEY"

    first_val = "FIRSTVAL"
    second_val = "SECONDVAL"
    third_val = "THIRDVAL"

    assert "OK" = FakeRedis.command!(
      conn,
      ~w(MSET #{first_key} #{first_val} #{second_key} #{second_val} #{third_key} #{third_val})
    )
    assert [first_val, second_val, third_val, nil] === FakeRedis.command!(
      conn,
      ~w(MGET #{first_key} #{second_key} #{third_key} #{empty_key})
    )
  end

  test "set/2 with EX, ttl/2: expiring keys on set and checking in secs", %{conn: conn} do
    example_val = "TTLVAL"
    wait_secs = 1

    assert "OK" = FakeRedis.command!(
      conn,
      ~w(SET TESTKEY #{example_val} EX #{wait_secs})
    )
    assert example_val === FakeRedis.command!(conn, ~w(GET TESTKEY))
    :timer.sleep(1)

    first_ttl = FakeRedis.command!(conn, ~w(TTL TESTKEY))
    assert first_ttl < wait_secs
    refute first_ttl < 0

    :timer.sleep(wait_secs * 1000)
    assert nil === FakeRedis.command!(conn, ~w(GET TESTKEY))
  end

  test "set/2 with PX, pttl/2: checking ttl in milliseconcs", %{conn: conn} do
    example_val = "PTTLVAL"
    wait_msecs = 500

    assert "OK" = FakeRedis.command!(
      conn,
      ~w(SET TESTKEY #{example_val} PX #{wait_msecs})
    )
    assert example_val === FakeRedis.command!(conn, ~w(GET TESTKEY))

    :timer.sleep(1)
    intermediate_ttl = FakeRedis.command!(conn, ~w(PTTL TESTKEY))
    assert intermediate_ttl < wait_msecs
    refute intermediate_ttl < 0

    :timer.sleep(wait_msecs)
    assert nil === FakeRedis.command!(conn, ~w(GET TESTKEY))
  end

  test "expire/2, ttl/1: expiring keys in seconds after set", %{conn: conn} do
    example_val = "EXPIREVAL"
    wait_secs = 1

    assert "OK" = FakeRedis.command!(conn, ~w(SET TESTKEY #{example_val}))
    assert true = FakeRedis.command!(conn, ~w(EXPIRE TESTKEY #{wait_secs}))

    assert example_val === FakeRedis.command!(conn, ~w(GET TESTKEY))
    :timer.sleep(1)

    intermediate_ttl = FakeRedis.command!(conn, ~w(TTL TESTKEY))
    assert intermediate_ttl < wait_secs
    refute intermediate_ttl < 0

    :timer.sleep(wait_secs * 1000)
    assert nil === FakeRedis.command!(conn, ~w(GET TESTKEY))
  end

  test "pexpire/2, pttl/1: expiring keys in ms after set", %{conn: conn} do
    example_val = "PEXPIREVAL"
    wait_msecs = 500

    assert "OK" = FakeRedis.command!(conn, ~w(SET TESTKEY #{example_val}))
    assert true = FakeRedis.command!(conn, ~w(PEXPIRE TESTKEY #{wait_msecs}))

    assert example_val === FakeRedis.command!(conn, ~w(GET TESTKEY))

    :timer.sleep(1)
    intermediate_ttl = FakeRedis.command!(conn, ~w(PTTL TESTKEY))
    assert intermediate_ttl < wait_msecs
    refute intermediate_ttl < 0

    :timer.sleep(wait_msecs)
    assert nil === FakeRedis.command!(conn, ~w(GET TESTKEY))
  end

end