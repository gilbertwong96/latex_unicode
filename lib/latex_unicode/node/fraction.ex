defmodule LatexUnicode.Node.Fraction do
  @moduledoc """
  A fraction that is stacked rather than written inline: the numerator's
  rendered text, the denominator's, and a bar between them (drawn by the
  display pass, not stored here).
  """

  @type t :: %__MODULE__{
          numerator: String.t(),
          denominator: String.t()
        }

  defstruct [:numerator, :denominator]
end
