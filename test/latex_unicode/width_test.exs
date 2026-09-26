defmodule LatexUnicode.WidthTest do
  use ExUnit.Case, async: true

  alias LatexUnicode.Width

  # Measured with pi's own `visibleWidth` (packages/tui/src/utils.ts, run under
  # bun) over these exact strings: a divergence here means the two disagree about
  # what a terminal shows, which is the only thing this module claims to know.
  @pi_widths [
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
    # The glyphs the renderer itself draws, and the private-use markers its layout
    # pass leaves in the text.
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
    # Mathematical script letters are one cell, which is why the renderer only
    # substitutes the letterlike ones for `\mathbb`.
    {"𝔄", 1},
    {"𝒜", 1},
    {"ℱ", 1},
    {"日本語 🀄 α", 11},
    {"mixed 中文 text", 15},
    {"ASCII é mix", 11}
  ]

  test "measures what pi measures" do
    for {text, width} <- @pi_widths do
      measured = Width.display(text)

      assert measured == width,
             "#{inspect(text)} measures #{measured} here, pi measures #{width}"
    end
  end

  test "strips escape sequences before measuring" do
    # pi's own scan ends a CSI only on `m/G/K/H/J`, so it counts the six
    # characters of `ESC[?25l` as five cells. The standard final byte range is what
    # this one ends on, so hiding a cursor costs nothing here.
    assert Width.display("\e[?25l") == 0
    assert Width.display("\e[2J") == 0
    assert Width.display("\e[31mred\e[0m") == 3
    assert Width.display("\e[1;31mbold\e[0m") == 4
    assert Width.display("\e[38;2;255;0;0mtruecolor\e[0m") == 9
    assert Width.display("\e]0;title\a") == 0
    assert Width.display("\e]8;;http://x\alink\e]8;;\a") == 4
    assert Width.display("\e_something\a") == 0
    assert Width.display("mixed 中文 \e[32m🀄\e[0m text") == 18
  end

  test "measures one grapheme cluster" do
    assert Width.grapheme_width("\t") == 3
    assert Width.grapheme_width("中") == 2
    assert Width.grapheme_width("e\u0301") == 1
    assert Width.grapheme_width("👨‍👩‍👧") == 2
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

    # The cache is the process's own, so this reads it out directly. pi bounds its
    # cache at 512 strings too, and the point is that a long session holds a fixed
    # amount rather than every string it has ever measured.
    {entries, _order} = Process.get({Width, :cache})
    assert map_size(entries) <= 512
  end
end
