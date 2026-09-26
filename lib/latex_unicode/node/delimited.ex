defmodule LatexUnicode.Node.Delimited do
  @moduledoc """
  A group whose delimiters grow with what they wrap: `\\left( … \\right)`, and the
  fixed heights `\\big(` and friends ask for.

  The body is rendered when the group is read, the way a fraction's numerator is,
  and laid out by the display pass so the delimiters can be sized to its height: one
  character when the body fits on a line, the stacking pieces above and below it when
  it does not. `height` is set by the size commands, which name a height instead of
  leaving it to the body; `left` and `right` are `nil` when the delimiter is
  invisible, as in `\\left.`.
  """

  @type t :: %__MODULE__{
          left: String.t() | nil,
          body: String.t(),
          right: String.t() | nil,
          height: 2 | 3 | nil
        }

  defstruct [:left, :body, :right, :height]
end
