defmodule LatexUnicode.DelimitersTest do
  use ExUnit.Case, async: true

  alias LatexUnicode

  # pi reads `\left( … \right)` as plain text, so its delimiters stay one row however
  # tall the body is: `\left(\frac{a}{b}\right)` stacks the fraction between a
  # one-row pair, and beside a matrix only the first row has anything. These cases
  # are what this library does instead — the delimiters are sized to the body, out of
  # the same pieces the matrix environments draw with — and the inline ones are the
  # ones pi's own `renderLatex` gives, character for character.

  describe "inline math" do
    test "keeps pi's delimiters, one row and unsized" do
      assert LatexUnicode.render("\\left( x \\right)") == "( x )"
      assert LatexUnicode.render("x + \\left(y\\right) + z") == "x + (y) + z"
      assert LatexUnicode.render("\\left(\\frac{a}{b}\\right)") == "(a/b)"
      assert LatexUnicode.render("\\left\\langle x \\right\\rangle") == "⟨ x ⟩"
    end

    test "drops the size commands, as pi does" do
      assert LatexUnicode.render("\\big(x\\big)") == "(x)"
      assert LatexUnicode.render("\\Bigg[ x \\Bigg]") == "[ x ]"
    end
  end

  describe "display math" do
    test "sizes the parentheses to a stacked fraction" do
      assert LatexUnicode.render("\\left(\\frac{a}{b}\\right)", display: true) ==
               "⎛ a⎞\n⎜ ─⎟\n⎝ b⎠"
    end

    test "sizes the braces to a stacked fraction" do
      assert LatexUnicode.render("\\left\\{ \\frac{a}{b} \\right\\}", display: true) ==
               "⎧ a⎫\n⎨ ─⎬\n⎩ b⎭"
    end

    test "sizes the brackets to a matrix, every row of it" do
      assert LatexUnicode.render(
               "\\left[ \\begin{matrix} 1 & 2 \\\\ 3 & 4 \\\\ 5 & 6 \\end{matrix} \\right]",
               display: true
             ) == "⎡1 │ 2⎤\n⎢3 │ 4⎥\n⎣5 │ 6⎦"
    end

    test "repeats a delimiter that has no tall pieces" do
      assert LatexUnicode.render("\\left\\langle \\frac{a}{b} \\right\\rangle", display: true) ==
               "⟨ a⟩\n⟨ ─⟩\n⟨ b⟩"
    end

    test "leaves a one-row body at the single character" do
      # The body is laid out as a group of its own, which trims the spaces the source
      # put inside it; inline they are still text and stay.
      assert LatexUnicode.render("\\left( x \\right)", display: true) == "(x)"
      assert LatexUnicode.render("\\left(\\left( x \\right)\\right)", display: true) == "((x))"
    end

    test "draws nothing for an invisible delimiter" do
      assert LatexUnicode.render("\\left. \\frac{a}{b} \\right|_0^1", display: true) ==
               "a│\n─│₀¹\nb│"
    end

    test "nests a matrix inside its own delimiters" do
      assert LatexUnicode.render(
               "\\left(\\begin{pmatrix} 1 & 2 \\\\ 3 & 4 \\end{pmatrix}\\right)",
               display: true
             ) == "⎛⎛ 1 │ 2 ⎞⎞\n⎝⎝ 3 │ 4 ⎠⎠"
    end
  end

  describe "the size commands" do
    test "draw two rows for \\big and \\Big" do
      assert LatexUnicode.render("\\big(x\\big)", display: true) == "⎛ ⎞\n⎝x⎠"

      assert LatexUnicode.render("\\Big[ \\frac{a}{b} \\Big]", display: true) ==
               "⎡ a ⎤\n⎣ ─ ⎦\n  b"
    end

    test "draw three rows for \\bigg and \\Bigg" do
      assert LatexUnicode.render("\\bigg\\{ x \\bigg\\}", display: true) == "⎧ ⎫\n⎨x⎬\n⎩ ⎭"
    end
  end

  describe "an unclosed group" do
    test "renders the delimiter that follows, as pi does" do
      assert LatexUnicode.render("\\left( x", display: true) == "( x"
    end
  end
end
