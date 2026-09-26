defmodule LatexUnicode.ApiTest do
  @moduledoc """
  Every case this library's own API was checked against, in one file, printing each
  one as it goes so the rendering can be read back in a terminal:

      mix test test/latex_unicode/api_test.exs --trace

  Each section prints its cases — the source, then what the renderer drew, indented
  under it — and then asserts the exact value, so the file is both the catalogue and
  the test. The catalogue is the half that matters to a terminal: the glyphs it has to
  have (⎛ ⎜ ⎝ ⎞ ⎟ ⎠, ⏞ ⏟, ℱ ℋ ℳ ℭ, ─ ┼ │) are only right when they can be looked at,
  and the width table says which of them a terminal counts as one cell and which as
  two.

  The cases pi renders differently, or not at all, are marked where they sit: the
  ported suite in `test/latex_unicode_test.exs` is pi's own behaviour, and this file is
  where this library's behaviour is written down.
  """

  use ExUnit.Case, async: false

  alias LatexUnicode
  alias LatexUnicode.Width

  # {source, options, expected}: the letterlike alphabets, which pi renders as plain
  # wrappers. Only the letterlike codepoints are substituted — the rest of each
  # alphabet is in the Mathematical Alphanumeric Symbols block (U+1D49C onward), where
  # a terminal font usually has nothing to draw — so a letter with no letterlike
  # codepoint keeps its own, the line `\mathbb` has always drawn.
  @alphabet_cases [
    {"\\mathcal{B}", [], "ℬ"},
    {"\\mathcal{E}", [], "ℰ"},
    {"\\mathcal{F}", [], "ℱ"},
    {"\\mathcal{H}", [], "ℋ"},
    {"\\mathcal{I}", [], "ℐ"},
    {"\\mathcal{L}", [], "ℒ"},
    {"\\mathcal{M}", [], "ℳ"},
    {"\\mathcal{R}", [], "ℛ"},
    {"\\mathcal{e}", [], "ℯ"},
    {"\\mathcal{g}", [], "ℊ"},
    {"\\mathcal{o}", [], "ℴ"},
    {"\\mathcal{A}", [], "A"},
    {"\\mathcal{P}(X)", [], "P(X)"},
    {"\\mathcal{AB}", [], "Aℬ"},
    {"\\mathcal{L}(V)", [], "ℒ(V)"},
    {"\\mathcal{F}_q", [], "ℱ_q"},
    {"x + \\mathcal{F}", [], "x + ℱ"},
    {"\\mathcal{\\alpha}", [], "α"},
    {"\\mathscr{L}", [], "ℒ"},
    {"\\mathscr{F}", [], "ℱ"},
    {"\\mathfrak{C}", [], "ℭ"},
    {"\\mathfrak{H}", [], "ℌ"},
    {"\\mathfrak{I}", [], "ℑ"},
    {"\\mathfrak{R}", [], "ℜ"},
    {"\\mathfrak{Z}", [], "ℨ"},
    {"\\mathfrak{g}", [], "g"},
    {"\\mathfrak{sl}_2", [], "sl₂"},
    {"\\mathbb{R}^n", [], "ℝⁿ"},
    {"\\mathbb{A}", [], "A"}
  ]

  # {source, options, expected}: `\left( … \right)` is sized to what it wraps here.
  # pi reads the pair as plain text, so its delimiters stay one row however tall the
  # body is. The inline cases below are pi's own output, character for character.
  @delimiter_cases [
    {"\\left( x \\right)", [], "( x )"},
    {"x + \\left(y\\right) + z", [], "x + (y) + z"},
    {"\\left(\\frac{a}{b}\\right)", [], "(a/b)"},
    {"\\left\\langle x \\right\\rangle", [], "⟨ x ⟩"},
    {"\\big(x\\big)", [], "(x)"},
    {"\\Bigg[ x \\Bigg]", [], "[ x ]"},
    {"\\left(\\frac{a}{b}\\right)", [display: true], "⎛ a⎞\n⎜ ─⎟\n⎝ b⎠"},
    {"\\left\\{ \\frac{a}{b} \\right\\}", [display: true], "⎧ a⎫\n⎨ ─⎬\n⎩ b⎭"},
    {"\\left[ \\begin{matrix} 1 & 2 \\\\ 3 & 4 \\\\ 5 & 6 \\end{matrix} \\right]",
     [display: true], "⎡1 │ 2⎤\n⎢3 │ 4⎥\n⎣5 │ 6⎦"},
    {"\\left\\langle \\frac{a}{b} \\right\\rangle", [display: true], "⟨ a⟩\n⟨ ─⟩\n⟨ b⟩"},
    {"\\left( x \\right)", [display: true], "(x)"},
    {"\\left(\\left( x \\right)\\right)", [display: true], "((x))"},
    {"\\left. \\frac{a}{b} \\right|_0^1", [display: true], "a│\n─│₀¹\nb│"},
    {"\\left(\\begin{pmatrix} 1 & 2 \\\\ 3 & 4 \\end{pmatrix}\\right)", [display: true],
     "⎛⎛ 1 │ 2 ⎞⎞\n⎝⎝ 3 │ 4 ⎠⎠"},
    {"\\big(x\\big)", [display: true], "⎛ ⎞\n⎝x⎠"},
    {"\\Big[ \\frac{a}{b} \\Big]", [display: true], "⎡ a ⎤\n⎣ ─ ⎦\n  b"},
    {"\\bigg\\{ x \\bigg\\}", [display: true], "⎧ ⎫\n⎨x⎬\n⎩ ⎭"},
    {"\\left( x", [display: true], "( x"}
  ]

  # {source, options, expected}: the three structural commands pi leaves as text. Their
  # inline rendering is pi's, checked against pi's own `renderLatex` under bun — a
  # brace, a stack and a rule all need rows, and inline math has one.
  @structure_cases [
    {"\\substack{a \\\\ b}", [], "a\nb"},
    {"\\sum_{\\substack{i=0 \\\\ j=0}}^n x", [], "∑_(i=0\nj=0)ⁿ x"},
    {"\\substack{a \\\\ b}", [display: true], "a\nb"},
    {"\\sum_{\\substack{i=0 \\\\ j=0}}^n x", [display: true], "  n\n  ∑   x\ni = 0\nj = 0"},
    {"\\overbrace{x+y}", [], "x+y"},
    {"\\overbrace{x+y}^{n}", [], "x+yⁿ"},
    {"\\underbrace{x+y}_{n}", [], "x+yₙ"},
    {"\\overbrace{x+y}", [display: true], "⏞⏞⏞\nx+y"},
    {"\\underbrace{x+y}", [display: true], "x+y\n⏟⏟⏟"},
    {"\\overbrace{x+y}^{n}", [display: true], " n\n⏞⏞⏞\nx+y"},
    {"\\overbrace{x+y}_{n}", [display: true], "⏞⏞⏞\n n\nx+y"},
    {"\\underbrace{x+y}_{n}", [display: true], "x+y\n⏟⏟⏟\n n"},
    {"\\underbrace{x+y}^{n}", [display: true], " n\nx+y\n⏟⏟⏟"},
    {"\\overbrace{\\frac{a}{b}}^{n}", [display: true], "n\n⏞⏞\n a\n ─\n b"},
    {"\\begin{array}{c} a \\\\ \\hline b \\end{array}", [display: true], "a\n─\nb"},
    {"\\begin{array}{cc} a & b \\\\ \\hline c & d \\end{array}", [display: true],
     "a │ b\n──┼──\nc │ d"},
    {"\\begin{pmatrix} 1 & 2 \\\\ \\hline 3 & 4 \\end{pmatrix}", [display: true],
     "⎛ 1 │ 2 ⎞\n⎜ ──┼── ⎟\n⎝ 3 │ 4 ⎠"},
    {"\\begin{array}{c} \\hline a \\\\ b \\hline \\end{array}", [display: true], "─\na\nb\n─"},
    {"\\begin{array}{c} a \\\\ b \\end{array}", [display: true], "a\nb"}
  ]

  # {text, expected}: measured with pi's own `visibleWidth` (packages/tui/src/utils.ts,
  # run under bun) over these exact strings. A divergence means the two disagree about
  # what a terminal shows, which is the only thing the width module claims to know.
  @width_cases [
    {"", 0},
    {" ", 1},
    {"abc", 3},
    {"\t", 3},
    {"a\tb", 5},
    {"中文", 4},
    {"한국어", 6},
    {"ｱ", 1},
    {"Ａ", 2},
    {"e\u0301", 1},
    {"a\u0301\u0327", 1},
    {"क्क", 2},
    {"क्ष", 2},
    {"\u0E01\u0E33", 2},
    {"\u0E01\u0E34", 1},
    {"👍", 2},
    {"👍🏽", 2},
    {"👨‍👩‍👧", 2},
    {"👨‍👩‍👧‍👦", 2},
    {"🏳️‍🌈", 2},
    {"🇺🇸", 2},
    {"🇯🇵", 2},
    {"1️⃣", 2},
    {"1⃣", 1},
    {"❤", 1},
    {"❤️", 2},
    {"☀", 1},
    {"☀️", 2},
    {"⏱", 1},
    {"🀄", 2},
    {"🀀", 1},
    {"🫡", 2},
    {"❤️‍🔥", 2},
    {"\u200B", 0},
    {"a\u200Bb", 2},
    {"\u200D", 0},
    {"\u0301", 0},
    {"\u00AD", 0},
    # The glyphs the renderer itself draws, and the private-use markers its layout pass
    # leaves in the text.
    {"─", 1},
    {"│", 1},
    {"√", 1},
    {"∫", 1},
    {"∑", 1},
    {"⎛", 1},
    {"⎝", 1},
    {"⎞", 1},
    {"⎠", 1},
    {"⟨", 1},
    {"⟩", 1},
    {"\u{F0000}", 1},
    {"\u{F0001}", 1},
    {"x\u{F0000}0\u{F0001}y", 5},
    # Mathematical script letters are one cell, which is why the renderer substitutes
    # only the letterlike ones for `\mathbb`.
    {"𝔄", 1},
    {"𝒜", 1},
    {"ℱ", 1},
    {"日本語 🀄 α", 11},
    {"mixed 中文 text", 15},
    {"ASCII é mix", 11}
  ]

  # {text, expected}: escape sequences take no cells. pi's own scan ends a CSI only on
  # `m/G/K/H/J`, so it counts the six characters of `ESC[?25l` as five cells, where the
  # standard final byte range this one ends on counts nothing — the one case in the
  # file where the number is deliberately not pi's.
  @escape_cases [
    {"\e[?25l", 0},
    {"\e[2J", 0},
    {"\e[31mred\e[0m", 3},
    {"\e[1;31mbold\e[0m", 4},
    {"\e[38;2;255;0;0mtruecolor\e[0m", 9},
    {"\e]0;title\a", 0},
    {"\e]8;;http://x\alink\e]8;;\a", 4},
    {"\e_something\a", 0},
    {"mixed 中文 \e[32m🀄\e[0m text", 18}
  ]

  # {grapheme, expected}: one cluster at a time, as pi's `graphemeWidth` measures them.
  @cluster_cases [
    {"\t", 3},
    {"中", 2},
    {"e\u0301", 1},
    {"👨‍👩‍👧", 2}
  ]

  # One test, so the catalogue reads in this order rather than whatever order ExUnit
  # shuffles tests into, and so its sections are not interleaved with another file's.
  test "every case the API was checked against" do
    check_renderings("alphabet", @alphabet_cases)
    check_renderings("delimiter", @delimiter_cases)
    check_renderings("structure", @structure_cases)
    check_widths("width", @width_cases, &Width.display/1, 24)
    check_widths("grapheme cluster", @cluster_cases, &Width.grapheme_width/1, 14)
    check_widths("escape sequences", @escape_cases, &Width.display/1, 40)
  end

  test "keeps the measurement cache in the calling process" do
    parent = self()

    pid =
      spawn(fn ->
        Width.display("日本語 🀄 α")
        send(parent, :measured)
        Process.sleep(:infinity)
      end)

    assert_receive :measured
    assert Enum.filter(:ets.all(), &(:ets.info(&1, :owner) == pid)) == []
    Process.exit(pid, :kill)
  end

  test "bounds the measurement cache" do
    for index <- 1..600, do: Width.display("line #{index} 中文")

    # The cache is the process's own, so this reads it out directly. pi bounds its cache
    # at 512 strings too, and the point is that a long session holds a fixed amount
    # rather than every string it has ever measured.
    {entries, _order} = Process.get({Width, :cache})
    assert map_size(entries) <= 512
  end

  defp check_widths(section, cases, measure, padding) do
    IO.puts("\n── #{section}: #{length(cases)} cases ──")

    for {text, expected} <- cases do
      measured = measure.(text)
      IO.puts("  #{String.pad_trailing(inspect(text), padding)} => #{measured}")

      assert measured == expected,
             "#{inspect(text)} measures #{measured}, expected #{expected}"
    end
  end

  defp check_renderings(section, cases) do
    IO.puts("\n── #{section}: #{length(cases)} cases ──")

    for {source, options, expected} <- cases do
      rendered = LatexUnicode.render(source, options)

      IO.puts("  #{label(source, options)}")
      IO.puts(indent(rendered))

      assert rendered == expected,
             "#{inspect(source)} #{inspect(options)} rendered #{inspect(rendered)}, " <>
               "expected #{inspect(expected)}"
    end
  end

  defp label(source, []), do: source
  defp label(source, options), do: "#{source}    (#{inspect(options)})"

  defp indent(nil), do: "      <nil>"

  defp indent(rendered) do
    rendered
    |> String.split("\n")
    |> Enum.map_join("\n", &("      " <> &1))
  end
end
