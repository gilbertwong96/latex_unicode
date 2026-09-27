# LatexUnicode

[![CI](https://github.com/gilbertwong96/latex_unicode/actions/workflows/ci.yml/badge.svg)](https://github.com/gilbertwong96/latex_unicode/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/gilbertwong96/latex_unicode/graph/badge.svg)](https://codecov.io/gh/gilbertwong96/latex_unicode)
[![Hex.pm](https://img.shields.io/hexpm/v/latex_unicode.svg)](https://hex.pm/packages/latex_unicode)
[![Hexdocs](https://img.shields.io/badge/hexdocs-docs-blue.svg)](https://hexdocs.pm/latex_unicode)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Render LaTeX math as Unicode text — for terminals, code comments, log output, and
anywhere rich formatting is not available. Pure Elixir, no dependencies, no TeX
installation, no image backend.

```elixir
LatexUnicode.render("\\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}")
#=> "(-b ± √(b² - 4ac))/(2a)"

LatexUnicode.render("\\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}", display: true)
#=> "-b ± √(b² - 4ac)\n────────────────\n       2a"

LatexUnicode.render("\\sum_{i=0}^n x_i", display: true)
#=> " n\n ∑  xᵢ\ni=0"

LatexUnicode.render("\\begin{pmatrix}1&200\\\\3000&4\\end{pmatrix}")
#=> "⎛ 1    │ 200 ⎞\n⎝ 3000 │ 4   ⎠"

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

For markdown something else will read — a `@doc` string, a guide page — the math can be
rendered into the text itself, with nothing to keep in step:

```elixir
@doc LatexUnicode.Spans.render("""
The identity $e^{i\\pi} + 1 = 0$ holds in the complex plane.
""")
```

Display math arrives in a fenced block labelled `text`, because markdown keeps the art's
indentation and its line breaks only inside one; `fence: false` is the way back for text
no parser runs over, such as a log line. A guide page is a file rather than an
expression, so `mix latex_unicode.render` writes the rendered copy beside it and
`--check` fails when the two drift apart. This repository's own page is
[Math in docs](guides/math-in-docs.rendered.md).

## What it renders

Symbols (Greek, relations, arrows, big operators, delimiters, dots), scripts
(`x^2`, `x_{i_j}`, `\sum_{i=0}^n` with display limits), fractions, roots,
binomials, `\text`/`\mathbf`/`\mathbb`/font switches, accents and wide decorations,
`\boxed`, `\operatorname`, `\overset`/`\underset`, environments (`aligned`,
`alignedat`, `gather`, `split`, `cases`, `array`, `matrix`, `pmatrix`, `bmatrix`,
`Bmatrix`, `vmatrix`, `Vmatrix`), spacing commands, and display-mode layout that
stacks fractions, operator limits, nested scripts, and matrices into multi-line
art.

Beyond pi's subset: `\left … \right` and the size commands (`\big` … `\Bigg`) grow
their delimiters to the body, `\mathcal`/`\mathfrak`/`\mathscr` take the letterlike
letters (`\mathbb` takes the blackboard ones, as in pi), `\substack` stacks,
`\overbrace`/`\underbrace` draw their brace with the label on the side its script
asks for, and `\hline` rules an array or matrix.

Inline math is pi's rendering character for character — `a/b` for a fraction, `x²`
for a script, `e^(x₁)` where Unicode has no script form — and display math is the
multi-line art. `e^{-x}` is `e⁻ˣ` either way; `e^{-x^2}` is three lines as display
math, because a script inside a script has no Unicode form to nest in.

`examples/rendering.txt` is all of this rendered, ready to `cat` in a terminal.

Unsupported commands, malformed groups, and unbalanced environments return `nil`.

## Install

```elixir
def deps do
  [{:latex_unicode, "~> 0.1"}]
end
```

## Development

`mix ci` matches CI's checks, not its matrix:

```text
compile --all-warnings --warnings-as-errors
format --check-formatted
latex_unicode.render --check guides/math-in-docs.md
credo --strict          # includes the ExSlop AI-slop checks
deps.unlock --check-unused
hex.audit
xref graph --label compile-connected --fail-above 5
dialyzer
ex_dna                  # duplicate code
reach.check --dead-code --smells
test --warnings-as-errors
```

CI's test job runs `mix compile`, `mix format` and `mix test` on Elixir 1.19/OTP 27,
1.19/OTP 28 and 1.20/OTP 29. The quality job runs `mix ci`, builds the docs with
warnings as errors, holds coverage at 93%, and caches Dialyzer's PLT against the
lockfile.

`mix ci.fast` is the inner loop: the list above without `deps.unlock
--check-unused`, `hex.audit`, `xref graph --label compile-connected --fail-above 5`,
`dialyzer`, `ex_dna` and `reach.check --dead-code --smells`.

`examples/compare_with_pi.exs` renders and measures the same inputs with pi's own
`renderLatex` and `visibleWidth`, and reports where the two agree and where this library
is meant to differ: a divergence that is not listed as one fails the run. It reads pi's
source with `gh` and runs it with `bun`, so it is not part of `mix ci`.

Elixir 1.19 is the floor, and the toolchain sets it rather than the library:
`reach` needs 1.18, and the `ex_ast` it depends on needs 1.19. Everything is
`dev`/`test` scoped with `runtime: false`, so a consumer's dependency tree stays
empty — `reach` is also what provides `mix ex_ast.search`, `mix ex_ast.replace`
and `mix ex_ast.diff`.

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
