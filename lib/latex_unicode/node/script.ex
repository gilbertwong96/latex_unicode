defmodule LatexUnicode.Node.Script do
  @moduledoc """
  A script pair that is laid out on its own lines instead of being substituted
  into Unicode — either because the script has no Unicode form, or because it
  sits inside another script, where the substitution has nothing to give.
  """

  @type t :: %__MODULE__{
          upper: String.t() | nil,
          lower: String.t() | nil
        }

  defstruct [:upper, :lower]
end
