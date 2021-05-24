defmodule Media.Cartesian do
  @moduledoc """
  This module is a helper to compute the cartesian product of a list of lists
  In other words, it outputs all the possible combinations of this list of list
  [[1,2,3], [4,5,6]] will produce
  [1,4], [1,5], [1,6], [2,4], [2,5], [2,6], [3,4], [3,5], [3,6]
  """
  def product([]) do
    []
  end

  def product(nil) do
    []
  end

  def product([head | rest]) do
    iterate(head, rest, [])
    |> Enum.map(&Enum.reverse/1)
  end

  defp iterate(list, [], base) do
    Enum.map(list, fn item ->
      [item | base]
    end)
  end

  defp iterate(list, [head | rest], base) do
    Enum.flat_map(list, fn item ->
      iterate(head, rest, [item | base])
    end)
  end
end
