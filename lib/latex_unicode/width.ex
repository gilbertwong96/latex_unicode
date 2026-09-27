defmodule LatexUnicode.Width do
  @moduledoc """
  Terminal display width of rendered math text.

  Math output is plain text, so this is pi-tui's `visibleWidth`/`graphemeWidth`
  math: East Asian wide and fullwidth codepoints, emoji clusters and flags take
  two cells, zero-width clusters none, everything else one.

  A host measures its own lines with this as well as the renderer's, so two
  things go past pi's version. Escape sequences take no cells and are stripped
  before measuring, and the cache of measured strings lives in the calling
  process rather than in a table every process in the VM can see.
  """

  alias LatexUnicode.Width.EastAsianWidth

  # pi bounds its width cache at 512 strings and drops the oldest; the same bound
  # keeps a long session's measurements from growing without limit.
  @cache_size 512
  @cache_key {__MODULE__, :cache}

  # Mark categories, per codepoint. pi spells these as Unicode property regexes, and
  # `re` answers for the general categories on every release this library supports.
  @mark ~r/^[\p{Mn}\p{Mc}\p{Me}]$/u
  @spacing_mark ~r/^[\p{Mc}]$/u

  # pi's `zeroWidthRegex` and `nonPrintingRegex` differ only in whether they name
  # `\p{Cf}`: the derived `Default_Ignorable_Code_Point` both of them carry already
  # contains the format characters, so the two sets are one set — measured, they agree
  # on every codepoint — and it is written once here.
  #
  # The derived property itself is spelled out as ranges rather than named: Erlang/OTP
  # 27's PCRE rejects the name, which CI caught as `unknown property name after \P or
  # \p`, and the same numbers should come out of every release. The ranges are what
  # `PropList.txt` calls `Other_Default_Ignorable_Code_Point`, which is all the derived
  # property adds to the categories below it — 3773 of the set's 6477 codepoints.
  @non_printing ~r/^[\x{034F}\x{115F}-\x{1160}\x{17B4}-\x{17B5}\x{2065}\x{3164}\x{FFA0}\x{FFF0}-\x{FFF8}\x{E0000}\x{E0002}-\x{E001F}\x{E0080}-\x{E00FF}\x{E01F0}-\x{E0FFF}\p{Cc}\p{Cf}\p{Cs}\p{Mn}\p{Mc}\p{Me}]$/u
  @emoji_presentation ~r/^[\p{Emoji_Presentation}]$/u
  @extended_pictographic ~r/^[\p{Extended_Pictographic}]$/u

  # pi's `terminalSpacingMarkRegex`: spacing marks take a cell of their own, less
  # the three that do not, plus the non-spacing exceptions legacy wcwidth tables
  # give a cell to.
  @spacing_mark_exceptions [0x1734, 0x302E, 0x302F]
  @legacy_spacing_marks [
    0x065F,
    0x0F7F,
    0x102B,
    0x102C,
    0x1031,
    0x1033,
    0x1034,
    0x1035,
    0x1038,
    0x103A,
    0x103B,
    0x103C,
    0x103D,
    0x103E
  ]

  @doc """
  Display width of `text` in terminal cells.

  ANSI, OSC and APC escape sequences are stripped first, and a tab counts as
  three cells, the way pi measures a line it is about to render.
  """
  @spec display(String.t()) :: non_neg_integer()
  def display(""), do: 0

  def display(text) do
    if printable_ascii?(text) do
      byte_size(text)
    else
      case cached(text) do
        nil ->
          width = text |> without_escapes() |> measure()
          cache(text, width)
          width

        width ->
          width
      end
    end
  end

  @doc "Terminal display width of one grapheme cluster (pi's graphemeWidth)."
  @spec grapheme_width(String.t()) :: non_neg_integer()
  def grapheme_width("\t"), do: 3

  def grapheme_width(grapheme) do
    case :unicode.characters_to_list(grapheme) do
      codepoints when is_list(codepoints) -> cluster_width(codepoints)
      _not_unicode -> 1
    end
  end

  defp measure(text) do
    text
    |> String.graphemes()
    |> Enum.reduce(0, fn grapheme, acc -> acc + grapheme_width(grapheme) end)
  end

  # Nothing to segment, strip or look up: pi's `isPrintableAscii` fast path, which
  # is what most of a rendered line is.
  defp printable_ascii?(<<byte, rest::binary>>) when byte in 0x20..0x7E,
    do: printable_ascii?(rest)

  defp printable_ascii?(<<>>), do: true
  defp printable_ascii?(_other), do: false

  # pi's order: marks a terminal gives cells to even with no base under them,
  # then clusters that take no cells at all, then everything that is visible.
  defp cluster_width(codepoints) do
    cond do
      Enum.all?(codepoints, &spacing_mark?/1) ->
        length(codepoints)

      Enum.all?(codepoints, &non_printing?/1) ->
        0

      true ->
        visible_width(codepoints)
    end
  end

  defp visible_width(codepoints) do
    case Enum.drop_while(codepoints, &non_printing?/1) do
      [] ->
        0

      [base | rest] ->
        if emoji?(base, codepoints) do
          2
        else
          region_width(base) + trailing_width(rest, false)
        end
    end
  end

  # A flag's regional indicator is two cells wide, and the East Asian Width table
  # answers for everything else.
  defp region_width(codepoint) do
    if codepoint in 0x1F1E6..0x1F1FF do
      2
    else
      EastAsianWidth.columns(codepoint)
    end
  end

  # Codepoints after the base can each take a cell of their own: a spacing mark
  # always does, and a consonant or vowel that follows a mark (Devanagari, Thai,
  # Lao) is visible by itself. pi walks the same cases.
  defp trailing_width([], _follows_mark), do: 0

  defp trailing_width([codepoint | rest], follows_mark) do
    cond do
      spacing_mark?(codepoint) ->
        1 + trailing_width(rest, false)

      mark?(codepoint) ->
        trailing_width(rest, true)

      non_printing?(codepoint) ->
        trailing_width(rest, follows_mark)

      follows_mark or codepoint in 0xFF00..0xFFEF ->
        EastAsianWidth.columns(codepoint) + trailing_width(rest, false)

      codepoint in [0x0E33, 0x0EB3] ->
        1 + trailing_width(rest, false)

      true ->
        trailing_width(rest, false)
    end
  end

  # pi asks `\p{RGI_Emoji}` of the whole cluster, which Erlang's `re` does not
  # have. The codepoint properties it does have answer the same for every cluster
  # the terminal shows as an emoji: a codepoint that presents as one by default, a
  # flag, or a pictograph with a variation selector forcing emoji presentation —
  # which is also what makes a keycap an emoji, since `1` is not one on its own.
  defp emoji?(base, codepoints) do
    cond do
      emoji_presentation?(base) -> true
      base in 0x1F1E6..0x1F1FF -> true
      0xFE0F in codepoints -> extended_pictographic?(base) or 0x20E3 in codepoints
      true -> false
    end
  end

  defp spacing_mark?(codepoint) do
    codepoint in @legacy_spacing_marks or
      (codepoint not in @spacing_mark_exceptions and matches?(@spacing_mark, codepoint))
  end

  defp mark?(codepoint), do: matches?(@mark, codepoint)
  defp non_printing?(codepoint), do: matches?(@non_printing, codepoint)
  defp emoji_presentation?(codepoint), do: matches?(@emoji_presentation, codepoint)
  defp extended_pictographic?(codepoint), do: matches?(@extended_pictographic, codepoint)

  defp matches?(regex, codepoint), do: Regex.match?(regex, <<codepoint::utf8>>)

  defp without_escapes(text) do
    if :binary.match(text, <<0x1B>>) == :nomatch, do: text, else: strip_escapes(text)
  end

  # CSI (`ESC [ …` styling and cursor codes), OSC (`ESC ] …` hyperlinks and prompt
  # markers) and APC (`ESC _ …`), each ending where the terminal says it does. pi's
  # own scan ends a CSI only on `m/G/K/H/J`, so it counts `ESC[?25l` as five cells;
  # the standard final byte range is what the cursor can be trusted to be hidden
  # with.
  defp strip_escapes(text), do: strip_escapes(text, [])

  defp strip_escapes(<<0x1B, "[", rest::binary>>, acc), do: strip_escapes(skip_csi(rest), acc)

  defp strip_escapes(<<0x1B, "]", rest::binary>>, acc),
    do: strip_escapes(skip_terminated(rest), acc)

  defp strip_escapes(<<0x1B, "_", rest::binary>>, acc),
    do: strip_escapes(skip_terminated(rest), acc)

  defp strip_escapes(<<codepoint::utf8, rest::binary>>, acc) do
    strip_escapes(rest, [<<codepoint::utf8>> | acc])
  end

  defp strip_escapes(<<byte, rest::binary>>, acc), do: strip_escapes(rest, [byte | acc])
  defp strip_escapes(<<>>, acc), do: acc |> Enum.reverse() |> IO.iodata_to_binary()

  defp skip_csi(<<byte, rest::binary>>) when byte in 0x40..0x7E, do: rest
  defp skip_csi(<<_byte, rest::binary>>), do: skip_csi(rest)
  defp skip_csi(<<>>), do: <<>>

  defp skip_terminated(<<0x07, rest::binary>>), do: rest
  defp skip_terminated(<<0x1B, "\\", rest::binary>>), do: rest
  defp skip_terminated(<<_byte, rest::binary>>), do: skip_terminated(rest)
  defp skip_terminated(<<>>), do: <<>>

  # A host redraws the same lines every frame, so the strings it measures are
  # mostly ones this process has measured before (pi keeps the same cache in a
  # module-level map, which in the BEAM would be a table shared by every process).
  defp cached(text) do
    case Process.get(@cache_key) do
      nil -> nil
      {entries, _order} -> Map.get(entries, text)
    end
  end

  defp cache(text, width) do
    {entries, order} =
      case Process.get(@cache_key) do
        nil -> {%{}, :queue.new()}
        {entries, order} -> {entries, order}
      end

    {entries, order} =
      if map_size(entries) < @cache_size do
        {entries, order}
      else
        case :queue.out(order) do
          {{:value, oldest}, rest} -> {Map.delete(entries, oldest), rest}
          {:empty, rest} -> {entries, rest}
        end
      end

    Process.put(@cache_key, {Map.put(entries, text, width), :queue.in(text, order)})
    width
  end
end
