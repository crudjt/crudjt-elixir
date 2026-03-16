require Logger

if System.get_env("CRUDJT_AUTOTEST_ALLOWED") != "true" do
  IO.puts("Denied run autotest for this environment. Set ENV['CRUDJT_AUTOTEST_ALLOWED'] = 'true'")
  System.halt(1)
end

CRUDJT.Config.start_master(
  secret_key: "Cm7B68NWsMNNYjzMDREacmpe5sI1o0g40ZC9w1yQW3WOes7Gm59UsittLOHR2dciYiwmaYq98l3tG8h9yXVCxg=="
)

IO.puts("OS: #{inspect(:os.type())}")

arch = :erlang.system_info(:system_architecture) |> to_string()
IO.puts("CPU: #{arch}")

# without metadata
IO.puts("Checking without metadata...")
data = %{"user_id" => 42, "role" => 11}
expected_data = %{"data" => data}

ed_data = %{"user_id" => 42, "role" => 8}
expected_ed_data = %{"data" => ed_data}

token = CRUDJT.create(data)

IO.puts(CRUDJT.read(token) == expected_data)
IO.puts(CRUDJT.update(token, ed_data) == true)
IO.puts(CRUDJT.read(token) == expected_ed_data)
IO.puts(CRUDJT.delete(token) == true)
IO.puts(CRUDJT.read(token) == nil)

# with ttl
IO.puts("Checking ttl...")

ttl = 5
token_with_ttl = CRUDJT.create(data, ttl)

for i <- 0..(ttl - 1) do
  expected_result = %{"metadata" => %{"ttl" => ttl - i}, "data" => data}
  IO.puts(CRUDJT.read(token_with_ttl) == expected_result)
  :timer.sleep(1000)
end
IO.puts(CRUDJT.read(token_with_ttl) == nil)

# when expired ttl
IO.puts("When expired ttl")
ttl = 1
token = CRUDJT.create(data, ttl)
:timer.sleep(ttl * 1000)
IO.puts(CRUDJT.read(token) == nil)
IO.puts(CRUDJT.update(token, data) == false)
IO.puts(CRUDJT.delete(token) == false)

# with silence_read
IO.puts("Checking silence_read...")

data = %{"user_id" => 42, "role" => 11}
silence_read = 6
token_with_silence_read = CRUDJT.create(data, nil, silence_read)

for i <- 1..silence_read do
  expected_result = %{"metadata" => %{"silence_read" => silence_read - i}, "data" => data}
  IO.puts(CRUDJT.read(token_with_silence_read) == expected_result)
end
IO.puts(CRUDJT.read(token_with_silence_read) == nil)

# with ttl and silence_read
IO.puts("Checking ttl and silence_read...")

ttl = 5
silence_read = ttl
token_with_ttl_and_silence_read = CRUDJT.create(data, ttl, silence_read)

expected_ttl = ttl
expected_silence_read = silence_read - 1
for i <- 1..silence_read do
  expected_result = %{
    "metadata" => %{"ttl" => ttl - i + 1, "silence_read" => silence_read - i},
    "data" => data
  }
  IO.puts(CRUDJT.read(token_with_ttl_and_silence_read) == expected_result)
  :timer.sleep(1000)
  expected_ttl = expected_ttl - 1
  expected_silence_read = expected_silence_read - 1
end
IO.puts(CRUDJT.read(token_with_ttl_and_silence_read) == nil)

requests = 40_000

data = %{
  user_id: 414243,
  role: 11,
  devices: %{
    ios_expired_at: DateTime.utc_now() |> DateTime.to_string(),
    android_expired_at: DateTime.utc_now() |> DateTime.to_string(),
    mobile_app_expired_at: DateTime.utc_now() |> DateTime.to_string(),
    external_api_integration_expired_at: DateTime.utc_now() |> DateTime.to_string()
  },
  a: 42
}

ed_data = %{user_id: 42, role: 11}

IO.puts("Checking scale load...")

for i <- 1..10 do
  list = []

  IO.puts("when creates 40k tokens")
  {time, list} = :timer.tc(fn ->
    Enum.reduce(1..requests, [], fn _, acc ->
      [CRUDJT.create(data) | acc]
    end)
  end)
  IO.puts("#{time / 1_000_000} seconds") # Перетворюємо на секунди

  list = Enum.reverse(list)

  IO.puts("when reads 40k tokens")
  {time, _} = :timer.tc(fn ->
    Enum.each(list, fn token ->
      CRUDJT.read(token)
    end)
  end)
  IO.puts("#{time / 1_000_000} seconds") # Перетворюємо на секунди

  IO.puts("when updates 40k tokens")
  {time, _} = :timer.tc(fn ->
    Enum.each(list, fn token ->
      CRUDJT.update(token, ed_data)
    end)
  end)
  IO.puts("#{time / 1_000_000} seconds") # Перетворюємо на секунди

  IO.puts("when deletes 40k tokens")
  {time, _} = :timer.tc(fn ->
    Enum.each(list, fn token ->
      CRUDJT.delete(token)
    end)
  end)
  IO.puts("#{time / 1_000_000} seconds") # Перетворюємо на секунди
end

IO.puts("when caches after read from file system")
limit_for_cache = 2
previous_values = []

{time, previous_values} = :timer.tc(fn ->
  Enum.reduce(1..requests, [], fn _, acc ->
    [CRUDJT.create(data) | acc]
  end)
end)

for _ <- 1..requests do
  CRUDJT.create(data)
end

previous_values = Enum.reverse(previous_values)

for _ <- 1..limit_for_cache do
  {time, _} = :timer.tc(fn ->
    Enum.each(previous_values, fn token ->
      CRUDJT.read(token)
    end)
  end)
  IO.puts("#{time / 1_000_000} seconds")
end
