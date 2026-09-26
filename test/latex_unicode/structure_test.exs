defmodule LatexUnicode.StructureTest do
  use ExUnit.Case, async: true

  alias LatexUnicode

  # Three things pi leaves undone, each with the inline rendering it gives them kept
  # exactly: the inline values below are pi's own `renderLatex` output, run under bun
  # to check, and the display ones are what this library does instead.
  describe "\\substack" do
    test "stacks its rows in display math" do
      assert LatexUnicode.render("\\substack{a \\\\ b}", display: true) == "a\nb"
    end

    test "stacks a sum's limits, centered under the operator" do
      assert LatexUnicode.render("\\sum_{\\substack{i=0 \\\\ j=0}}^n x", display: true) ==
               "  n\n  ∑   x\ni = 0\nj = 0"
    end

    test "stays the wrapper pi renders inline" do
      assert LatexUnicode.render("\\substack{a \\\\ b}") == "a\nb"

      assert LatexUnicode.render("\\sum_{\\substack{i=0 \\\\ j=0}}^n x") ==
               "∑_(i=0\nj=0)ⁿ x"
    end
  end

  describe "\\overbrace and \\underbrace" do
    test "draw the brace across the body" do
      assert LatexUnicode.render("\\overbrace{x+y}", display: true) == "⏞⏞⏞\nx+y"
      assert LatexUnicode.render("\\underbrace{x+y}", display: true) == "x+y\n⏟⏟⏟"
    end

    test "put the label on the side its script asks for" do
      assert LatexUnicode.render("\\overbrace{x+y}^{n}", display: true) == " n\n⏞⏞⏞\nx+y"
      assert LatexUnicode.render("\\overbrace{x+y}_{n}", display: true) == "⏞⏞⏞\n n\nx+y"
      assert LatexUnicode.render("\\underbrace{x+y}_{n}", display: true) == "x+y\n⏟⏟⏟\n n"
      assert LatexUnicode.render("\\underbrace{x+y}^{n}", display: true) == " n\nx+y\n⏟⏟⏟"
    end

    test "span whatever the body lays out to" do
      assert LatexUnicode.render("\\overbrace{\\frac{a}{b}}^{n}", display: true) ==
               "n\n⏞⏞\n a\n ─\n b"
    end

    test "stay the wrapper pi renders inline, label and all" do
      assert LatexUnicode.render("\\overbrace{x+y}^{n}") == "x+yⁿ"
      assert LatexUnicode.render("\\underbrace{x+y}_{n}") == "x+yₙ"
      assert LatexUnicode.render("\\overbrace{x+y}") == "x+y"
    end
  end

  describe "\\hline" do
    test "is a rule between the rows, not an unsupported command" do
      assert LatexUnicode.render("\\begin{array}{c} a \\\\ \\hline b \\end{array}", display: true) ==
               "a\n─\nb"
    end

    test "crosses the column separators" do
      assert LatexUnicode.render(
               "\\begin{array}{cc} a & b \\\\ \\hline c & d \\end{array}",
               display: true
             ) == "a │ b\n──┼──\nc │ d"
    end

    test "is drawn inside a matrix's delimiters" do
      assert LatexUnicode.render("\\begin{pmatrix} 1 & 2 \\\\ \\hline 3 & 4 \\end{pmatrix}",
               display: true
             ) ==
               "⎛ 1 │ 2 ⎞\n⎜ ──┼── ⎟\n⎝ 3 │ 4 ⎠"
    end

    test "draws before the first row and after the last" do
      assert LatexUnicode.render("\\begin{array}{c} \\hline a \\\\ b \\hline \\end{array}",
               display: true
             ) ==
               "─\na\nb\n─"
    end

    test "leaves rows without a rule alone" do
      assert LatexUnicode.render("\\begin{array}{c} a \\\\ b \\end{array}", display: true) ==
               "a\nb"
    end
  end
end
