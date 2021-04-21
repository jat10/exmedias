defmodule Media.Context do
  @moduledoc """
    The context module defines the functions that should be invoked in the parent app.
    Consider this as the API of the Media.
  """
  alias Media.Helpers

  def insert(args) do
    DB.insert(Helpers.db_struct(args))
  end

  def get(args) do
    DB.get(Helpers.db_struct(args))
  end

  def delete(args) do
    DB.delete(Helpers.db_struct(args))
  end

  def update(args) do
    DB.update(Helpers.db_struct(args))
  end
end
