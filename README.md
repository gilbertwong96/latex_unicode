# LatexUnicode

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

## Development

`mix ci` matches CI's checks, not its matrix:

```text
compile --all-warnings --warnings-as-errors
format --check-formatted
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
1.19/OTP 28 and 1.20/OTP 29. The quality job runs `mix ci` once on the newest pair,
holds coverage at 91%, and caches Dialyzer's PLT against the lockfile.

`mix ci.fast` is the inner loop: the list above without `deps.unlock
--check-unused`, `hex.audit`, `xref graph --label compile-connected --fail-above 5`,
`dialyzer`, `ex_dna` and `reach.check --dead-code --smells`.

Elixir 1.19 is the floor, and the toolchain sets it rather than the library:
`reach` needs 1.18, and the `ex_ast` it depends on needs 1.19. Everything is
`dev`/`test` scoped with `runtime: false`, so a consumer's dependency tree stays
empty — `reach` is also what provides `mix ex_ast.search`, `mix ex_ast.replace`
and `mix ex_ast.diff`.

## Attribution

This library is a port of pi-tui's LaTeX renderer and markdown tokenizers
(`packages/tui/src/latex.ts` and `components/markdown.ts` in
[pi](https://github.com/earendil-works/pi)) by Mario Zechner, MIT licensed. The
symbol and command tables are generated from that source, and the test suite is a
port of its tests, so behaviour matches the reference implementation rather than
re-inventing it. The display-width math comes from the same project's
`visibleWidth`.

## License

MIT — see [LICENSE](LICENSE), which also carries the upstream notice.
