defmodule LatexUnicode.Node.Braced do
  @moduledoc """
  `\\overbrace{…}` and `\\underbrace{…}`: a body, a brace drawn across its width, and
  the label the source gave it on the side its script asked for.

  pi treats both commands as plain wrappers, which loses the brace and sets the label
  beside the body as a script. The brace needs a row of its own, so it is drawn in
  display math, where there are rows to spare.
  """

  @type t :: %__MODULE__{
          body: String.t(),
          label: String.t() | nil,
          label_side: :above | :below | nil,
          kind: :over | :under
        }

  defstruct [:body, :label, :label_side, :kind]
end
