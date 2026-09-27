defmodule CompareWithPi do
  @moduledoc """
  Renders the same expressions with this library and with pi's own `renderLatex`, and
  measures the same strings with `LatexUnicode.Width.display/1` and pi's `visibleWidth`,
  then says where they agree and where they are meant to differ.

      mix run examples/compare_with_pi.exs

  pi's source is read from its repository rather than vendored, and run by `bun`; that
  is why this is an example rather than a step of `mix ci`.

  Every case says which of the two it expects. `:same` is the ported behaviour — a
  divergence there is a regression. `:differs` is one of the places this library goes
  further than pi (the README's "What it renders" lists them) — and a case that was
  expected to differ but no longer does is reported as a warning, because it means pi
  caught up and the note here is stale.
  """

  @pi_source "repos/earendil-works/pi/contents/packages/tui/src"
  @pi_files ["latex.ts", "utils.ts"]
  @latex_marker "export function renderLatex"

  # {source, display?, expectation}
  @render_cases [
    # Ported behaviour: pi's rendering, character for character.
    {"\\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}", false, :same},
    {"\\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}", true, :same},
    {"x^2 + y^2 = r^2", false, :same},
    {"e^{i\\pi} + 1 = 0", false, :same},
    {"e^{-x}", true, :same},
    {"e^{-x^2}", true, :same},
    {"\\sum_{i=0}^{n} x_i^2", true, :same},
    {"\\prod_{k=1}^{n} k = n!", true, :same},
    {"\\int_0^1 e^{-x^2}\\,dx", true, :same},
    {"\\lim_{x \\to 0} \\frac{\\sin x}{x} = 1", true, :same},
    {"\\sqrt[3]{\\frac{x + 1}{y - 1}}", true, :same},
    {"\\sum_{\\substack{i=0 \\\\ j=0}}^n x", false, :same},
    {"\\overbrace{x+y}^{n}", false, :same},
    {"\\underbrace{x+y}_{n}", false, :same},
    {"\\mathbf{F} = m\\mathbf{a}", false, :same},
    {"\\boxed{E = mc^2}", true, :same},
    {"\\binom{n}{k}", true, :same},
    {"\\operatorname*{arg\\,max}_{x} f(x)", true, :same},
    {"\\hat{H}\\psi = E\\psi", false, :same},
    {"\\vec{v} \\cdot \\vec{w}", false, :same},
    {"\\alpha + \\beta \\to \\gamma", false, :same},
    {"\\mathbb{R}^n \\to \\mathbb{R}^m", false, :same},
    {"\\begin{pmatrix} a & b \\\\ c & d \\end{pmatrix}", true, :same},
    {"\\begin{bmatrix} 1 & 0 \\\\ 0 & 1 \\end{bmatrix}", true, :same},
    {"\\begin{cases} x^2 & x > 0 \\\\ 0 & x \\le 0 \\end{cases}", true, :same},
    {"\\begin{aligned} (a+b)^2 &= a^2 + 2ab + b^2 \\end{aligned}", true, :same},
    {"\\left( x \\right)", false, :same},
    {"\\big(x\\big)", false, :same},
    {"\\color{red}{x}", false, :same},
    {"\\hspace{1em} x", false, :same},
    {"\\frac{1}{", false, :same},

    # Beyond pi: the sizes, the alphabets, the stacks, the brace, the rule.
    {"\\left(\\frac{a}{b}\\right)", true, :differs},
    {"\\left\\langle \\frac{a}{b} \\right\\rangle", true, :differs},
    {"\\Big[ \\frac{a}{b} \\Big]", true, :differs},
    {"\\big(x\\big)", true, :differs},
    {"\\mathcal{F}", false, :differs},
    {"\\mathscr{L}", false, :differs},
    {"\\mathfrak{C}", false, :differs},
    {"\\substack{a \\\\ bbb}", true, :differs},
    {"\\sum_{\\substack{i=0 \\\\ j=0}}^n x", true, :differs},
    {"\\overbrace{x+y}^{n}", true, :differs},
    {"\\underbrace{x+y}_{n}", true, :differs},
    {"\\begin{array}{c} a \\\\ \\hline b \\end{array}", true, :differs}
  ]

  # {text, expectation}: the width table, plus the escape sequences pi's own scan
  # misreads.
  @width_cases [
    {"abc", :same},
    {"中文", :same},
    {"한국어", :same},
    {"ｱ", :same},
    {"Ａ", :same},
    {"e\u0301", :same},
    {"क्क", :same},
    {"\u0E01\u0E33", :same},
    {"👍", :same},
    {"👍🏽", :same},
    {"👨‍👩‍👧", :same},
    {"🏳️‍🌈", :same},
    {"🇺🇸", :same},
    {"1️⃣", :same},
    {"1⃣", :same},
    {"❤", :same},
    {"❤️", :same},
    {"☀️", :same},
    {"⏱", :same},
    {"🀄", :same},
    {"🀀", :same},
    {"\u200B", :same},
    {"a\u200Bb", :same},
    {"\u00AD", :same},
    {"─", :same},
    {"│", :same},
    {"⎛", :same},
    {"⟨", :same},
    {"\u{F0000}", :same},
    {"𝔄", :same},
    {"日本語 🀄 α", :same},
    {"mixed 中文 text", :same},
    {"\e[31mred\e[0m", :same},
    {"\e[2J", :same},
    {"\e]0;title\a", :same},
    # pi's CSI scan ends only on m/G/K/H/J, so it counts a hidden cursor as five cells.
    {"\e[?25l", :differs}
  ]

  # Every codepoint in these ranges, measured by both: the tables behind the width are
  # generated from pi's own data, so a drift here means the data moved.
  @sample_ranges [
    0x00A0..0x02FF,
    0x0300..0x036F,
    0x0590..0x06FF,
    0x0900..0x097F,
    0x0E00..0x0E7F,
    0x1100..0x11FF,
    0x2000..0x206F,
    0x20D0..0x20F0,
    0x2100..0x214F,
    0x2190..0x22FF,
    0x2300..0x23FF,
    0x2460..0x24FF,
    0x2500..0x257F,
    0x25A0..0x25FF,
    0x2600..0x27BF,
    0x2B00..0x2BFF,
    0x2E80..0x2EFF,
    0x3000..0x303F,
    0x3040..0x30FF,
    0x4E00..0x4E20,
    0xFE00..0xFE0F,
    0xFE30..0xFE4F,
    0xFF00..0xFFEF,
    0x1D400..0x1D420,
    0x1F000..0x1F02F,
    0x1F1E6..0x1F1FF,
    0x1F300..0x1F3FF,
    0x1F900..0x1F9FF,
    0x1FA00..0x1FAFF,
    0xE0000..0xE007F
  ]

  @runner """
  import { renderLatex } from "./latex.ts";
  import { visibleWidth } from "./utils.ts";

  const cases = JSON.parse(await Bun.file("cases.json").text());
  const renders = cases.renders.map(
    (one: { source: string; display: boolean }) => renderLatex(one.source, { display: one.display }) ?? null
  );
  const widths = cases.widths.map((text: string) => visibleWidth(text));

  await Bun.write("pi.json", JSON.stringify({ renders, widths }));
  """

  def main do
    directory = Path.join(System.tmp_dir!(), "latex_unicode_compare_with_pi")
    File.rm_rf(directory)
    File.mkdir_p!(directory)

    fetch!(directory)
    pi = run_pi!(directory)

    renderings = compare_renders(pi["renders"])
    widths = compare_widths(pi["widths"])

    report(renderings, widths)
  end

  # pi's source, read from the repository. `gh api` writes its own errors to stderr, so a
  # failed fetch leaves an empty file rather than a loud failure: both checks below are
  # what keep that from looking like a broken module later.
  defp fetch!(directory) do
    Enum.each(@pi_files, fn file ->
      {output, status} =
        System.cmd("gh", [
          "api",
          "-H",
          "Accept: application/vnd.github.raw",
          "#{@pi_source}/#{file}"
        ])

      if status != 0 or output == "" do
        Mix.raise("gh api could not fetch #{file} (status #{status}, #{byte_size(output)} bytes)")
      end

      File.write!(Path.join(directory, file), output)
    end)

    latex = File.read!(Path.join(directory, "latex.ts"))

    unless String.contains?(latex, @latex_marker) do
      Mix.raise("latex.ts came back without `#{@latex_marker}`: not the file this expects")
    end
  end

  defp run_pi!(directory) do
    File.write!(Path.join(directory, "runner.ts"), @runner)

    File.write!(
      Path.join(directory, "cases.json"),
      JSON.encode!(%{
        renders:
          Enum.map(@render_cases, fn {source, display, _} ->
            %{source: source, display: display}
          end),
        widths: Enum.map(@width_cases, &elem(&1, 0)) ++ sampled_strings()
      })
    )

    {_output, status} = System.cmd("bun", ["runner.ts"], cd: directory)

    if status != 0 do
      Mix.raise("bun could not run pi's renderer (status #{status}); is bun on PATH?")
    end

    # The runner writes its results to a file rather than to stdout, so it stays runnable
    # by hand in the directory it fetched pi into.
    directory |> Path.join("pi.json") |> File.read!() |> JSON.decode!()
  end

  defp compare_renders(pi_renderings) do
    @render_cases
    |> Enum.zip(pi_renderings)
    |> Enum.map(fn {{source, display, expectation}, theirs} ->
      ours = LatexUnicode.render(source, display: display)

      %{
        label: "#{source}#{if display, do: "  (display: true)", else: ""}",
        expected: expectation,
        agreed?: ours == theirs,
        ours: ours,
        theirs: theirs
      }
    end)
  end

  defp compare_widths(pi_widths) do
    texts = Enum.map(@width_cases, &elem(&1, 0)) ++ sampled_strings()

    expectations =
      Enum.map(@width_cases, &elem(&1, 1)) ++ List.duplicate(:same, length(sampled_strings()))

    texts
    |> Enum.zip(pi_widths)
    |> Enum.zip(expectations)
    |> Enum.map(fn {{text, theirs}, expectation} ->
      ours = LatexUnicode.Width.display(text)

      %{
        label: "#{inspect(text)} measures",
        expected: expectation,
        agreed?: ours == theirs,
        ours: ours,
        theirs: theirs
      }
    end)
  end

  defp sampled_strings do
    for range <- @sample_ranges, codepoint <- range, do: <<codepoint::utf8>>
  end

  defp report(renderings, widths) do
    IO.puts("pi's renderer: #{@pi_source} (#{Enum.join(@pi_files, ", ")})")

    report_section("renderLatex", renderings)
    report_section("visibleWidth", widths)
  end

  defp report_section(title, results) do
    unexpected = Enum.filter(results, &(&1.expected == :same and not &1.agreed?))
    caught_up = Enum.filter(results, &(&1.expected == :differs and &1.agreed?))
    differing = Enum.filter(results, &(&1.expected == :differs and not &1.agreed?))

    IO.puts("\n── #{title}: #{length(results)} cases ──")

    IO.puts(
      "   #{length(results) - length(unexpected) - length(caught_up) - length(differing)} same, " <>
        "#{length(differing)} differ as expected, #{length(caught_up)} unexpectedly same, " <>
        "#{length(unexpected)} unexpected"
    )

    Enum.each(differing, fn result -> IO.puts("   ~ #{result.label}") end)

    Enum.each(caught_up, fn result ->
      IO.puts("   ? #{result.label} was expected to differ and no longer does — pi caught up?")
    end)

    Enum.each(unexpected, fn result ->
      IO.puts("   ✗ #{result.label}")
      IO.puts("     pi:   #{inspect(result.theirs)}")
      IO.puts("     ours: #{inspect(result.ours)}")
    end)

    if unexpected != [] do
      Mix.raise("#{length(unexpected)} #{title} case(s) diverge from pi without saying so")
    end
  end
end

CompareWithPi.main()
