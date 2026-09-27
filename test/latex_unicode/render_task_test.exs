defmodule LatexUnicode.RenderTaskTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  setup do
    directory =
      Path.join(
        System.tmp_dir!(),
        "latex_unicode_render_task_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(directory)
    on_exit(fn -> File.rm_rf(directory) end)

    %{directory: directory}
  end

  test "writes the rendered copy beside its source", %{directory: directory} do
    source = Path.join(directory, "page.md")
    File.write!(source, "The identity $e^{i\\pi} + 1 = 0$ holds.\n")

    assert capture_io(fn -> render([source]) end) =~ "page.md -> "

    assert File.read!(Path.join(directory, "page.rendered.md")) ==
             "The identity e^(iπ) + 1 = 0 holds.\n"
  end

  test "fences display math, which a parser would otherwise reflow", %{directory: directory} do
    source = Path.join(directory, "page.md")
    File.write!(source, "$$\\frac{1}{2}$$\n")

    capture_io(fn -> render([source]) end)

    assert File.read!(Path.join(directory, "page.rendered.md")) == "```text\n1\n─\n2\n```\n"
  end

  test "--check passes while the two are in step", %{directory: directory} do
    source = Path.join(directory, "page.md")
    File.write!(source, "The area is $a^2 + b^2 = c^2$.\n")

    capture_io(fn -> render([source]) end)

    assert capture_io(fn -> render(["--check", source]) end) =~ "is up to date"
  end

  test "--check fails when the copy is stale", %{directory: directory} do
    source = Path.join(directory, "page.md")
    File.write!(source, "The area is $a^2$.\n")
    File.write!(Path.join(directory, "page.rendered.md"), "The area is $a^2$.\n")

    assert_raise Mix.Error, ~r/is out of date/, fn -> render(["--check", source]) end
  end

  test "--check fails when the copy is missing", %{directory: directory} do
    source = Path.join(directory, "page.md")
    File.write!(source, "The area is $a^2$.\n")

    assert_raise Mix.Error, ~r/is missing/, fn -> render(["--check", source]) end
  end

  test "a path that does not exist is a sentence, not a stack trace" do
    assert_raise Mix.Error, ~r|could not read guides\/nowhere\.md: no such file|, fn ->
      render(["guides/nowhere.md"])
    end
  end

  test "needs a file to work on" do
    assert_raise Mix.Error, ~r/needs at least one markdown file/, fn -> render([]) end
  end

  defp render(args) do
    Mix.Task.reenable("latex_unicode.render")
    Mix.Task.run("latex_unicode.render", args)
  end
end
