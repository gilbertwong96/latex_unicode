defmodule LatexUnicode.Layout do
  @moduledoc """
  One laid-out piece of a line: its lines, the width they are padded to, and the
  index of the line the text beside it aligns on.

  The display pass produces one of these for every piece it lays out — a
  matrix's rows, a fraction's stacked numerator and denominator, a run of plain
  text between two markers — and then zips them onto a shared baseline grid, so
  a fraction's bar lines up with the text it sits in. `baseline` is that index
  into `lines`; a layout whose text is a single line has `baseline: 0`.
  """

  @type t :: %__MODULE__{
          lines: [String.t()],
          width: non_neg_integer(),
          baseline: non_neg_integer()
        }

  defstruct [:lines, :width, :baseline]
end
