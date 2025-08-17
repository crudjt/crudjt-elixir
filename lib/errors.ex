defmodule Errors do
  alias MyLib.Errors.InternalError

  @errors %{
    "XX000" => InternalError
  }

  def errors, do: @errors
end
