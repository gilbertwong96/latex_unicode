defmodule LatexUnicode.Node.Operator do
  @moduledoc """
  A named operator whose limits go above and below it (`\\sum_{i=0}^n`) instead
  of beside it: the operator's rendered text and whichever limits it was given.
  """

  @type t :: %__MODULE__{
          operator: String.t(),
          lower: String.t() | nil,
          upper: String.t() | nil
        }

  defstruct [:operator, :lower, :upper]
end
