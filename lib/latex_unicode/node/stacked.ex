defmodule LatexUnicode.Node.Stacked do
  @moduledoc """
  `\\substack{…}`: the rows written one per `\\\\`, centered on each other.

  pi treats the command as a plain wrapper, so its rows come back as one string with
  newlines in it — and an operator measuring its limits as a single line puts those
  rows nowhere in particular. Laid out as a block, they stack the way a sum's limits
  want them.
  """

  @type t :: %__MODULE__{
          lines: [String.t()]
        }

  defstruct [:lines]
end
