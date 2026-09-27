defmodule LatexUnicode.Width.Ranges do
  @moduledoc """
  Membership in the width data's range tables.

  Every table is a tuple of inclusive `[first, last, ...]` pairs, so one probe is a
  constant-time lookup.
  """

  @doc """
  Whether `codepoint` falls in any of the table's ranges.

  Binary search over the flattened pairs, the way pi's `isInRange` walks the same data.
  """
  @spec member?(tuple(), non_neg_integer()) :: boolean()
  def member?(ranges, codepoint) do
    search(ranges, codepoint, 0, div(tuple_size(ranges), 2) - 1)
  end

  defp search(_ranges, _codepoint, low, high) when low > high, do: false

  defp search(ranges, codepoint, low, high) do
    middle = div(low + high, 2)
    first = elem(ranges, middle * 2)
    last = elem(ranges, middle * 2 + 1)

    cond do
      codepoint < first -> search(ranges, codepoint, low, middle - 1)
      codepoint > last -> search(ranges, codepoint, middle + 1, high)
      true -> true
    end
  end
end
