defmodule LatexUnicode.AlphabetTest do
  use ExUnit.Case, async: true

  alias LatexUnicode

  # pi leaves `\mathcal`, `\mathscr` and `\mathfrak` as plain wrappers, so these
  # cases are this library's own. Only the letterlike codepoints are substituted:
  # the rest of each alphabet is in the Mathematical Alphanumeric Symbols block
  # (U+1D49C onward), where a terminal font usually has nothing to draw, so a
  # letter with no letterlike codepoint keeps its own — the same line `\mathbb`
  # has always drawn.
  describe "\\mathcal and \\mathscr" do
    test "take the script letters that have a codepoint" do
      assert LatexUnicode.render("\\mathcal{B}") == "ℬ"
      assert LatexUnicode.render("\\mathcal{E}") == "ℰ"
      assert LatexUnicode.render("\\mathcal{F}") == "ℱ"
      assert LatexUnicode.render("\\mathcal{H}") == "ℋ"
      assert LatexUnicode.render("\\mathcal{I}") == "ℐ"
      assert LatexUnicode.render("\\mathcal{L}") == "ℒ"
      assert LatexUnicode.render("\\mathcal{M}") == "ℳ"
      assert LatexUnicode.render("\\mathcal{R}") == "ℛ"
      assert LatexUnicode.render("\\mathcal{e}") == "ℯ"
      assert LatexUnicode.render("\\mathcal{g}") == "ℊ"
      assert LatexUnicode.render("\\mathcal{o}") == "ℴ"
    end

    test "leave a letter with no letterlike codepoint alone" do
      assert LatexUnicode.render("\\mathcal{A}") == "A"
      assert LatexUnicode.render("\\mathcal{P}(X)") == "P(X)"
      assert LatexUnicode.render("\\mathcal{AB}") == "Aℬ"
    end

    test "render in place, inside a larger expression" do
      assert LatexUnicode.render("\\mathcal{L}(V)") == "ℒ(V)"
      assert LatexUnicode.render("\\mathcal{F}_q") == "ℱ_q"
      assert LatexUnicode.render("x + \\mathcal{F}") == "x + ℱ"
      assert LatexUnicode.render("\\mathcal{\\alpha}") == "α"
    end

    test "are the same alphabet" do
      assert LatexUnicode.render("\\mathscr{L}") == LatexUnicode.render("\\mathcal{L}")
      assert LatexUnicode.render("\\mathscr{F}") == "ℱ"
    end
  end

  describe "\\mathfrak" do
    test "takes the black-letter letters that have a codepoint" do
      assert LatexUnicode.render("\\mathfrak{C}") == "ℭ"
      assert LatexUnicode.render("\\mathfrak{H}") == "ℌ"
      assert LatexUnicode.render("\\mathfrak{I}") == "ℑ"
      assert LatexUnicode.render("\\mathfrak{R}") == "ℜ"
      assert LatexUnicode.render("\\mathfrak{Z}") == "ℨ"
    end

    test "leaves the letters that only exist in the mathematical block alone" do
      assert LatexUnicode.render("\\mathfrak{g}") == "g"
      assert LatexUnicode.render("\\mathfrak{sl}_2") == "sl₂"
    end
  end

  describe "\\mathbb" do
    test "still takes the blackboard letters and nothing else" do
      assert LatexUnicode.render("\\mathbb{R}^n") == "ℝⁿ"
      assert LatexUnicode.render("\\mathbb{A}") == "A"
    end
  end
end
