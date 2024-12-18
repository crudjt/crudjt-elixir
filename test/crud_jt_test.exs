require Logger

IO.puts("OS: #{inspect(:os.type())}")

arch = :erlang.system_info(:system_architecture) |> to_string()
IO.puts("CPU: #{arch}")

# without metadata
IO.puts("Checking without metadata...")
data = %{"user_id" => 42, "role" => 11}
expected_data = %{"data" => data}

ed_data = %{"user_id" => 42, "role" => 8}
expected_ed_data = %{"data" => ed_data}

token = CRUD_JT.create(data)

IO.puts(CRUD_JT.read(token) == expected_data)
IO.puts(CRUD_JT.update(token, ed_data) == true)
IO.puts(CRUD_JT.read(token) == expected_ed_data)
IO.puts(CRUD_JT.delete(token) == true)
IO.puts(CRUD_JT.read(token) == nil)

# with ttl
IO.puts("Checking ttl...")

ttl = 5
token_with_ttl = CRUD_JT.create(data, ttl)

for i <- 0..(ttl - 1) do
  expected_result = %{"metadata" => %{"ttl" => ttl - i}, "data" => data}
  IO.puts(CRUD_JT.read(token_with_ttl) == expected_result)
  :timer.sleep(1000)
end
IO.puts(CRUD_JT.read(token_with_ttl) == nil)

# when expired ttl
IO.puts("When expired ttl")
ttl = 1
token = CRUD_JT.create(data, ttl)
:timer.sleep(ttl * 1000)
IO.puts(CRUD_JT.read(token) == nil)
IO.puts(CRUD_JT.update(token, data) == false)
IO.puts(CRUD_JT.delete(token) == false)

# with silence_read
IO.puts("Checking silence_read...")

data = %{"user_id" => 42, "role" => 11}
silence_read = 6
token_with_silence_read = CRUD_JT.create(data, -1, silence_read)

for i <- 1..silence_read do
  expected_result = %{"metadata" => %{"silence_read" => silence_read - i}, "data" => data}
  IO.puts(CRUD_JT.read(token_with_silence_read) == expected_result)
end
IO.puts(CRUD_JT.read(token_with_silence_read) == nil)

# with ttl and silence_read
IO.puts("Checking ttl and silence_read...")

ttl = 5
silence_read = ttl
token_with_ttl_and_silence_read = CRUD_JT.create(data, ttl, silence_read)

expected_ttl = ttl
expected_silence_read = silence_read - 1
for i <- 1..silence_read do
  expected_result = %{
    "metadata" => %{"ttl" => ttl - i + 1, "silence_read" => silence_read - i},
    "data" => data
  }
  IO.puts(CRUD_JT.read(token_with_ttl_and_silence_read) == expected_result)
  :timer.sleep(1000)
  expected_ttl = expected_ttl - 1
  expected_silence_read = expected_silence_read - 1
end
IO.puts(CRUD_JT.read(token_with_ttl_and_silence_read) == nil)

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

  IO.puts("when creates 40k tokens with Turbo Queue")
  {time, list} = :timer.tc(fn ->
    Enum.reduce(1..requests, [], fn _, acc ->
      [CRUD_JT.create(data) | acc]
    end)
  end)
  IO.puts("#{time / 1_000_000} seconds") # Перетворюємо на секунди

  list = Enum.reverse(list)

  IO.puts("when reads 40k tokens")
  {time, _} = :timer.tc(fn ->
    Enum.each(list, fn token ->
      CRUD_JT.read(token)
    end)
  end)
  IO.puts("#{time / 1_000_000} seconds") # Перетворюємо на секунди

  IO.puts("when updates 40k tokens")
  {time, _} = :timer.tc(fn ->
    Enum.each(list, fn token ->
      CRUD_JT.update(token, ed_data)
    end)
  end)
  IO.puts("#{time / 1_000_000} seconds") # Перетворюємо на секунди

  IO.puts("when deletes 40k tokens")
  {time, _} = :timer.tc(fn ->
    Enum.each(list, fn token ->
      CRUD_JT.delete(token)
    end)
  end)
  IO.puts("#{time / 1_000_000} seconds") # Перетворюємо на секунди
end

IO.puts("when caches after read from file system")
limit_for_cache = 2
previous_values = []

{time, previous_values} = :timer.tc(fn ->
  Enum.reduce(1..requests, [], fn _, acc ->
    [CRUD_JT.create(data) | acc]
  end)
end)

for _ <- 1..requests do
  CRUD_JT.create(data)
end

previous_values = Enum.reverse(previous_values)

for _ <- 1..limit_for_cache do
  {time, _} = :timer.tc(fn ->
    Enum.each(previous_values, fn token ->
      CRUD_JT.read(token)
    end)
  end)
  IO.puts("#{time / 1_000_000} seconds")
end
