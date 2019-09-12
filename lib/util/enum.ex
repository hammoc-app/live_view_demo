defmodule Util.Enum do
  @moduledoc "Collection of utility functions for Enum-compatible data types."

  @doc """
  Count occurences and return a map containing the counts.

  ## Examples

      iex> [1, 3, 3, 7]
      ...> |> Util.Enum.count()
      %{1 => 1, 3 => 2, 7 => 1}
  """
  def count(enum) do
    Enum.reduce(enum, %{}, fn elem, acc ->
      Map.update(acc, elem, 1, &(&1 + 1))
    end)
  end

  @doc """
  Count occurences mapped by a function and return a map containing the counts.

  ## Examples

      iex> [1, 3, 3, 7]
      ...> |> Util.Enum.count(& &1 + 1)
      %{2 => 1, 4 => 2, 8 => 1}
  """
  def count(enum, mapper) do
    Enum.reduce(enum, %{}, fn elem, acc ->
      Map.update(acc, mapper.(elem), 1, &(&1 + 1))
    end)
  end

  @doc """
  Takes a count map (from count/1 or count/2) and returns top n elements with counts.

  ## Examples

      iex> %{bertha: 1, bob: 2, emily: 1, cho: 3, mani: 6}
      ...> |> Util.Enum.top_counts(3)
      [mani: 6, cho: 3, bob: 2]
  """
  def top_counts(count_map, top \\ 5) do
    count_map
    |> Enum.sort_by(&elem(&1, 1), &>=/2)
    |> Enum.take(top)
  end
end
