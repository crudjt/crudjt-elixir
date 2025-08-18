defmodule Errors do
  @errors %{
    "XX000" => Errors.InternalError,
    "DE000" => Errors.DonateException
  }

  def errors, do: @errors
end
