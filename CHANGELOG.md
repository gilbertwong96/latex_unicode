# Changelog

Notable changes to this project, newest first. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.1.0 — unreleased

First release. LaTeX math rendered as terminal-friendly Unicode text: inline math as one
line, display math as multi-line art, and a pass that puts either into markdown before a
parser reads it. Extracted from pie's transcript renderer and ported from pi-tui's
`latex.ts` and markdown tokenizers, so pi's rendering is reproduced character for
character rather than re-invented.

- `LatexUnicode.render/2` — the symbols, scripts, fractions, roots, binomials, accents,
  named operators, font switches and environments (`aligned`, `cases`, `matrix` and its
  delimited variants, `array`, `gather`, `split`, `alignedat`) that pi supports, and
  display layout that stacks fractions, operator limits, matrices and nested scripts.
  An expression outside the supported subset renders `nil` instead of raising, so the
  caller can fall back to the source text.
- Beyond pi's subset: `\left … \right` and the size commands (`\big` … `\Bigg`) grow
  their delimiters to what they wrap; `\mathcal`/`\mathscr` and `\mathfrak` take the
  letterlike letters, as `\mathbb` takes the blackboard ones — the rest of each alphabet
  is left as written, since a terminal font has nothing to draw it with; `\substack`
  stacks its rows, `\overbrace`/`\underbrace` draw their brace with the label on the
  side its script asks for, and `\hline` rules an array or matrix.
- `LatexUnicode.Width` measures what a terminal actually shows — East Asian wide and
  fullwidth characters, grapheme clusters, escape sequences — the way pi's
  `visibleWidth` does. Display layout is built on it.
- `LatexUnicode.Spans` renders the math spans in markdown (`$…$`, `\(…\)`, `$$…$$`,
  `\[…\]`) as a source pass that pairs with any line-based renderer: `extract/2` leaves
  placeholders behind, `substitute/2` puts the rendered math back into the rendered
  lines, and a span whose closing delimiter has not arrived yet keeps its source text so
  a streaming answer never flickers. Spans inside fenced code blocks are left alone.
  `Spans.render/2` does both halves in one call, for text a parser will read: display
  math is fenced there, because markdown keeps the art's indentation and its line breaks
  only inside a fenced block.
- `mix latex_unicode.render` writes the rendered copy of a markdown file beside it, for
  a project that hands its guide pages to ExDoc through `extras:`; `--check` fails when
  a committed copy no longer matches its source, and CI runs it.
- `examples/rendering.txt` — every formula the library renders, ready to `cat` in a
  terminal — and `examples/compare_with_pi.exs`, which renders and measures the same
  inputs with pi's own `renderLatex` and `visibleWidth`, so a divergence that is not
  listed as one fails the run.
