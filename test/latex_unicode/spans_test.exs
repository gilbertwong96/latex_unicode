defmodule LatexUnicode.SpansTest do
  use ExUnit.Case, async: true

  alias LatexUnicode.Spans

  doctest LatexUnicode.Spans

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

  # pi renders a token only when it is not pending, so a span whose closing delimiter
  # has not arrived keeps its source. This is what stops a streaming answer from
  # flickering between source and math.
  test "an unfinished span keeps its source, as pi's pending token does" do
    assert render("the formula is $x^2") == ["the formula is $x^2"]
    assert render("streaming: $\\frac{1}{2} + 1 and") == ["streaming: $\\frac{1}{2} + 1 and"]
    assert render("value \\(x^2") == ["value \\(x^2"]
  end

  # A `$` rejected as not math (`$5`) is behind the scan, not the end of it: a span
  # after it is still math.
  test "a span after a dollar amount is still math" do
    assert render("cost is $5 and $x^2$ here") == ["cost is $5 and x² here"]
    assert render("it costs $5, so $a^2$ matters") == ["it costs $5, so a² matters"]
    assert render("$5 and $10 total") == ["$5 and $10 total"]
  end

  # ExDoc renders no math of its own, so a formula reaches hexdocs only if the `@doc`
  # string already holds the rendered text. `@doc` takes an expression, so the recipe is
  # a call — this compiles such a module and reads its docs chunk back out, which is the
  # chunk ExDoc reads.
  test "a doc attribute can render its own math" do
    directory =
      Path.join(System.tmp_dir!(), "latex_unicode_doc_math_#{System.unique_integer([:positive])}")

    File.mkdir_p!(directory)
    on_exit(fn -> File.rm_rf(directory) end)

    file = Path.join(directory, "doc_math_demo.ex")

    File.write!(file, """
    defmodule LatexUnicode.DocMathDemo do
      @doc LatexUnicode.Spans.render("The identity $a^2 + b^2 = c^2$ holds.")
      def demo, do: :ok
    end
    """)

    # The docs chunk is written when the compiler is asked for it, which is what Mix
    # does; this test compiles a module itself.
    Code.compiler_options(docs: true)

    assert {:ok, [LatexUnicode.DocMathDemo], diagnostics} =
             Kernel.ParallelCompiler.compile_to_path([file], directory, return_diagnostics: true)

    assert diagnostics == %{runtime_warnings: [], compile_warnings: []}

    assert {:docs_v1, _, :elixir, _, _, _, docs} =
             Code.fetch_docs(Path.join(directory, "Elixir.LatexUnicode.DocMathDemo.beam"))

    assert {{:function, :demo, 0}, _, _, %{"en" => doc}, _} =
             List.keyfind(docs, {:function, :demo, 0}, 0)

    assert doc =~ "a² + b² = c²"
  end
end
