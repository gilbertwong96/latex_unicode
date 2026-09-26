defmodule LatexUnicode do
  @moduledoc """
  LaTeX math rendering for the transcript, mirroring pi-tui's `renderLatex`
  (`packages/tui/src/latex.ts`).

  A recursive-descent parser over the math subset pi supports: symbols,
  scripts, fractions, roots, accents, named operators, environments
  (`aligned`, `cases`, `pmatrix`, ...) and display-mode stacking. The output is
  terminal-friendly Unicode; `nil` means "unsupported or malformed", and the
  caller falls back to the raw source (pi renders the raw token too).

  Display layout uses pi's marker scheme: fractions, stacked operator limits,
  stacked scripts and matrices push a layout node and leave a
  `\\u{F0000}<index>\\u{F0001}` marker in the text; the layout pass then expands
  the markers into multi-line art.
  """

  alias LatexUnicode.Width

  defp visible_width(text), do: Width.display(text)

  # Marker characters pi uses to defer display layout until the whole
  # expression has been parsed.
  @layout_marker_start "\u{F0000}"
  @layout_marker_end "\u{F0001}"
  @layout_marker_pattern ~r/\x{F0000}([0-9]+)\x{F0001}/u
  @trailing_layout_marker_pattern ~r/\x{F0000}([0-9]+)\x{F0001}$/u
  # pi protects the padding spaces of laid-out cells from whitespace
  # normalization and restores them at the end.
  @protected_space "\u{F0002}"
  # A negative spacing command removes the preceding space instead of adding.
  @negative_space "\u{0000}"
  # pi marks a named operator's boundaries so the spacing pass can normalize
  # the space around it, then strips the markers.
  @named_operator_start "\u{F0004}"
  @named_operator_end "\u{F0005}"
  @named_operator_left_pattern ~r/(?<=[\p{L}\p{N}\)\}\x{F0001}])\x{F0004}/u
  @named_operator_right_pattern ~r/\x{F0005}(?=[\p{L}\p{N}√\x{F0000}])/u
  # Environment rows are separated by `\\` with an optional `[<len>]`.
  @environment_row_pattern ~r/\\\\(?:\[[^\]\n]*\])?/
  @matrix_delimiters %{
    "pmatrix" => {"⎛", "⎞", "⎜", "⎟", "⎝", "⎠"},
    "bmatrix" => {"⎡", "⎤", "⎢", "⎥", "⎣", "⎦"},
    "Bmatrix" => {"⎧", "⎫", "⎨", "⎬", "⎩", "⎭"},
    "vmatrix" => {"│", "│", "│", "│", "│", "│"},
    "Vmatrix" => {"║", "║", "║", "║", "║", "║"}
  }

  # --- tables (generated from pi-tui's latex.ts) ---

  @symbols %{
    "alpha" => "α",
    "beta" => "β",
    "gamma" => "γ",
    "delta" => "δ",
    "epsilon" => "ϵ",
    "varepsilon" => "ε",
    "zeta" => "ζ",
    "eta" => "η",
    "theta" => "θ",
    "vartheta" => "ϑ",
    "iota" => "ι",
    "kappa" => "κ",
    "varkappa" => "ϰ",
    "lambda" => "λ",
    "mu" => "μ",
    "nu" => "ν",
    "xi" => "ξ",
    "pi" => "π",
    "varpi" => "ϖ",
    "rho" => "ρ",
    "varrho" => "ϱ",
    "sigma" => "σ",
    "varsigma" => "ς",
    "tau" => "τ",
    "upsilon" => "υ",
    "phi" => "ϕ",
    "varphi" => "φ",
    "chi" => "χ",
    "psi" => "ψ",
    "omega" => "ω",
    "Gamma" => "Γ",
    "Delta" => "Δ",
    "Theta" => "Θ",
    "Lambda" => "Λ",
    "Xi" => "Ξ",
    "Pi" => "Π",
    "Sigma" => "Σ",
    "Upsilon" => "Υ",
    "Phi" => "Φ",
    "Psi" => "Ψ",
    "Omega" => "Ω",
    "pm" => "±",
    "mp" => "∓",
    "times" => "×",
    "div" => "÷",
    "cdot" => "·",
    "ast" => "∗",
    "star" => "⋆",
    "circ" => "∘",
    "bullet" => "•",
    "oplus" => "⊕",
    "ominus" => "⊖",
    "otimes" => "⊗",
    "oslash" => "⊘",
    "odot" => "⊙",
    "bigcirc" => "○",
    "dagger" => "†",
    "ddagger" => "‡",
    "amalg" => "⨿",
    "uplus" => "⊎",
    "sqcap" => "⊓",
    "sqcup" => "⊔",
    "bowtie" => "⋈",
    "Join" => "⋈",
    "ltimes" => "⋉",
    "rtimes" => "⋊",
    "leftouterjoin" => "⟕",
    "rightouterjoin" => "⟖",
    "fullouterjoin" => "⟗",
    "triangleleft" => "◁",
    "triangleright" => "▷",
    "wr" => "≀",
    "cap" => "∩",
    "cup" => "∪",
    "bigcap" => "⋂",
    "bigcup" => "⋃",
    "bigwedge" => "⋀",
    "bigvee" => "⋁",
    "bigsqcup" => "⨆",
    "biguplus" => "⨄",
    "bigoplus" => "⨁",
    "bigotimes" => "⨂",
    "bigodot" => "⨀",
    "setminus" => "∖",
    "in" => "∈",
    "notin" => "∉",
    "ni" => "∋",
    "subset" => "⊂",
    "supset" => "⊃",
    "subseteq" => "⊆",
    "supseteq" => "⊇",
    "sqsubset" => "⊏",
    "sqsupset" => "⊐",
    "sqsubseteq" => "⊑",
    "sqsupseteq" => "⊒",
    "prec" => "≺",
    "preceq" => "≼",
    "succ" => "≻",
    "succeq" => "≽",
    "ll" => "≪",
    "gg" => "≫",
    "le" => "≤",
    "leq" => "≤",
    "leqslant" => "≤",
    "ge" => "≥",
    "geq" => "≥",
    "geqslant" => "≥",
    "ne" => "≠",
    "neq" => "≠",
    "equiv" => "≡",
    "approx" => "≈",
    "sim" => "∼",
    "simeq" => "≃",
    "cong" => "≅",
    "asymp" => "≍",
    "doteq" => "≐",
    "propto" => "∝",
    "parallel" => "∥",
    "perp" => "⊥",
    "mid" => "∣",
    "vdash" => "⊢",
    "dashv" => "⊣",
    "models" => "⊨",
    "Vdash" => "⊩",
    "Vvdash" => "⊪",
    "nvdash" => "⊬",
    "nvDash" => "⊭",
    "forall" => "∀",
    "exists" => "∃",
    "nexists" => "∄",
    "neg" => "¬",
    "land" => "∧",
    "wedge" => "∧",
    "lor" => "∨",
    "vee" => "∨",
    "to" => "→",
    "rightarrow" => "→",
    "longrightarrow" => "→",
    "leftarrow" => "←",
    "longleftarrow" => "←",
    "gets" => "←",
    "leftrightarrow" => "↔",
    "longleftrightarrow" => "↔",
    "hookleftarrow" => "↩",
    "hookrightarrow" => "↪",
    "twoheadleftarrow" => "↞",
    "twoheadrightarrow" => "↠",
    "leftharpoonup" => "↼",
    "leftharpoondown" => "↽",
    "rightharpoonup" => "⇀",
    "rightharpoondown" => "⇁",
    "rightleftharpoons" => "⇌",
    "leftrightharpoons" => "⇋",
    "nearrow" => "↗",
    "searrow" => "↘",
    "swarrow" => "↙",
    "nwarrow" => "↖",
    "rightsquigarrow" => "⇝",
    "leadsto" => "⇝",
    "Rightarrow" => "⇒",
    "Longrightarrow" => "⇒",
    "Leftarrow" => "⇐",
    "Longleftarrow" => "⇐",
    "Leftrightarrow" => "⇔",
    "Longleftrightarrow" => "⇔",
    "implies" => "⇒",
    "iff" => "⇔",
    "mapsto" => "↦",
    "longmapsto" => "↦",
    "uparrow" => "↑",
    "downarrow" => "↓",
    "partial" => "∂",
    "nabla" => "∇",
    "int" => "∫",
    "iint" => "∬",
    "iiint" => "∭",
    "oint" => "∮",
    "sum" => "∑",
    "prod" => "∏",
    "coprod" => "∐",
    "infty" => "∞",
    "emptyset" => "∅",
    "varnothing" => "∅",
    "angle" => "∠",
    "therefore" => "∴",
    "because" => "∵",
    "aleph" => "ℵ",
    "beth" => "ℶ",
    "gimel" => "ℷ",
    "daleth" => "ℸ",
    "top" => "⊤",
    "bot" => "⊥",
    "triangle" => "△",
    "square" => "□",
    "lozenge" => "◊",
    "checkmark" => "✓",
    "complement" => "∁",
    "wp" => "℘",
    "prime" => "′",
    "ldots" => "…",
    "dots" => "…",
    "cdots" => "⋯",
    "vdots" => "⋮",
    "ddots" => "⋱",
    "ell" => "ℓ",
    "hbar" => "ℏ",
    "Im" => "ℑ",
    "Re" => "ℜ",
    "langle" => "⟨",
    "rangle" => "⟩",
    "vert" => "|",
    "lvert" => "|",
    "rvert" => "|",
    "Vert" => "‖",
    "lVert" => "‖",
    "rVert" => "‖",
    "lbrace" => "{",
    "rbrace" => "}",
    "backslash" => "\\",
    "lfloor" => "⌊",
    "rfloor" => "⌋",
    "lceil" => "⌈",
    "rceil" => "⌉",
    "colon" => ":"
  }

  @negated_symbols %{
    "<" => "≮",
    ">" => "≯",
    "=" => "≠",
    "∈" => "∉",
    "∋" => "∌",
    "∣" => "∤",
    "∥" => "∦",
    "∼" => "≁",
    "≃" => "≄",
    "≅" => "≇",
    "≈" => "≉",
    "≡" => "≢",
    "≤" => "≰",
    "≥" => "≱",
    "≺" => "⊀",
    "≻" => "⊁",
    "⊂" => "⊄",
    "⊃" => "⊅",
    "⊆" => "⊈",
    "⊇" => "⊉",
    "⊢" => "⊬",
    "⊨" => "⊭",
    "↔" => "↮",
    "←" => "↚",
    "→" => "↛",
    "⇒" => "⇏",
    "⇐" => "⇍",
    "⇔" => "⇎",
    "≼" => "⋠",
    "≽" => "⋡"
  }

  @blackboard %{
    "C" => "ℂ",
    "H" => "ℍ",
    "N" => "ℕ",
    "P" => "ℙ",
    "Q" => "ℚ",
    "R" => "ℝ",
    "Z" => "ℤ"
  }

  @superscripts %{
    "0" => "⁰",
    "1" => "¹",
    "2" => "²",
    "3" => "³",
    "4" => "⁴",
    "5" => "⁵",
    "6" => "⁶",
    "7" => "⁷",
    "8" => "⁸",
    "9" => "⁹",
    "+" => "⁺",
    "-" => "⁻",
    "=" => "⁼",
    "(" => "⁽",
    ")" => "⁾",
    "a" => "ᵃ",
    "b" => "ᵇ",
    "c" => "ᶜ",
    "d" => "ᵈ",
    "e" => "ᵉ",
    "f" => "ᶠ",
    "g" => "ᵍ",
    "h" => "ʰ",
    "i" => "ⁱ",
    "j" => "ʲ",
    "k" => "ᵏ",
    "l" => "ˡ",
    "m" => "ᵐ",
    "n" => "ⁿ",
    "o" => "ᵒ",
    "p" => "ᵖ",
    "r" => "ʳ",
    "s" => "ˢ",
    "t" => "ᵗ",
    "u" => "ᵘ",
    "v" => "ᵛ",
    "w" => "ʷ",
    "x" => "ˣ",
    "y" => "ʸ",
    "z" => "ᶻ"
  }

  @subscripts %{
    "0" => "₀",
    "1" => "₁",
    "2" => "₂",
    "3" => "₃",
    "4" => "₄",
    "5" => "₅",
    "6" => "₆",
    "7" => "₇",
    "8" => "₈",
    "9" => "₉",
    "+" => "₊",
    "-" => "₋",
    "=" => "₌",
    "(" => "₍",
    ")" => "₎",
    "a" => "ₐ",
    "e" => "ₑ",
    "h" => "ₕ",
    "i" => "ᵢ",
    "j" => "ⱼ",
    "k" => "ₖ",
    "l" => "ₗ",
    "m" => "ₘ",
    "n" => "ₙ",
    "o" => "ₒ",
    "p" => "ₚ",
    "r" => "ᵣ",
    "s" => "ₛ",
    "t" => "ₜ",
    "u" => "ᵤ",
    "v" => "ᵥ",
    "x" => "ₓ"
  }

  @accents %{
    "acute" => "́",
    "bar" => "̅",
    "breve" => "̆",
    "check" => "̌",
    "ddot" => "̈",
    "dot" => "̇",
    "grave" => "̀",
    "hat" => "̂",
    "mathring" => "̊",
    "overleftarrow" => "⃖",
    "overleftrightarrow" => "⃡",
    "overline" => "̅",
    "overrightarrow" => "⃗",
    "tilde" => "̃",
    "underline" => "̲",
    "vec" => "⃗",
    "widehat" => "̂",
    "widetilde" => "̃"
  }

  @named_operators MapSet.new([
                     "arccos",
                     "arcsin",
                     "arctan",
                     "arg",
                     "cos",
                     "cosh",
                     "cot",
                     "coth",
                     "csc",
                     "deg",
                     "det",
                     "dim",
                     "exp",
                     "gcd",
                     "hom",
                     "inf",
                     "ker",
                     "lg",
                     "lim",
                     "liminf",
                     "limsup",
                     "ln",
                     "log",
                     "max",
                     "min",
                     "Pr",
                     "sec",
                     "sin",
                     "sinh",
                     "sup",
                     "tan",
                     "tanh"
                   ])

  @limit_operators MapSet.new([
                     "argmax",
                     "argmin",
                     "inf",
                     "injlim",
                     "lim",
                     "liminf",
                     "limsup",
                     "max",
                     "min",
                     "projlim",
                     "sup"
                   ])

  @display_limit_symbols MapSet.new([
                           "bigcap",
                           "bigcup",
                           "bigodot",
                           "bigoplus",
                           "bigotimes",
                           "bigsqcup",
                           "biguplus",
                           "bigvee",
                           "bigwedge",
                           "coprod",
                           "int",
                           "iint",
                           "iiint",
                           "oint",
                           "prod",
                           "sum"
                         ])

  @relation_commands MapSet.new([
                       "Leftarrow",
                       "Leftrightarrow",
                       "Longleftarrow",
                       "Longleftrightarrow",
                       "Longrightarrow",
                       "Rightarrow",
                       "Join",
                       "Vdash",
                       "Vvdash",
                       "approx",
                       "asymp",
                       "bowtie",
                       "cong",
                       "dashv",
                       "fullouterjoin",
                       "doteq",
                       "downarrow",
                       "equiv",
                       "ge",
                       "geq",
                       "geqslant",
                       "gets",
                       "gg",
                       "hookleftarrow",
                       "hookrightarrow",
                       "iff",
                       "implies",
                       "in",
                       "leadsto",
                       "le",
                       "leftarrow",
                       "leftharpoondown",
                       "leftharpoonup",
                       "leftrightarrow",
                       "leftrightharpoons",
                       "leftouterjoin",
                       "leq",
                       "leqslant",
                       "ll",
                       "longleftarrow",
                       "longleftrightarrow",
                       "longmapsto",
                       "longrightarrow",
                       "ltimes",
                       "mapsto",
                       "mid",
                       "models",
                       "ne",
                       "nearrow",
                       "neq",
                       "ni",
                       "notin",
                       "nvdash",
                       "nvDash",
                       "nwarrow",
                       "parallel",
                       "perp",
                       "prec",
                       "preceq",
                       "propto",
                       "rightharpoondown",
                       "rightharpoonup",
                       "rightleftharpoons",
                       "rightouterjoin",
                       "rightarrow",
                       "rightsquigarrow",
                       "rtimes",
                       "searrow",
                       "sim",
                       "simeq",
                       "sqsubset",
                       "sqsubseteq",
                       "sqsupset",
                       "sqsupseteq",
                       "subset",
                       "subseteq",
                       "succ",
                       "succeq",
                       "supset",
                       "supseteq",
                       "swarrow",
                       "to",
                       "triangleleft",
                       "triangleright",
                       "twoheadleftarrow",
                       "twoheadrightarrow",
                       "uparrow",
                       "vdash"
                     ])

  @spacing_commands MapSet.new([
                      ",",
                      ":",
                      ";",
                      " ",
                      ">",
                      "enspace",
                      "enskip",
                      "medspace",
                      "quad",
                      "qquad",
                      "thickspace",
                      "thinspace"
                    ])

  @negative_spacing_commands MapSet.new([
                               "!",
                               "negmedspace",
                               "negthickspace",
                               "negthinspace"
                             ])

  @font_switch_commands MapSet.new([
                          "bf",
                          "cal",
                          "it",
                          "rm",
                          "sf",
                          "sl",
                          "tt"
                        ])

  @ignored_commands MapSet.new([
                      "displaystyle",
                      "limits",
                      "nolimits",
                      "scriptstyle",
                      "scriptscriptstyle",
                      "textstyle"
                    ])

  @size_commands MapSet.new([
                   "big",
                   "Big",
                   "bigg",
                   "Bigg",
                   "bigl",
                   "Bigl",
                   "biggl",
                   "Biggl",
                   "bigr",
                   "Bigr",
                   "biggr",
                   "Biggr"
                 ])

  @plain_wrappers MapSet.new([
                    "emph",
                    "mathcal",
                    "mathbf",
                    "mathfrak",
                    "mathit",
                    "mathrm",
                    "mathnormal",
                    "mathscr",
                    "mathsf",
                    "mathtt",
                    "mathup",
                    "mbox",
                    "overbrace",
                    "pmb",
                    "smash",
                    "substack",
                    "text",
                    "textbf",
                    "textit",
                    "textmd",
                    "textnormal",
                    "textrm",
                    "textsc",
                    "textsf",
                    "textsl",
                    "texttt",
                    "textup",
                    "underbrace",
                    "bm",
                    "boldsymbol"
                  ])

  # --- api ---

  @typedoc "Rendering options: `display: true` stacks fractions and operator limits."
  @type options :: [display: boolean()]

  @doc """
  Render `source` as terminal-friendly Unicode math, or `nil` when the
  expression is unsupported or malformed (the caller falls back to the raw
  source, like pi).

  ## Options

    * `:display` — stack fractions and operator limits vertically for display
      math (default false, pi's `RenderLatexOptions.display`)
  """
  @spec render(String.t(), options()) :: String.t() | nil
  def render(source, opts \\ []) do
    display = Keyword.get(opts, :display, false)

    p = %{
      source: source,
      nodes: %{},
      node_count: 0,
      display: display,
      pos: 0,
      supported: true,
      stack_fractions: true,
      script_depth: 0
    }

    {rendered, p} = parse_sequence(p, nil)

    if p.supported and p.pos == byte_size(source) do
      rendered = normalize_output(rendered)

      if map_size(p.nodes) == 0 do
        String.replace(rendered, @protected_space, " ")
      else
        render_layout_output(rendered, p.nodes)
      end
    end
  end

  # pi drops the shared indentation of the laid-out lines and turns the
  # protected spaces back into real ones.
  defp render_layout_output(rendered, nodes) do
    layout = render_layout(rendered, nodes)

    indentation =
      layout.lines
      |> Enum.filter(&(String.trim(&1) != ""))
      |> Enum.map(&(String.length(&1) - String.length(String.trim_leading(&1))))
      |> Enum.min(fn -> nil end)

    if indentation == nil do
      ""
    else
      lines =
        Enum.map(layout.lines, fn line ->
          line |> String.slice(indentation, String.length(line)) |> String.trim_trailing()
        end)

      lines
      |> Enum.join("\n")
      |> String.trim_trailing()
      |> String.replace(@protected_space, " ")
    end
  end

  # --- characters and helpers ---

  defp cp_at(%{pos: pos, source: source}) when pos >= byte_size(source), do: nil

  defp cp_at(%{pos: pos, source: source}) do
    case String.next_codepoint(binary_part(source, pos, byte_size(source) - pos)) do
      {cp, _rest} -> cp
      nil -> nil
    end
  end

  defp advance(p, cp), do: %{p | pos: p.pos + byte_size(cp)}

  defp whitespace?(cp), do: Regex.match?(~r/^\s$/u, cp)
  defp letter?(cp), do: Regex.match?(~r/^[A-Za-z]$/, cp)
  defp space_or_tab?(cp), do: cp in [" ", "\t"]

  defp replace_characters(value, replacements) do
    replace_characters(value, replacements, [])
  end

  defp replace_characters("", _replacements, acc),
    do: acc |> Enum.reverse() |> IO.iodata_to_binary()

  defp replace_characters(value, replacements, acc) do
    case String.next_codepoint(value) do
      nil ->
        acc |> Enum.reverse() |> IO.iodata_to_binary()

      {character, rest} ->
        case Map.get(replacements, character) do
          nil -> nil
          replacement -> replace_characters(rest, replacements, [replacement | acc])
        end
    end
  end

  # pi counts one *code point* here (Array.from), so a combining sequence is
  # not one character.
  defp single_codepoint?(value), do: match?({_codepoint, ""}, String.next_codepoint(value))

  defp normalize_script_value(value) do
    value |> String.trim() |> String.replace(~r/\s*([=+-])\s*/u, "\\1")
  end

  defp format_unicode_script(value, kind) do
    replacements = if kind == :sub, do: @subscripts, else: @superscripts
    replace_characters(normalize_script_value(value), replacements)
  end

  defp format_script(value, kind) do
    value = normalize_script_value(value)

    case format_unicode_script(value, kind) do
      nil ->
        prefix = if kind == :sub, do: "_", else: "^"

        if single_codepoint?(value) or (kind == :sub and Regex.match?(~r/^[A-Za-z]+$/, value)) do
          prefix <> value
        else
          prefix <> "(" <> value <> ")"
        end

      unicode ->
        unicode
    end
  end

  defp format_fraction(numerator, denominator) do
    numerator = String.trim(numerator)
    denominator = String.trim(denominator)

    simple_numerator = Regex.match?(~r/^[\p{L}\p{N}.]+$/u, numerator)

    simple_denominator =
      Regex.match?(~r/^[\p{N}.]+$/u, denominator) or single_codepoint?(denominator)

    num = if(simple_numerator, do: numerator, else: "(" <> numerator <> ")")
    den = if(simple_denominator, do: denominator, else: "(" <> denominator <> ")")
    num <> "/" <> den
  end

  defp format_root(value, symbol \\ "√") do
    value = String.trim(value)

    if Regex.match?(~r/^[\p{L}\p{N}.]+$/u, value) do
      symbol <> value
    else
      symbol <> "(" <> value <> ")"
    end
  end

  defp normalize_output(value) do
    value
    |> String.replace(@named_operator_left_pattern, " ")
    |> String.replace(@named_operator_start, "")
    |> String.replace(@named_operator_right_pattern, " ")
    |> String.replace(@named_operator_end, "")
    |> String.split("\n")
    |> Enum.with_index()
    |> Enum.map(fn {line, _index} ->
      line |> String.replace(~r/[ \t]+/u, " ") |> String.trim()
    end)
    |> drop_outer_empty_lines()
    |> Enum.join("\n")
    |> String.trim()
  end

  # pi keeps blank lines that are strictly inside the value and drops the
  # leading/trailing ones.
  defp drop_outer_empty_lines(lines) do
    last = length(lines) - 1

    lines
    |> Enum.with_index()
    |> Enum.filter(fn {line, index} -> line != "" or (index > 0 and index < last) end)
    |> Enum.map(&elem(&1, 0))
  end

  # --- layout nodes ---

  defp push_node(p, node) do
    index = p.node_count
    {index, %{p | nodes: Map.put(p.nodes, index, node), node_count: index + 1}}
  end

  defp marker(index), do: @layout_marker_start <> Integer.to_string(index) <> @layout_marker_end

  defp trailing_marker(marker_index) do
    case Regex.run(@trailing_layout_marker_pattern, marker_index, return: :index) do
      [{start, _len}, {group_start, group_len}] ->
        index = binary_part(marker_index, group_start, group_len)
        {start, String.to_integer(index)}

      _ ->
        nil
    end
  end

  defp marker_matches(line) do
    @layout_marker_pattern
    |> Regex.scan(line, return: :index)
    |> Enum.map(fn [{start, len}, {group_start, group_len}] ->
      {start, len, String.to_integer(binary_part(line, group_start, group_len))}
    end)
  end

  # The "." after a matrix marker joins the matrix's last line (pi mutates the
  # matrix node in place).
  defp append_to_matrix(p, index, text) do
    case Map.get(p.nodes, index) do
      %{type: :matrix, lines: lines} = node ->
        last = length(lines) - 1
        updated = %{node | lines: List.update_at(lines, last, &(&1 <> text))}
        {updated, %{p | nodes: Map.put(p.nodes, index, updated)}}

      _ ->
        {nil, p}
    end
  end

  # --- layout ---

  defp pad_layout_line(line, width, centered \\ false) do
    padding = max(0, width - visible_width(line))
    left = if centered, do: div(padding, 2), else: 0

    String.duplicate(" ", left) <> line <> String.duplicate(" ", padding - left)
  end

  defp join_layouts([]), do: %{lines: [""], width: 0, baseline: 0}

  defp join_layouts(layouts) do
    baseline = layouts |> Enum.map(& &1.baseline) |> Enum.max()
    below = layouts |> Enum.map(&(length(&1.lines) - &1.baseline - 1)) |> Enum.max()
    height = baseline + below + 1

    # Each layout's rows are aligned to the shared baseline grid, so the rows
    # can be zipped instead of indexed (pi walks rows and indexes each layout).
    aligned =
      Enum.map(layouts, fn layout ->
        above = List.duplicate("", baseline - layout.baseline)
        below_count = height - (baseline - layout.baseline) - length(layout.lines)
        above ++ layout.lines ++ List.duplicate("", below_count)
      end)

    lines =
      aligned
      |> Enum.zip()
      |> Enum.map(fn row ->
        row
        |> Tuple.to_list()
        |> Enum.zip(layouts)
        |> Enum.map_join(fn {text, layout} -> pad_layout_line(text, layout.width) end)
        |> String.trim_trailing()
      end)

    width = Enum.reduce(layouts, 0, fn layout, acc -> acc + layout.width end)
    %{lines: lines, width: width, baseline: baseline}
  end

  defp render_layout(source, nodes) do
    line_layouts = Enum.map(String.split(source, "\n"), &render_source_line(&1, nodes))

    first_baseline =
      case line_layouts do
        [] -> 0
        [first | _rest] -> first.baseline
      end

    rendered_lines = Enum.flat_map(line_layouts, & &1.lines)
    width = Enum.reduce(rendered_lines, 0, fn line, acc -> max(acc, visible_width(line)) end)

    %{lines: rendered_lines, width: width, baseline: first_baseline}
  end

  defp render_source_line(source_line, nodes) do
    {layouts, position, previous_node} =
      source_line
      |> marker_matches()
      |> Enum.reduce({[], 0, nil}, fn {index, length, marker_index},
                                      {layouts, position, previous_node} ->
        case Map.get(nodes, marker_index) do
          nil ->
            {layouts, position, previous_node}

          node ->
            # layouts accumulate reversed: the text before the marker goes in
            # first, so the marker's own layout ends up after it
            {layouts, _end_position, _previous} =
              maybe_push_text(layouts, source_line, position, index, previous_node, node)

            {[layout_for_node(node, nodes) | layouts], index + length, node}
        end
      end)

    layouts =
      case trailing_layout_text(source_line, position, previous_node) do
        nil ->
          layouts

        text ->
          [%{lines: [text], width: visible_width(text), baseline: 0} | layouts]
      end

    join_layouts(Enum.reverse(layouts))
  end

  defp trailing_layout_text(source_line, position, previous_node) do
    if position < byte_size(source_line) do
      sliced = binary_part(source_line, position, byte_size(source_line) - position)
      trimmed = if previous_node, do: String.trim_leading(sliced), else: sliced

      if previous_node != nil and previous_node.type == :matrix and String.match?(sliced, ~r/^\s/) do
        " " <> trimmed
      else
        trimmed
      end
    end
  end

  # The text between two layout markers (pi trims it depending on the
  # neighbouring nodes).
  defp maybe_push_text(layouts, source_line, position, index, previous_node, node) do
    if index > position do
      sliced = binary_part(source_line, position, index - position)
      leading_trimmed = if previous_node, do: String.trim_leading(sliced), else: sliced
      trimmed = String.trim_trailing(leading_trimmed)

      preserve_leading =
        previous_node != nil and previous_node.type == :matrix and String.match?(sliced, ~r/^\s/)

      preserve_trailing = node.type == :matrix and String.match?(sliced, ~r/\s$/)

      text =
        cond do
          trimmed != "" ->
            if(preserve_leading, do: " ", else: "") <>
              trimmed <> if(preserve_trailing, do: " ", else: "")

          preserve_leading or preserve_trailing ->
            " "

          true ->
            ""
        end

      {[%{lines: [text], width: visible_width(text), baseline: 0} | layouts], index, node}
    else
      {layouts, position, previous_node}
    end
  end

  defp layout_for_node(%{type: :fraction} = node, nodes) do
    numerator = render_layout(node.numerator, nodes)
    denominator = render_layout(node.denominator, nodes)
    content_width = Enum.max([numerator.width, denominator.width, 1])
    width = content_width + 2

    lines =
      Enum.map(numerator.lines, &pad_layout_line(&1, width, true)) ++
        [" " <> String.duplicate("─", content_width) <> " "] ++
        Enum.map(denominator.lines, &pad_layout_line(&1, width, true))

    %{lines: lines, width: width, baseline: length(numerator.lines)}
  end

  defp layout_for_node(%{type: :operator} = node, _nodes) do
    content_width =
      Enum.max([
        visible_width(node.operator),
        if(node.lower == nil, do: 0, else: visible_width(node.lower)),
        if(node.upper == nil, do: 0, else: visible_width(node.upper))
      ])

    lines =
      if(node.upper == nil,
        do: [],
        else: [pad_layout_line(node.upper, content_width, true) <> " "]
      ) ++
        [pad_layout_line(node.operator, content_width, true) <> " "] ++
        if(node.lower == nil,
          do: [],
          else: [pad_layout_line(node.lower, content_width, true) <> " "]
        )

    %{lines: lines, width: content_width + 1, baseline: if(node.upper == nil, do: 0, else: 1)}
  end

  defp layout_for_node(%{type: :script} = node, nodes) do
    upper = if node.upper == nil, do: nil, else: render_layout(node.upper, nodes)
    lower = if node.lower == nil, do: nil, else: render_layout(node.lower, nodes)

    width =
      Enum.max([
        if(upper == nil, do: 0, else: upper.width),
        if(lower == nil, do: 0, else: lower.width)
      ])

    lines =
      if(upper == nil, do: [], else: Enum.map(upper.lines, &pad_layout_line(&1, width))) ++
        [String.duplicate(" ", width)] ++
        if(lower == nil, do: [], else: Enum.map(lower.lines, &pad_layout_line(&1, width)))

    %{lines: lines, width: width, baseline: if(upper == nil, do: 0, else: length(upper.lines))}
  end

  defp layout_for_node(%{type: :matrix} = node, _nodes) do
    width = node.lines |> Enum.map(&visible_width/1) |> Enum.max(fn -> 0 end)

    %{
      lines: Enum.map(node.lines, &pad_layout_line(&1, width)),
      width: width,
      baseline: node.baseline
    }
  end

  # --- parser ---

  defp parse_sequence(p, end_char) do
    do_parse_sequence(p, end_char, "")
  end

  defp do_parse_sequence(%{pos: pos, source: source} = p, end_char, acc)
       when pos >= byte_size(source) do
    p = if end_char, do: %{p | supported: false}, else: p
    {acc, p}
  end

  defp do_parse_sequence(p, end_char, acc) do
    cp = cp_at(p)

    cond do
      end_char != nil and cp == end_char ->
        {acc, advance(p, cp)}

      cp == "}" ->
        {acc, %{p | supported: false}}

      cp == "{" ->
        {inner, p} = parse_sequence(advance(p, cp), "}")
        do_parse_sequence(p, end_char, acc <> inner)

      cp == "\\" ->
        {command, p} = parse_command(p)
        do_parse_sequence(p, end_char, apply_command(acc, command))

      cp in ["^", "_"] ->
        acc = String.trim_trailing(acc)
        p = advance(p, cp)
        {script, p} = parse_scripts(p, cp)

        acc =
          if String.ends_with?(acc, @named_operator_end) do
            binary_part(acc, 0, byte_size(acc) - byte_size(@named_operator_end)) <>
              script <> @named_operator_end
          else
            acc <> script
          end

        do_parse_sequence(p, end_char, acc)

      whitespace?(cp) ->
        {space, p} = parse_whitespace(p)
        do_parse_sequence(p, end_char, acc <> space)

      cp in ["=", "<", ">"] ->
        do_parse_sequence(advance(p, cp), end_char, String.trim_trailing(acc) <> " " <> cp <> " ")

      cp == "&" ->
        do_parse_sequence(advance(p, cp), end_char, acc)

      cp == "~" ->
        do_parse_sequence(advance(p, cp), end_char, acc <> " ")

      cp == "." ->
        case trailing_marker(acc) do
          {_start, index} ->
            case append_to_matrix(p, index, cp) do
              {nil, p} ->
                do_parse_sequence(advance(p, cp), end_char, acc <> cp)

              {_node, p} ->
                do_parse_sequence(advance(p, cp), end_char, acc)
            end

          nil ->
            do_parse_sequence(advance(p, cp), end_char, acc <> cp)
        end

      true ->
        do_parse_sequence(advance(p, cp), end_char, acc <> cp)
    end
  end

  # A negative space eats the trailing space (and a pending named-operator
  # terminator) instead of adding anything.
  defp apply_command(acc, command) do
    if command == @negative_space do
      acc = String.trim_trailing(acc)

      if String.ends_with?(acc, @named_operator_end) do
        binary_part(acc, 0, byte_size(acc) - byte_size(@named_operator_end))
      else
        acc
      end
    else
      acc <> command
    end
  end

  defp parse_whitespace(p) do
    case cp_at(p) do
      cp when is_binary(cp) ->
        if whitespace?(cp) do
          parse_whitespace(advance(p, cp))
        else
          {" ", p}
        end

      nil ->
        {" ", p}
    end
  end

  defp parse_scripts(p, initial_marker) do
    {scripts, order, p} = parse_script_marker(p, initial_marker, %{}, [])

    {next_marker, peeked} = peek_script_marker(p)

    {scripts, order, p} =
      if next_marker != nil and next_marker != initial_marker do
        parse_script_marker(advance(peeked, next_marker), next_marker, scripts, order)
      else
        {scripts, order, p}
      end

    sub = Map.get(scripts, :sub)
    sup = Map.get(scripts, :sup)
    sub_unicode = if sub == nil, do: nil, else: format_unicode_script(sub, :sub)
    sup_unicode = if sup == nil, do: nil, else: format_unicode_script(sup, :sup)

    can_use_layout =
      Enum.all?([sub, sup], fn
        nil ->
          true

        value ->
          not (String.contains?(value, "/") or
                 (not String.contains?(value, @layout_marker_start) and String.length(value) > 1 and
                    not Regex.match?(~r/[A-Z*∗]/u, value)))
      end)

    needs_layout =
      p.display and can_use_layout and
        (p.script_depth > 0 or (sub != nil and sub_unicode == nil) or
           (sup != nil and sup_unicode == nil))

    if needs_layout do
      {index, p} =
        push_node(p, %{
          type: :script,
          lower: if(sub == nil, do: nil, else: normalize_output(sub)),
          upper: if(sup == nil, do: nil, else: normalize_output(sup))
        })

      {marker(index), p}
    else
      rendered =
        Enum.map_join(order, fn
          :sub -> sub_unicode || format_script(sub || "", :sub)
          :sup -> sup_unicode || format_script(sup || "", :sup)
        end)

      {rendered, p}
    end
  end

  defp parse_script_marker(p, marker, scripts, order) do
    kind = if marker == "_", do: :sub, else: :sup
    p = %{p | script_depth: p.script_depth + 1}
    {value, p} = parse_required_argument(p, false)
    p = %{p | script_depth: p.script_depth - 1}

    {Map.put(scripts, kind, value), order ++ [kind], p}
  end

  defp peek_script_marker(p) do
    case cp_at(p) do
      cp when is_binary(cp) ->
        if space_or_tab?(cp) do
          peek_script_marker(advance(p, cp))
        else
          {if(cp in ["^", "_"], do: cp, else: nil), p}
        end

      nil ->
        {nil, p}
    end
  end

  defp parse_command(p) do
    p = %{p | pos: p.pos + 1}

    case cp_at(p) do
      nil ->
        {"", %{p | supported: false}}

      "\n" ->
        {" ", advance(p, "\n")}

      "\r" ->
        p = advance(p, "\r")

        p =
          case cp_at(p) do
            "\n" -> advance(p, "\n")
            _ -> p
          end

        {" ", p}

      cp ->
        {command, p} =
          if letter?(cp) do
            read_command_name(p, "")
          else
            {cp, advance(p, cp)}
          end

        dispatch_command(p, command)
    end
  end

  defp read_command_name(p, acc) do
    case cp_at(p) do
      cp when is_binary(cp) ->
        if letter?(cp) do
          read_command_name(advance(p, cp), acc <> cp)
        else
          {acc, p}
        end

      nil ->
        {acc, p}
    end
  end

  defp dispatch_command(p, "\\"), do: {"\n", p}

  defp dispatch_command(p, command) when command in ["", "}", "{"] do
    {command, p}
  end

  defp dispatch_command(p, command) do
    cond do
      MapSet.member?(@spacing_commands, command) ->
        {" ", p}

      MapSet.member?(@negative_spacing_commands, command) ->
        {@negative_space, p}

      MapSet.member?(@font_switch_commands, command) ->
        {_skipped, p} = skip_spaces_and_tabs(p)
        {"", p}

      MapSet.member?(@ignored_commands, command) ->
        {"", p}

      command in ["{", "}", "$", "%", "#", "_", "&"] ->
        {command, p}

      command == "|" ->
        {"‖", p}

      command == "not" ->
        {value, p} = parse_required_argument(p, false)
        value = String.trim(value)

        case Map.get(@negated_symbols, value) do
          nil ->
            case String.next_codepoint(value) do
              nil ->
                {"", %{p | supported: false}}

              {first, rest} ->
                {" " <> first <> "\u0338" <> rest <> " ", p}
            end

          negated ->
            {" " <> negated <> " ", p}
        end

      MapSet.member?(@limit_operators, command) ->
        parse_operator(p, command, :bracket, true, true)

      Map.get(@symbols, command) != nil ->
        symbol = Map.fetch!(@symbols, command)

        if MapSet.member?(@display_limit_symbols, command) do
          parse_operator(p, symbol, :script, true)
        else
          if command in ["cdot", "times"] or MapSet.member?(@relation_commands, command) do
            {" " <> symbol <> " ", p}
          else
            {symbol, p}
          end
        end

      MapSet.member?(@named_operators, command) ->
        {@named_operator_start <> command <> @named_operator_end, p}

      MapSet.member?(@size_commands, command) ->
        {"", p}

      command in ["left", "middle", "right"] ->
        case cp_at(p) do
          "." -> {"", advance(p, ".")}
          _ -> {"", p}
        end

      command in ["frac", "dfrac", "tfrac"] ->
        should_stack = p.display and p.stack_fractions and command != "tfrac"
        {numerator, p} = parse_required_argument(p, not should_stack)
        {denominator, p} = parse_required_argument(p, not should_stack)

        if should_stack do
          {index, p} =
            push_node(p, %{
              type: :fraction,
              numerator: normalize_output(numerator),
              denominator: normalize_output(denominator)
            })

          {marker(index), p}
        else
          {format_fraction(numerator, denominator), p}
        end

      command == "sqrt" ->
        {degree, p} = parse_optional_argument(p)
        degree = if degree == nil, do: nil, else: String.trim(degree)
        {value, p} = parse_required_argument(p)

        cond do
          degree == nil or degree == "2" -> {format_root(value), p}
          degree == "3" -> {format_root(value, "∛"), p}
          degree == "4" -> {format_root(value, "∜"), p}
          true -> {format_script(degree, :sup) <> format_root(value), p}
        end

      command in ["boxed", "fbox"] ->
        {value, p} = parse_required_argument(p)
        {"[" <> String.trim(value) <> "]", p}

      command in ["binom", "dbinom", "tbinom"] ->
        {numerator, p} = parse_required_argument(p)
        {denominator, p} = parse_required_argument(p)
        {"(" <> numerator <> " choose " <> denominator <> ")", p}

      Map.get(@accents, command) != nil ->
        accent = Map.fetch!(@accents, command)
        {value, p} = parse_required_argument(p)

        if single_codepoint?(value) do
          {value <> accent, p}
        else
          {command <> "(" <> value <> ")", p}
        end

      command == "mathbb" ->
        {value, p} = parse_required_argument(p)

        rendered =
          value
          |> String.to_charlist()
          |> Enum.map_join(fn char ->
            char = <<char::utf8>>
            Map.get(@blackboard, char, char)
          end)

        {rendered, p}

      command == "operatorname" ->
        {starred, p} =
          case cp_at(p) do
            "*" -> {true, advance(p, "*")}
            _ -> {false, p}
          end

        {operator, p} = parse_required_argument(p, true)

        parse_operator(
          p,
          operator |> normalize_output() |> String.trim(),
          :bracket,
          starred,
          true
        )

      command in ["mod", "bmod"] ->
        {" mod ", p}

      command in ["pmod", "pod"] ->
        {value, p} = parse_required_argument(p)
        value = String.trim(value)

        if command == "pmod" do
          {" (mod " <> value <> ")", p}
        else
          {" (" <> value <> ")", p}
        end

      command in ["overset", "stackrel"] ->
        {upper, p} = parse_required_argument(p)
        {value, p} = parse_required_argument(p)
        {String.trim(value) <> format_script(upper, :sup), p}

      command == "underset" ->
        {lower, p} = parse_required_argument(p)
        {value, p} = parse_required_argument(p)
        {String.trim(value) <> format_script(lower, :sub), p}

      MapSet.member?(@plain_wrappers, command) ->
        {value, p} = parse_required_argument(p)

        if String.starts_with?(command, "text") or command == "mbox" do
          {value, p}
        else
          {String.trim(value), p}
        end

      command == "begin" ->
        parse_environment(p)

      command == "end" ->
        {"", %{p | supported: false}}

      true ->
        {"\\" <> command, %{p | supported: false}}
    end
  end

  defp skip_spaces_and_tabs(p) do
    case cp_at(p) do
      cp when is_binary(cp) ->
        if space_or_tab?(cp) do
          skip_spaces_and_tabs(advance(p, cp))
        else
          {nil, p}
        end

      nil ->
        {nil, p}
    end
  end

  defp parse_operator(p, operator, inline_lower_style, display_limits, spaced \\ false) do
    {use_display_limits, p} = parse_limits_modifier(p, display_limits)
    {lower, upper, p} = parse_operator_scripts(p, nil, nil)

    if p.display and use_display_limits and (lower != nil or upper != nil) do
      {index, p} =
        push_node(p, %{type: :operator, operator: operator, lower: lower, upper: upper})

      {marker(index), p}
    else
      lower_text =
        cond do
          lower == nil -> ""
          inline_lower_style == :bracket -> "[" <> lower <> "]"
          true -> format_script(lower, :sub)
        end

      upper_text = if upper == nil, do: "", else: format_script(upper, :sup)
      rendered = operator <> lower_text <> upper_text
      {if(spaced, do: " " <> rendered <> " ", else: rendered), p}
    end
  end

  defp parse_limits_modifier(p, display_limits) do
    {_skipped, p} = skip_spaces_and_tabs(p)
    rest = binary_part(p.source, p.pos, byte_size(p.source) - p.pos)

    case Regex.run(~r/^\\(limits|nolimits)(?![A-Za-z])/, rest, return: :index) do
      [{start, len}, {group_start, group_len}] ->
        modifier = binary_part(rest, group_start, group_len)
        {modifier == "limits", %{p | pos: p.pos + start + len}}

      _ ->
        {display_limits, p}
    end
  end

  defp parse_operator_scripts(p, lower, upper) do
    case script_marker_at(p) do
      nil ->
        {lower, upper, p}

      {marker, position} ->
        p = %{p | pos: position + 1}
        {value, p} = parse_required_argument(p, false)
        value = String.replace(normalize_output(value), " ", "")

        if marker == "_" do
          if lower != nil do
            parse_operator_scripts(%{p | supported: false}, lower, upper)
          else
            parse_operator_scripts(p, value, upper)
          end
        else
          if upper != nil do
            parse_operator_scripts(%{p | supported: false}, lower, upper)
          else
            parse_operator_scripts(p, lower, value)
          end
        end
    end
  end

  defp script_marker_at(p) do
    case cp_at(p) do
      cp when is_binary(cp) ->
        cond do
          space_or_tab?(cp) -> script_marker_at(advance(p, cp))
          cp in ["_", "^"] -> {cp, p.pos}
          true -> nil
        end

      nil ->
        nil
    end
  end

  defp parse_optional_argument(p) do
    {_skipped, p} = skip_spaces_and_tabs(p)

    case cp_at(p) do
      "[" ->
        rest = binary_part(p.source, p.pos + 1, byte_size(p.source) - p.pos - 1)

        case :binary.match(rest, "]") do
          :nomatch ->
            {nil, %{p | supported: false}}

          {start, _len} ->
            value = binary_part(rest, 0, start)
            p = %{p | pos: p.pos + 1 + start + 1}
            render_nested(p, value, true)
        end

      _ ->
        {nil, p}
    end
  end

  defp parse_required_argument(p, stack_fractions \\ true) do
    previous = p.stack_fractions
    p = %{p | stack_fractions: previous and stack_fractions}
    {value, p} = parse_required_argument_value(p)
    {value, %{p | stack_fractions: previous}}
  end

  defp parse_required_argument_value(p) do
    {_skipped, p} = skip_whitespace(p)

    case cp_at(p) do
      nil ->
        {"", %{p | supported: false}}

      "{" ->
        parse_sequence(advance(p, "{"), "}")

      "\\" ->
        parse_command(p)

      cp ->
        {cp, advance(p, cp)}
    end
  end

  defp skip_whitespace(p) do
    case cp_at(p) do
      cp when is_binary(cp) ->
        if whitespace?(cp) do
          skip_whitespace(advance(p, cp))
        else
          {nil, p}
        end

      nil ->
        {nil, p}
    end
  end

  defp split_environment_rows(body), do: Regex.split(@environment_row_pattern, body)

  defp parse_environment(p) do
    case read_raw_group(p) do
      {nil, p} ->
        {"", p}

      {environment, p} ->
        end_marker = "\\end{" <> environment <> "}"

        case :binary.match(p.source, end_marker, scope: {p.pos, byte_size(p.source) - p.pos}) do
          :nomatch ->
            {"", %{p | supported: false}}

          {start, len} ->
            body = binary_part(p.source, p.pos, start - p.pos)
            p = %{p | pos: start + len}
            render_environment(p, environment, body)
        end
    end
  end

  defp read_raw_group(p) do
    {_skipped, p} = skip_spaces_and_tabs(p)

    case cp_at(p) do
      "{" ->
        p = advance(p, "{")
        scan_raw_group(p, p.pos, 1)

      _ ->
        {nil, %{p | supported: false}}
    end
  end

  defp scan_raw_group(p, start, depth) do
    case cp_at(p) do
      nil ->
        {nil, %{p | supported: false}}

      "\\" ->
        p = advance(p, "\\")

        p =
          case cp_at(p) do
            nil -> p
            cp -> advance(p, cp)
          end

        scan_raw_group(p, start, depth)

      "{" ->
        scan_raw_group(advance(p, "{"), start, depth + 1)

      "}" ->
        if depth == 1 do
          {binary_part(p.source, start, p.pos - start), %{p | pos: p.pos + 1}}
        else
          scan_raw_group(advance(p, "}"), start, depth - 1)
        end

      cp ->
        scan_raw_group(advance(p, cp), start, depth)
    end
  end

  defp render_environment(p, environment, body) do
    cond do
      environment in ["equation", "equation*", "displaymath"] ->
        {rendered, p} = render_nested(p, body, true)
        {String.trim(rendered), p}

      environment in [
        "aligned",
        "align",
        "align*",
        "alignedat",
        "alignat",
        "alignat*",
        "gather",
        "gathered",
        "multline",
        "multline*",
        "split"
      ] ->
        aligned_at = environment in ["alignedat", "alignat", "alignat*"]

        aligned_body =
          if aligned_at, do: Regex.replace(~r/^\s*\{[^}]*\}/u, body, ""), else: body

        {rows, p} =
          aligned_body
          |> split_environment_rows()
          |> Enum.map_reduce(p, fn row, p ->
            cells = String.split(row, "&")

            source =
              if aligned_at do
                cells |> Enum.chunk_every(2) |> Enum.map_join(" ", &Enum.join/1)
              else
                Enum.join(cells)
              end

            {rendered, p} = render_nested(p, source, true)
            {String.trim(rendered), p}
          end)

        {rows |> Enum.reject(&(&1 == "")) |> Enum.join("\n"), p}

      environment in ["cases", "cases*"] ->
        render_cases(p, body)

      environment in [
        "array",
        "matrix",
        "smallmatrix",
        "pmatrix",
        "bmatrix",
        "Bmatrix",
        "vmatrix",
        "Vmatrix"
      ] ->
        matrix_body =
          if environment == "array", do: Regex.replace(~r/^\s*\{[^}]*\}/u, body, ""), else: body

        render_matrix(p, environment, matrix_body)

      true ->
        {body, %{p | supported: false}}
    end
  end

  defp render_environment_cells(p, body) do
    body
    |> split_environment_rows()
    |> Enum.map_reduce(p, fn row, p ->
      row
      |> String.split("&")
      |> Enum.map_reduce(p, fn cell, p ->
        {rendered, p} = render_nested(p, cell, false)
        {String.trim(rendered), p}
      end)
    end)
  end

  defp render_cases(p, body) do
    {rows, p} = render_environment_cells(p, body)

    # Each row is padded to `[value, condition | extra]` so the cells can be
    # destructured instead of indexed.
    rows =
      rows
      |> Enum.reject(fn row -> not Enum.any?(row, &(&1 != "")) end)
      |> Enum.map(fn row -> row ++ [""] end)

    value_width =
      Enum.reduce(rows, 0, fn [value | _rest], acc ->
        max(acc, value |> String.replace(~r/,\s*$/, "") |> visible_width())
      end)

    contents =
      Enum.map(rows, fn
        [value | [condition | _rest]] ->
          value = String.replace(value, ~r/,\s*$/, "")

          if condition == "" do
            value
          else
            prefix =
              if Regex.match?(~r/^(?:if|when|for|otherwise)\b/i, condition), do: " ", else: " if "

            value <>
              String.duplicate(@protected_space, value_width - visible_width(value)) <>
              prefix <> condition
          end
      end)

    case contents do
      [] ->
        {"", p}

      [only] ->
        {"⎧ " <> only, p}

      _ ->
        middle = div(length(contents), 2)

        visual_rows =
          if rem(length(contents), 2) == 0 do
            List.insert_at(contents, middle, nil)
          else
            contents
          end

        last = length(visual_rows) - 1

        lines =
          visual_rows
          |> Enum.with_index()
          |> Enum.map(fn {content, index} ->
            delimiter =
              cond do
                index == 0 -> "⎧"
                index == last -> "⎩"
                true -> "⎨"
              end

            if content == nil, do: delimiter, else: delimiter <> " " <> content
          end)

        {index, p} = push_node(p, %{type: :matrix, lines: lines, baseline: middle})
        {marker(index), p}
    end
  end

  defp render_matrix(p, environment, body) do
    {matrix, p} = render_environment_cells(p, body)

    matrix = Enum.reject(matrix, fn row -> not Enum.any?(row, &(&1 != "")) end)
    column_count = matrix |> Enum.map(&length/1) |> Enum.max(fn -> 0 end)

    # Rows are padded to the column count so the columns can be zipped instead
    # of indexed.
    matrix = Enum.map(matrix, fn row -> row ++ List.duplicate("", column_count - length(row)) end)

    column_widths =
      matrix
      |> Enum.zip()
      |> Enum.map(fn column ->
        column |> Tuple.to_list() |> Enum.map(&visible_width/1) |> Enum.max(fn -> 0 end)
      end)

    rows =
      Enum.map(matrix, fn row ->
        row
        |> Enum.zip(column_widths)
        |> Enum.map_join(" │ ", fn {cell, width} ->
          cell <> String.duplicate(@protected_space, max(0, width - visible_width(cell)))
        end)
      end)

    lines =
      if environment in ["array", "matrix", "smallmatrix"] do
        {:ok, rows}
      else
        case Map.get(@matrix_delimiters, environment) do
          nil -> {:unsupported, Enum.join(rows, "\n")}
          {tl, tr, ml, mr, bl, br} -> {:ok, matrix_delimited_rows(rows, tl, tr, ml, mr, bl, br)}
        end
      end

    case lines do
      {:unsupported, joined} ->
        {joined, %{p | supported: false}}

      {:ok, []} ->
        {"", p}

      {:ok, [only]} ->
        {only, p}

      {:ok, lines} ->
        {index, p} = push_node(p, %{type: :matrix, lines: lines, baseline: 0})
        {marker(index), p}
    end
  end

  defp matrix_delimited_rows(rows, tl, tr, ml, mr, bl, br) do
    last = length(rows) - 1

    rows
    |> Enum.with_index()
    |> Enum.map(fn {row, index} ->
      left = if index == 0, do: tl, else: if(index == last, do: bl, else: ml)
      right = if index == 0, do: tr, else: if(index == last, do: br, else: mr)
      left <> " " <> row <> " " <> right
    end)
  end

  # A nested parse shares the layout nodes but has its own position, success
  # flag and script depth (pi constructs a new parser over the same node array).
  defp render_nested(p, source, stack_fractions) do
    inner = %{
      p
      | source: source,
        pos: 0,
        supported: true,
        stack_fractions: true,
        script_depth: 0,
        display: p.display and stack_fractions
    }

    {rendered, inner} = parse_sequence(inner, nil)

    if inner.supported and inner.pos == byte_size(source) do
      {normalize_output(rendered), %{p | nodes: inner.nodes}}
    else
      {source, %{p | supported: false, nodes: inner.nodes}}
    end
  end
end
