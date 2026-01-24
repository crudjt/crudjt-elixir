defmodule CRUDJT_Errors do
  @errors %{
    "XX000" => Errors.InternalError,
    "55JT01" => Errors.InvalidState
  }

  def errors, do: @errors
end
