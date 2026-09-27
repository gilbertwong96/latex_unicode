# Math in docs

ExDoc renders no math of its own: a formula written into a doc string reaches hexdocs
as the characters it was written with. This library renders math to Unicode, so the
formula can be text by the time ExDoc reads it — and this page is that twice over:

- its source is `guides/math-in-docs.md`, where the formulas are written in LaTeX
  between dollar signs;
- the page you are reading is `guides/math-in-docs.rendered.md`, which
  `mix latex_unicode.render` wrote, and the `extras` list hands ExDoc that one.

## API documentation

`@doc` accepts any expression that returns a string, so a doc string can render itself
where it is written, with nothing to keep in step:

```elixir
@doc LatexUnicode.Spans.render("""
The identity $e^{i\\pi} + 1 = 0$ holds in the complex plane.
""")
```

Two backslashes, because the string is Elixir before it is LaTeX: `\\pi` is the
`\pi` the renderer sees.

## Guide pages

A guide is a file, and a project hands it to ExDoc through `extras:`. Render the math
first, then point ExDoc at the rendered copy:

    mix latex_unicode.render guides/math-in-docs.md
    # => guides/math-in-docs.rendered.md

```elixir
docs: [extras: ["guides/math-in-docs.rendered.md"]]
```

The paths are this page's own: the command above is what writes the copy you are
reading. `mix ci` runs the check that follows, so the two cannot drift apart unnoticed.

`--check` writes nothing and fails when a committed page no longer matches its source:

    mix latex_unicode.render --check guides/math-in-docs.md

## A formula, drawn

Display math stacks into art. This is the page's own source, rendered:

$$\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$

and an inline one, the same way it would appear in prose: the area is $a^2 + b^2 = c^2$
for a right triangle.

## What is left as written

Math inside a fenced code block is kept as written, which is where an example of source
math belongs:

```
$e^{i\pi} + 1 = 0$
```

Inline code spans are not protected: pi renders a span inside backticks too, and so does
this. An unfinished span keeps its source until its closing delimiter arrives, which is
what stops a streaming answer from flickering between source and math.
