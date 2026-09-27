defmodule LatexUnicode.Spans do
  @moduledoc """
  pi's LaTeX markdown tokens as a source pass, mirroring pi-tui's
  `components/markdown.ts` tokenizers.

  pi registers a marked block tokenizer (`$$...$$` / `\\[...\\]` on their own
  line) and an inline tokenizer (`$...$`, `\\(...\\)`, plus inline `$$`/`\\[`),
  rendering each span with `renderLatex` and falling back to the span's source
  text when the renderer reports unsupported syntax. While a span is still
  streaming (pi's `pending` tokens) or when `renderLatex: false` disables the
  feature, the source text is kept as-is.

  pie pre-parses markdown with MDEx, so the spans are extracted first: each
  becomes a placeholder that survives parsing, and `substitute/2` puts the
  rendered math back into the rendered lines.

  Unlike pi, spans inside fenced code blocks are left alone: pi's inline rule
  only guards the `$` form against backticks, and code content is better kept
  verbatim.
  """

  alias LatexUnicode

  @placeholder_start "\u{F0010}"
  @placeholder_end "\u{F0011}"
  @placeholder_pattern ~r/\x{F0010}([0-9]+)\x{F0011}/u

  # pi's tokenizeBlockLatex patterns. The trailing whitespace is a lookahead so
  # the newline after the span stays in the source.
  @block_dollar ~r/^ {0,3}\$\$[ \t]*(?:\n)?([\s\S]*?)\$\$[ \t]*(?=\n|\z)/m
  @block_bracket ~r/^ {0,3}\\\[[ \t]*(?:\n)?([\s\S]*?)\\\][ \t]*(?=\n|\z)/m
  @fence ~r/^ {0,3}(`{3,}|~{3,})/

  @type spans :: %{String.t() => [String.t()]}

  @doc """
  Replace the math spans in `source` with placeholders.

  Options:

    * `:render_latex` — render math spans (default true, pi's
      `MarkdownOptions.renderLatex`); false keeps the span's source text
  """
  @spec extract(String.t(), keyword()) :: {String.t(), spans()}
  def extract(source, opts \\ []) do
    render? = Keyword.get(opts, :render_latex, true)

    {source, spans} = extract_blocks(source, fenced_ranges(source), render?, %{})
    {source, spans} = extract_inlines(source, render?, spans)

    {source, spans}
  end

  @doc """
  Render the math spans in `source` in place, for text that no markdown parser runs
  over in between.

  `extract/2` and `substitute/2` are two halves because a markdown parser has to see
  the source between them; when there is no parser — a plain text file, a log line, a
  help message, a doc string — this does both in one call and leaves the text's own
  line breaks alone, the last newline included.

      iex> LatexUnicode.Spans.render("the identity $e^{i\\\\pi} + 1 = 0$ holds")
      "the identity e^(iπ) + 1 = 0 holds"

  The options are `extract/2`'s: `render_latex: false` leaves every span as written.
  """
  @spec render(String.t(), keyword()) :: String.t()
  def render(source, opts \\ []) do
    {source, spans} = extract(source, opts)

    source
    |> String.split("\n", trim: false)
    |> substitute(spans)
    |> Enum.join("\n")
  end

  @doc "Replace the placeholders in rendered lines with their math."
  @spec substitute([String.t()], spans()) :: [String.t()]
  def substitute(lines, spans) when map_size(spans) == 0, do: lines

  def substitute(lines, spans) do
    Enum.flat_map(lines, fn line ->
      line |> String.split("\n") |> Enum.flat_map(&expand(&1, spans))
    end)
  end

  # --- fenced code blocks ---

  @doc false
  @spec fenced_ranges(String.t()) :: [{non_neg_integer(), non_neg_integer()}]
  def fenced_ranges(source) do
    {ranges, open, _offset} =
      source
      |> String.split("\n")
      |> Enum.reduce({[], nil, 0}, fn line, {ranges, open, offset} ->
        next_offset = offset + byte_size(line) + 1

        cond do
          open != nil and closing_fence?(line, elem(open, 0)) ->
            {[{elem(open, 1), next_offset} | ranges], nil, next_offset}

          open != nil ->
            {ranges, open, next_offset}

          true ->
            case Regex.run(@fence, line) do
              [_, marker] -> {ranges, {marker, offset}, next_offset}
              _ -> {ranges, nil, next_offset}
            end
        end
      end)

    ranges =
      case open do
        nil -> ranges
        {_marker, start} -> [{start, byte_size(source)} | ranges]
      end

    Enum.reverse(ranges)
  end

  defp closing_fence?(line, marker) do
    Regex.match?(~r/^ {0,3}#{Regex.escape(marker)} {0,}$/, line)
  end

  defp fenced?(fenced, position) do
    Enum.any?(fenced, fn {from, to} -> position >= from and position < to end)
  end

  # --- block spans ---

  defp extract_blocks(source, fenced, render?, spans) do
    matches = block_matches(source, fenced)
    matches = Enum.sort_by(matches, &elem(&1, 0))

    {segments, spans, last_end} =
      Enum.reduce(matches, {[], spans, 0}, fn {start, length, text_start, text_length},
                                              {segments, spans, last_end} ->
        text = String.trim(binary_part(source, text_start, text_length))
        raw = String.trim(binary_part(source, start, length))

        replacement =
          if render? do
            case LatexUnicode.render(text, display: true) do
              nil -> raw
              rendered -> rendered
            end
          else
            raw
          end

        {placeholder, spans} = put_span(spans, replacement)
        prefix = binary_part(source, last_end, start - last_end)
        {[placeholder, prefix | segments], spans, start + length}
      end)

    tail = binary_part(source, last_end, byte_size(source) - last_end)
    {IO.iodata_to_binary([Enum.reverse(segments), tail]), spans}
  end

  # pi's block tokenizers match a `$$` or `\[` delimiter at the start of a
  # line; fenced code blocks are skipped.
  defp block_matches(source, fenced) do
    [@block_dollar, @block_bracket]
    |> Enum.flat_map(fn pattern ->
      pattern
      |> Regex.scan(source, return: :index)
      |> Enum.map(fn [{start, length}, {text_start, text_length}] ->
        {start, length, text_start, text_length}
      end)
    end)
    |> Enum.reject(fn {start, _length, _text_start, _text_length} -> fenced?(fenced, start) end)
  end

  # --- inline spans ---

  # The fence state is carried line by line rather than looked up by offset: every line
  # the pass replaces a span on changes length — a placeholder is not the size of the
  # span it stands for — so offsets measured before the pass cannot be trusted during it.
  defp extract_inlines(source, render?, spans) do
    {lines, {spans, _open}} =
      source
      |> String.split("\n")
      |> Enum.map_reduce({spans, nil}, fn line, {spans, open} ->
        cond do
          open != nil and closing_fence?(line, open) ->
            {line, {spans, nil}}

          open != nil ->
            {line, {spans, open}}

          match = Regex.run(@fence, line) ->
            [_fence, marker] = match
            {line, {spans, marker}}

          true ->
            {line, spans} = scan_inline(line, 0, render?, spans)
            {line, {spans, open}}
        end
      end)

    {Enum.join(lines, "\n"), spans}
  end

  defp scan_inline(line, from, render?, spans) do
    case next_inline_start(line, from) do
      nil ->
        {line, spans}

      index ->
        rest = binary_part(line, index, byte_size(line) - index)

        case tokenize_inline(rest) do
          :none ->
            scan_inline(line, index + 1, render?, spans)

          {:ok, raw, text} ->
            replace_span(line, index, raw, text, render?, spans)

          # A span whose closing delimiter has not arrived keeps its source, which is
          # what pi does with a pending token and what stops a streaming answer from
          # flickering between source and math.
          {:pending, raw, text} ->
            replace_span(line, index, raw, text, false, spans)
        end
    end
  end

  defp replace_span(line, index, raw, text, render?, spans) do
    replacement =
      if render? do
        case LatexUnicode.render(text) do
          nil -> raw
          rendered -> rendered
        end
      else
        raw
      end

    {placeholder, spans} = put_span(spans, replacement)

    line =
      binary_part(line, 0, index) <>
        placeholder <>
        binary_part(line, index + byte_size(raw), byte_size(line) - index - byte_size(raw))

    scan_inline(line, index + byte_size(placeholder), render?, spans)
  end

  defp next_inline_start(line, from) do
    [index_of(line, "$", from), index_of(line, "\\(", from), index_of(line, "\\[", from)]
    |> Enum.reject(&(&1 == nil))
    |> Enum.min(fn -> nil end)
  end

  # The search starts at `from` rather than at the beginning of the line: a `$` that was
  # rejected as not math (`$5`, say) is behind us, and a span after it is still math.
  defp index_of(line, needle, from) do
    case :binary.match(line, needle, scope: {from, byte_size(line) - from}) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end

  # pi's tokenizeInlineLatex: the raw span and its math source, or :none when
  # the delimiter run is not math (and stays text). A span whose closing
  # delimiter has not arrived yet keeps its source text, like pi's pending
  # tokens.
  defp tokenize_inline(source) do
    cond do
      String.starts_with?(source, "$$") ->
        inline_span(source, "$$", "$$")

      String.starts_with?(source, "\\(") ->
        inline_span(source, "\\(", "\\)")

      String.starts_with?(source, "\\[") ->
        inline_span(source, "\\[", "\\]")

      String.starts_with?(source, "$") and not Regex.match?(~r/^\$\s/, source) ->
        inline_span(source, "$", "$")

      true ->
        :none
    end
  end

  defp inline_span(source, opening, closing) do
    closing_index = find_closing(source, closing, byte_size(opening))

    cond do
      closing_index >= 0 and opening == "$" and dollar_math_rejected?(source, closing_index) ->
        :none

      closing_index < 0 ->
        inner = binary_part(source, byte_size(opening), byte_size(source) - byte_size(opening))

        if String.starts_with?(opening, "\\") or looks_like_pending_dollar_math?(inner) do
          {:pending, source, inner}
        else
          :none
        end

      true ->
        text = binary_part(source, byte_size(opening), closing_index - byte_size(opening))

        if text == "" or String.contains?(text, "\n") do
          :none
        else
          {:ok, binary_part(source, 0, closing_index + byte_size(closing)), text}
        end
    end
  end

  # pi rejects `$...$` when the content ends with whitespace, the next
  # character is a digit, the span looks like an identifier followed by one, or
  # the content contains a backtick (an inline code span).
  defp dollar_math_rejected?(source, closing_index) do
    inner = binary_part(source, 1, closing_index - 1)
    after_closing = binary_part(source, closing_index + 1, byte_size(source) - closing_index - 1)

    Regex.match?(~r/\s$/, inner) or
      Regex.match?(~r/^\d/, after_closing) or
      (Regex.match?(~r/^[A-Z_][A-Z0-9_]*(?:[^A-Za-z0-9_\s])?$/, inner) and
         Regex.match?(~r/^[A-Za-z_][A-Za-z0-9_]*/, after_closing)) or
      String.contains?(inner, "`")
  end

  defp find_closing(source, closing, start) do
    case :binary.match(source, closing, scope: {start, byte_size(source) - start}) do
      {index, _length} ->
        if escaped?(source, index) do
          find_closing(source, closing, index + byte_size(closing))
        else
          index
        end

      :nomatch ->
        -1
    end
  end

  defp escaped?(source, index) do
    source
    |> binary_part(0, index)
    |> String.reverse()
    |> backslash_count(0)
    |> rem(2) == 1
  end

  defp backslash_count(<<"\\", rest::binary>>, count), do: backslash_count(rest, count + 1)
  defp backslash_count(_rest, count), do: count

  defp looks_like_pending_dollar_math?(source) do
    Regex.match?(~r/\\[A-Za-z]+|[_^=+*\/<>()\[\]|±≤≥≠≈∈→⇒∞∫∑√-]/u, source)
  end

  # --- placeholders ---

  defp put_span(spans, replacement) do
    placeholder = @placeholder_start <> Integer.to_string(map_size(spans)) <> @placeholder_end
    {placeholder, Map.put(spans, placeholder, String.split(replacement, "\n"))}
  end

  defp expand(text, spans) do
    case Regex.run(@placeholder_pattern, text, return: :index) do
      nil ->
        [text]

      [{start, length}, {group_start, group_length}] ->
        index = text |> binary_part(group_start, group_length) |> String.to_integer()
        placeholder = @placeholder_start <> Integer.to_string(index) <> @placeholder_end

        prefix = binary_part(text, 0, start)
        suffix = binary_part(text, start + length, byte_size(text) - start - length)

        case Map.get(spans, placeholder) do
          nil ->
            [text]

          math_lines ->
            combine(prefix, math_lines, expand(suffix, spans))
        end
    end
  end

  # The math may be several lines (display layout, matrices): the prefix rides
  # the first line and the rest of the rendered text follows the last one.
  defp combine(prefix, math_lines, suffix_lines) do
    [first | middle] = math_lines
    [suffix_head | suffix_tail] = suffix_lines

    case middle do
      [] ->
        [prefix <> first <> suffix_head | suffix_tail]

      middle ->
        [prefix <> first | middle]
        |> List.update_at(-1, &(&1 <> suffix_head))
        |> Kernel.++(suffix_tail)
    end
  end
end
