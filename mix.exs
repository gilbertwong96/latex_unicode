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
      # ExCoveralls rather than the built-in reporter: it is what writes the
      # `cover/excoveralls.json` the coverage step ingests. The bar itself sits
      # in that step, because `mix coveralls.json` exits 0 with the bar set
      # above the actual total.
      test_coverage: [tool: ExCoveralls],
      aliases: aliases(),
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
    [
      "ci.fast": [
        "cmd mix compile --all-warnings --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "test --warnings-as-errors"
      ],
      ci: [
        "cmd mix compile --all-warnings --warnings-as-errors",
        "format --check-formatted",
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
      files: ~w(lib mix.exs README.md CHANGELOG.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
