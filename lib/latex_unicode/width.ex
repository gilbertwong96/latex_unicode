defmodule LatexUnicode.Width do
  @moduledoc """
  Terminal display width of rendered math text.

  Math output is plain text, so this is pi-tui's `visibleWidth`/`graphemeWidth`
  math without the ANSI handling pie's transcript needs: East Asian
  wide/fullwidth and emoji clusters count two cells, zero-width clusters none,
  everything else one.
  """

  @doc "Display width of plain text in terminal cells."
  @spec display(String.t()) :: non_neg_integer()
  def display(text) do
    text
    |> String.graphemes()
    |> Enum.reduce(0, fn grapheme, acc -> acc + grapheme_width(grapheme) end)
  end

  @doc "Terminal display width of one grapheme cluster (pi's graphemeWidth)."
  @spec grapheme_width(String.t()) :: non_neg_integer()
  def grapheme_width("\t"), do: 3

  # The full computation walks several codepoint range tables; the width
  # cache keeps per-frame transcript redraws cheap (pi's widthCache).
  @width_cache :pie_grapheme_width_cache

  def grapheme_width(g) do
    case cached_width(g) do
      nil ->
        w = compute_grapheme_width(g)
        _ = ensure_width_cache()
        :ets.insert(@width_cache, {g, w})
        w

      w ->
        w
    end
  end

  # The table lives in whichever process created it first; when that owner
  # exits the table disappears, so every read tolerates its absence.
  defp cached_width(g) do
    if :ets.whereis(@width_cache) == :undefined do
      nil
    else
      case :ets.lookup(@width_cache, g) do
        [{^g, w}] -> w
        [] -> nil
      end
    end
  rescue
    ArgumentError -> nil
  end

  defp ensure_width_cache do
    if :ets.whereis(@width_cache) == :undefined do
      :ets.new(@width_cache, [:named_table, :public, :set, read_concurrency: true])
    end
  rescue
    ArgumentError -> :ok
  end

  defp compute_grapheme_width(g) do
    case :unicode.characters_to_list(g) do
      [] ->
        0

      cps ->
        cond do
          Enum.all?(cps, &zero_width_codepoint?/1) -> 0
          emoji_presentation?(cps) -> 2
          wide?(hd(cps)) -> 2
          true -> 1
        end
    end
  end

  # Regional indicators (flags) and the SMP emoji/symbol planes render 2
  # cells; a VS16 suffix forces emoji presentation for BMP symbols that
  # default to text presentation (❤️ ❗ ☀️ …).
  defp emoji_presentation?([cp | rest]) do
    cond do
      cp in 0x1F1E6..0x1F1FF -> true
      cp in 0x1F000..0x1FAFF -> true
      0xFE0F in rest and cp in 0x2000..0x2BFF -> true
      0xFE0F in rest and cp in [0x00A9, 0x00AE] -> true
      true -> false
    end
  end

  defp emoji_presentation?(_), do: false

  # Zero-width codepoints: variation selectors, joiners, combining marks,
  # bidi/format controls (pragmatic subset of the UCD Mark/Format tables).
  @zero_width_ranges [
    {0x0300, 0x036F},
    {0x0483, 0x0489},
    {0x0591, 0x05BD},
    {0x05BF, 0x05BF},
    {0x05C1, 0x05C2},
    {0x05C4, 0x05C5},
    {0x05C7, 0x05C7},
    {0x0610, 0x061A},
    {0x064B, 0x065F},
    {0x0670, 0x0670},
    {0x06D6, 0x06DC},
    {0x06DF, 0x06E4},
    {0x06E7, 0x06E8},
    {0x06EA, 0x06ED},
    {0x0711, 0x0711},
    {0x0730, 0x074A},
    {0x07A6, 0x07B0},
    {0x07EB, 0x07F3},
    {0x0816, 0x0819},
    {0x081B, 0x0823},
    {0x0825, 0x0827},
    {0x0829, 0x082D},
    {0x093C, 0x093C},
    {0x0941, 0x0948},
    {0x094D, 0x094D},
    {0x0951, 0x0957},
    {0x0962, 0x0963},
    {0x0E31, 0x0E31},
    {0x0E34, 0x0E3A},
    {0x0E47, 0x0E4E},
    {0x200B, 0x200F},
    {0x202A, 0x202E},
    {0x2060, 0x2064},
    {0x2066, 0x206F},
    {0x20D0, 0x20F0},
    {0xFE00, 0xFE0F},
    {0xFEFF, 0xFEFF},
    {0xFFF9, 0xFFFB},
    {0xE0100, 0xE01EF}
  ]

  defp zero_width_codepoint?(cp) do
    Enum.any?(@zero_width_ranges, fn {lo, hi} -> cp in lo..hi end)
  end

  # East Asian Wide and Fullwidth codepoints (UAX #11), including the
  # BMP codepoints terminals render wide by default (emoji with emoji
  # presentation); everything else that is not zero-width or emoji
  # presentation renders 1 column.
  @wide_ranges [
    {0x1100, 0x115F},
    {0x231A, 0x231B},
    {0x2329, 0x232A},
    {0x23E9, 0x23EC},
    {0x23F0, 0x23F1},
    {0x23F3, 0x23F3},
    {0x25FD, 0x25FE},
    {0x2614, 0x2615},
    {0x2648, 0x2653},
    {0x267F, 0x267F},
    {0x2693, 0x2693},
    {0x26A1, 0x26A1},
    {0x26AA, 0x26AB},
    {0x26BD, 0x26BE},
    {0x26C4, 0x26C5},
    {0x26CE, 0x26CE},
    {0x26D4, 0x26D4},
    {0x26EA, 0x26EA},
    {0x26F2, 0x26F3},
    {0x26F5, 0x26F5},
    {0x26FA, 0x26FA},
    {0x26FD, 0x26FD},
    {0x2705, 0x2705},
    {0x270A, 0x270B},
    {0x2728, 0x2728},
    {0x274C, 0x274C},
    {0x274E, 0x274E},
    {0x2753, 0x2755},
    {0x2757, 0x2757},
    {0x2795, 0x2797},
    {0x27B0, 0x27B0},
    {0x27BF, 0x27BF},
    {0x2B1B, 0x2B1C},
    {0x2B50, 0x2B50},
    {0x2B55, 0x2B55},
    {0x2E80, 0x303E},
    {0x3041, 0x33FF},
    {0x3400, 0x4DBF},
    {0x4E00, 0x9FFF},
    {0xA000, 0xA4CF},
    {0xA960, 0xA97C},
    {0xAC00, 0xD7A3},
    {0xF900, 0xFAFF},
    {0xFE10, 0xFE19},
    {0xFE30, 0xFE52},
    {0xFE54, 0xFE66},
    {0xFE68, 0xFE6B},
    {0xFF00, 0xFF60},
    {0xFFE0, 0xFFE6},
    {0x16FE0, 0x16FE4},
    {0x16FF0, 0x16FF1},
    {0x17000, 0x187F7},
    {0x18800, 0x18CD5},
    {0x18D00, 0x18D08},
    {0x1AFF0, 0x1B16F},
    {0x1F004, 0x1F004},
    {0x1F0CF, 0x1F0CF},
    {0x1F18E, 0x1F18E},
    {0x1F191, 0x1F19A},
    {0x1F200, 0x1F2FF},
    {0x20000, 0x2FFFD},
    {0x30000, 0x3FFFD}
  ]

  @doc "Whether a codepoint renders double-width (East Asian wide/fullwidth, emoji)."
  @spec wide?(non_neg_integer()) :: boolean()
  def wide?(cp) when is_integer(cp) do
    Enum.any?(@wide_ranges, fn {lo, hi} -> cp in lo..hi end)
  end
end
