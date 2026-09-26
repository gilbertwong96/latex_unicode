defmodule LatexUnicode.Node.Matrix do
  @moduledoc """
  A display environment's rows, already laid out, and the index of the row the
  text beside the matrix aligns on — the middle row for `cases`, the first row
  for a matrix.
  """

  @type t :: %__MODULE__{
          lines: [String.t()],
          baseline: non_neg_integer()
        }

  defstruct [:lines, :baseline]
end
