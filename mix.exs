defmodule LatexUnicode.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/gilbertwong96/latex_unicode"

  # The quality toolchain sets the floor: `reach` requires 1.18 and the `ex_ast`
  # it pulls in requires 1.19, so a lower floor would be a claim the dev deps
  # cannot keep.
  @elixir "~> 1.19"

  def project do
    [
      app: :latex_unicode,
      version: @version,
      elixir: @elixir,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [
        # ExCoveralls as the backend: its JSON is what Codecov ingests, and
        # `mix coveralls.json` only works when its tool is selected. Measured: under
        # this tool the built-in `threshold` check does not fire, so the gate that
        # actually bites is the explicit check in the CI coverage step — this key is
        # kept for the built-in reporter.
        tool: ExCoveralls,
        threshold: 93
      ],
      coveralls: [
        # ExCoveralls' own bar, which is what `mix coveralls` honours. Measured: `mix
        # coveralls.json` does not enforce it — the total stayed at 93.4% with this key
        # set to 99 — so CI holds the number itself. Nothing is listed under
        # `ignore_modules`: the files that measure 0% are struct definitions with no
        # relevant lines, not uncovered code.
        minimum_coverage: 93
      ],
      aliases: aliases(),
      # `Mix.raise/1` and `Mix.shell/0` are in the mix task, which Dialyzer knows nothing
      # about unless the application is in the PLT.
      dialyzer: [plt_add_apps: [:mix]],
      description: description(),
      package: package(),
      docs: docs(),
      name: "LatexUnicode",
      source_url: @source_url
    ]
  end

  def application do
    []
  end

  # `mix test` refuses to run from inside another Mix command outside the test
  # environment, so the aliases and the coverage tasks are pinned to it.
  def cli do
    [
      preferred_envs: [
        ci: :test,
        "ci.fast": :test,
        coveralls: :test,
        "coveralls.json": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp aliases do
    # The one guide is named here rather than looked up: the task takes files, and a
    # second guide would have to be added to both lists, which is the point — a page
    # nobody checks is a page that drifts.
    [
      "ci.fast": [
        "cmd mix compile --all-warnings --warnings-as-errors",
        "format --check-formatted",
        "latex_unicode.render --check guides/math-in-docs.md",
        "credo --strict",
        "test --warnings-as-errors"
      ],
      ci: [
        "cmd mix compile --all-warnings --warnings-as-errors",
        "format --check-formatted",
        "latex_unicode.render --check guides/math-in-docs.md",
        "credo --strict",
        "deps.unlock --check-unused",
        "cmd mix hex.audit",
        "xref graph --label compile-connected --fail-above 5",
        "dialyzer",
        "ex_dna",
        "reach.check --dead-code --smells",
        "test --warnings-as-errors"
      ]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},

      # Quality only, and `runtime: false` with them: none of these reach a
      # consumer's dependency tree. `reach` brings `ex_ast` and the `mix
      # ex_ast.search/replace/diff` tasks along with it.
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_dna, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false},
      {:reach, "~> 2.8", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "Render LaTeX math as Unicode text for terminals, code comments, and " <>
      "anywhere rich formatting is not available."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib mix.exs README.md CHANGELOG.md LICENSE guides)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        {"guides/math-in-docs.rendered.md", title: "Math in docs"},
        "CHANGELOG.md",
        {"LICENSE", title: "License"}
      ]
    ]
  end
end
