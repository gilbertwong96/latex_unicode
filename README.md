# LatexUnicode

Render LaTeX math as Unicode text — for terminals, code comments, log output, and
anywhere rich formatting is not available. Pure Elixir, no dependencies, no TeX
installation, no image backend.

```elixir
LatexUnicode.render("\\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}")
#=> nil (inline form is used unless you ask for display layout)

LatexUnicode.render("\\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}", display: true)
#=> "-b ± √(b² - 4ac)\n────────────────\n       2a"

LatexUnicode.render("\\sum_{i=0}^n x_i")
#=> "∑ᵢ₌₀ⁿ xᵢ"

LatexUnicode.render("x + \\unknown{y}")
#=> nil      # unsupported or malformed: the caller falls back to the source
```

`render/2` returns `nil` instead of raising when an expression uses syntax outside
the supported subset, so a renderer can fall back to the raw source text (that is
what the terminal UI this was extracted from does).

## Markdown integration

Math spans in markdown can be expanded before the markdown parser runs, then put
back into the rendered lines. The pass is parser-agnostic: it works on source text
and a list of rendered lines, so it pairs with any line-based renderer (MDEx,
Earmark, plain text, a custom TUI).

```elixir
alias LatexUnicode.Spans

{source, spans} = Spans.extract("the value $x^2$ and\n\n$$\\frac{1}{2}$$")
# pass `source` to your markdown parser, render it to lines, then:
lines = source |> String.split("\n") |> Spans.substitute(spans)
#=> ["the value x² and", "", "1", "─", "2"]
```

- Inline: `$...$`, `\(...\)`, `\[...\]`
- Display (own block): `$$...$$`, `\[...\]` at the start of a line
- `render_latex: false` turns the pass off
- a span whose closing delimiter has not arrived yet keeps its source text, so a
  streaming response never flickers
- math inside fenced code blocks is left alone

## What it renders

Symbols (Greek, relations, arrows, big operators, delimiters, dots), scripts
(`x^2`, `x_{i_j}`, `\sum_{i=0}^n` with display limits), fractions, roots,
binomials, `\text`/`\mathbf`/`\mathbb`/font switches, accents and wide decorations,
`\boxed`, `\operatorname`, `\overset`/`\underset`, environments (`aligned`,
`alignedat`, `gather`, `split`, `cases`, `array`, `matrix`, `pmatrix`, `bmatrix`,
`Bmatrix`, `vmatrix`, `Vmatrix`), spacing commands, and display-mode layout that
stacks fractions, operator limits, stacked scripts, and matrices into multi-line
art.

Unsupported commands, malformed groups, and unbalanced environments return `nil`.

## Install

```elixir
def deps do
  [{:latex_unicode, "~> 0.1"}]
end
```

## Attribution

This library is a port of pi-tui's LaTeX renderer and markdown tokenizers
(`packages/tui/src/latex.ts` and `components/markdown.ts` in
[pi](https://github.com/earendil-works/pi)) by Mario Zechner, copyright 2025, MIT licensed. The
symbol and command tables are generated from that source, and the test suite is a
port of its tests, so behaviour matches the reference implementation rather than
re-inventing it. The display-width math comes from the same project's
`visibleWidth`.

## License

MIT — see [LICENSE](LICENSE).
