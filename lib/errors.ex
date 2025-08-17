defmodule Errors do
  @errors %{
    "XX000" => InternalError,
    "DE000" => DonateException
  }

  def errors, do: @errors
end
