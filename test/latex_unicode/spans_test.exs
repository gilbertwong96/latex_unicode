defmodule LatexUnicode.SpansTest do
  use ExUnit.Case, async: true

  alias LatexUnicode.Spans

  # pi's markdown tokenizers: spans become placeholders before a markdown
  # parser runs, then substitute/2 puts the rendered math back into the
  # rendered lines.
  defp render(markdown, opts \\ []) do
    {source, spans} = Spans.extract(markdown, opts)
    source |> String.split("\n") |> Spans.substitute(spans)
  end

  test "inline math renders Unicode in place" do
    assert render("the value $x^2 + \\alpha$ here") == ["the value x² + α here"]
  end

  test "paren and bracket delimiters work too" do
    assert render("value \\(x^2\\) and \\[y_1\\]") == ["value x² and y₁"]
  end

  test "display math becomes its own lines" do
    assert render("$$\\frac{x^2 + 1}{x - 1}$$") == ["x² + 1", "──────", "x - 1"]
  end

  test "an unsupported command keeps the source text" do
    assert render("see $\\unknown{x}$ here") == ["see $\\unknown{x}$ here"]
  end

  test "an unclosed span keeps the source text" do
    assert render("cost is $5 and $x^2") == ["cost is $5 and $x^2"]
  end

  test "dollar amounts are not math" do
    assert render("$5 and $10 total") == ["$5 and $10 total"]
  end

  test "render_latex: false keeps every span as source" do
    assert render("the value $x^2$ here", render_latex: false) == ["the value $x^2$ here"]
  end

  test "math inside a fenced code block is left alone" do
    assert render("```\n$x^2$\n```") == ["```", "$x^2$", "```"]
  end

  test "text around a span is preserved" do
    assert render("a $x_1$ b") == ["a x₁ b"]
  end
end
