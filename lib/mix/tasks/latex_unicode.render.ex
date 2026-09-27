defmodule Mix.Tasks.LatexUnicode.Render do
  @shortdoc "Render the math in markdown files, for the pages ExDoc shows"

  @moduledoc """
  Renders the math spans in markdown files and writes the result beside them, for the
  pages a project hands to ExDoc.

  ExDoc renders no math of its own — a formula in a guide arrives at hexdocs as the
  characters it was written with — so a page that wants its math drawn has it rendered
  first, and the rendered copy is what goes in `extras`:

      mix latex_unicode.render guides/flow.md
      # => guides/flow.rendered.md

      # mix.exs
      docs: [extras: ["guides/flow.rendered.md"]]

  `--check` writes nothing and fails when a committed page no longer matches its
  source, which is how a project keeps the two from drifting apart:

      mix latex_unicode.render --check guides/flow.md

  API documentation takes the other route, because `@doc` takes any expression:
  render the string where it is written and there is nothing to keep in step.

      @doc LatexUnicode.Spans.render("The identity $e^{i\\\\pi} + 1 = 0$ holds.")

  Math inside a fenced code block is left as written. Inline code spans are not: pi
  renders a span inside backticks too, and so does this, so an example of source math
  belongs in a fenced block.
  """

  use Mix.Task

  @switches [check: :boolean]

  @impl Mix.Task
  def run(args) do
    {options, files} = OptionParser.parse!(args, strict: @switches)

    if files == [] do
      Mix.raise("mix latex_unicode.render needs at least one markdown file to render")
    end

    Enum.each(files, &render(&1, options))
  end

  defp render(file, options) do
    rendered = file |> File.read!() |> LatexUnicode.Spans.render()
    output = rendered_path(file)

    if options[:check] do
      check(output, rendered)
    else
      File.write!(output, rendered)
      Mix.shell().info("rendered #{file} -> #{output}")
    end
  end

  defp check(output, rendered) do
    case File.read(output) do
      {:ok, ^rendered} ->
        Mix.shell().info("#{output} is up to date")

      {:ok, _stale} ->
        Mix.raise("#{output} is out of date: render its source again and commit the result")

      {:error, _reason} ->
        Mix.raise("#{output} is missing: render its source first")
    end
  end

  # guides/flow.md -> guides/flow.rendered.md
  defp rendered_path(file) do
    Path.rootname(file) <> ".rendered" <> Path.extname(file)
  end
end
