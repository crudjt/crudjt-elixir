defmodule RustlerExampleTest do
  use ExUnit.Case
  doctest RustlerExample

  test "greets the world" do
    assert RustlerExample.hello() == :world
  end
end
