<p align="center">
  <img src="logos/crud_jt_logo_black.png#gh-light-mode-only" alt="Logo Light" />
  <img src="logos/crud_jt_logo.png#gh-dark-mode-only" alt="Logo Dark" />
</p>

<p align="center">
  Simplifies user session. Login/Logout/Authorization
</p>

<p align="center">
  <a href="https://www.patreon.com/exwarvlad">
    <img src="logos/buy_me_a_coffee_orange.svg" alt="Buy Me a Coffee"/>
  </a>
</p>

# Installation

```elixir
def deps do
  [
    {:crudjt, "~> 1.0.0"}
  ]
end
```

Configure CRUD JT in your project

```elixir
# openssl rand -base64 48 # In your terminal
# => your_encrypted_base64/48
CRUD_JT.start(%CRUD_JT.Config{
  encrypted_key: "your_encrypted_base64/32/48/64",
  store_jt_path: "your_path_to_file_storage" # optional
})
```

# C

```elixir
CRUD_JT.create(%{"user_id" => 42, "role" => 11})
=> "HBmKFXoXgJ46mCqer1WXyQ"
```

```elixir
# with ttl — token time-to-live in seconds
ttl = 3600 * 24 * 30

CRUD_JT.create(%{"user_id" => 42, "role" => 11}, ttl)
=> "HBmKFXoXgJ46mCqer1WXyQ"
```

```elixir
☕ = 🐰🥚
```

# R

```elixir
# ...
CRUD_JT.read("HBmKFXoXgJ46mCqer1WXyQ")
=> %{"data" => %{"user_id"=>42, "role"=>11}}
```

```elixir
# with ttl
CRUD_JT.read("HBmKFXoXgJ46mCqer1WXyQ")
=> %{"metadata" => %{"ttl" => 3}, "data" => %{"user_id" => 42, "role" => 11}}

# after 1 second
CRUD_JT.read("HBmKFXoXgJ46mCqer1WXyQ")
=> %{"metadata" => %{"ttl" => 2}, "data" => %{"user_id" => 42, "role" => 11}}

# still second
CRUD_JT.read("HBmKFXoXgJ46mCqer1WXyQ")
=> %{"metadata" => %{"ttl" => 1}, "data" => %{"user_id" => 42, "role" => 11}}

# ups
CRUD_JT.read("HBmKFXoXgJ46mCqer1WXyQ")
=> nil
```

```elixir
# with 🐰🥚
```

# U

```elixir
CRUD_JT.update("HBmKFXoXgJ46mCqer1WXyQ", %{"user_id" => 42, "role" => 8})
=> true # %{"data" => %{"user_id" => 42, %"role" => 8}}
```

```elixir
# supported for ttl
ttl = 41

CRUD_JT.update("HBmKFXoXgJ46mCqer1WXyQ", %{"user_id" => 42, "role" => 8}, ttl)
=> true # %{"metadata" => %{"ttl" => 41}, "data" => %{"user_id"=>42, "role" => 8}}
```

```elixir
# supported for 🐰🥚
```

```elixir
# when expired/not found token
CRUD_JT.update("HBmKFXoXgJ46mCqer1WXyQ", %{"user_id" => 42, "role" => 8})
=> false
```

# D
```elixir
# when token exist
CRUD_JT.delete("HBmKFXoXgJ46mCqer1WXyQ")
=> true
```

```elixir
# when expired/not found token
CRUD_JT.delete("HBmKFXoXgJ46mCqer1WXyQ")
=> false
```

# Performance
**40k** requests of **256 bytes** — median over 10 runs  
ARM64 (Apple M1+), macOS 15.6.1  
Elixir 1.18.4 (Erlang/OTP 27)

| Function | CRUD JT (Elixir) | JWT (Elixir) | redis-session-store (Ruby, Rails 8.0.4) |
|----------|-------|------|------|
| C        | 0.36 second | ⭐ 0.2965 second | 4.057 seconds |
| R        | `0.038 second` ![Logo Favicon Light](logos/crud_jt_logo_favicon_white.png#gh-light-mode-only) ![Logo Favicon Dark](logos/crud_jt_logo_favicon_black.png#gh-dark-mode-only) | 0.3795 second | 7.011 seconds |
| U        | `0.461 second` ![Logo Favicon Light](logos/crud_jt_logo_favicon_white.png#gh-light-mode-only) ![Logo Favicon Dark](logos/crud_jt_logo_favicon_black.png#gh-dark-mode-only) | X | 3.49 seconds |
| D        | `0.232 second` ![Logo Favicon Light](logos/crud_jt_logo_favicon_white.png#gh-light-mode-only) ![Logo Favicon Dark](logos/crud_jt_logo_favicon_black.png#gh-dark-mode-only) | X | 6.589 seconds |

[Full results](https://github.com/exwarvlad/benchmarks)

# Storage (Store JT)

## Path Lookup Order
Stored tokens are placed in the **file system** according to the following order

1. Explicitly set via `%CRUD_JT.Config{store_jt_path: "custom/path/to/file_system_db"}`
2. Default system location
   - **Linux**: `/var/lib/store_jt`
   - **macOS**: `/usr/local/var/store_jt`
   - **Windows**: `C:\Program Files\store_jt`
3. Project root directory (fallback)

## Storage Characteristics
* Store JT **automatically removing expired tokens** every 24 hours without blocking the main thread   
* **Store JT automatically fsyncs every 500ms**, meanwhile tokens ​​are available from cache
* Store JT is available for one process to open per instance for the time being

## Configuration

You can configure the library before starting it

```elixir
# Required configuration
CRUD_JT.start(%CRUD_JT.Config{
  encrypted_key: "your_encrypted_base64/32/48/64"
})

# Optional configuration
CRUD_JT.start(%CRUD_JT.Config{
  encrypted_key: "your_encrypted_base64/32/48/64",
  store_jt_path: "/custom/path/to/file_storage_db"
})
```

`CRUD_JT.start(config)`  
Initializes the CRUD JT process and opens the Store JT using the given configuration  
Must be called before performing any operations  

###### Configuration options (`%CRUD_JT.Config{}`)  

`encrypted_key :: String.t()`  
Specifies the encrypted key (in Base64 format)  
**Required**

`store_jt_path :: String.t()`  
Overrides the default File DB storage path  
**Optional**

# Limits
The library has the following limits and requirements

- **Elixir version:** tested with 1.17.3 | Erlang/OTP >= 27
- **Supported platforms:** Linux, macOS, Windows (x86_64 / arm64)
- **Maximum json size per token:** 256 bytes
- **`encrypted_key` format:** must be Base64
- **`encrypted_key` size:** must be 32, 48, or 64 bytes

# Contact & Support
<p align="center">
  <img src="logos/crud_jt_logo_favicon_black_160.png#gh-light-mode-only" alt="Visit Light" />
  <img src="logos/crud_jt_logo_favicon_white_160.png#gh-dark-mode-only" alt="Visit Dark" />
</p>

- **Custom integrations / new features / collaboration**: support@crudjt.com  
- **Library support & bug reports:** [open an issue](https://github.com/crudjt/crudjt-elixir/issues)


# Lincense
CRUD JT is released under the [MIT License](LICENSE.txt)

<p align="center">
  💘 Shoot your g . ? Love me out via <a href="https://www.patreon.com/exwarvlad">Github Sponsors</a>!
</p>
