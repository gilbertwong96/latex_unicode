defmodule LatexUnicodeTest do
  use ExUnit.Case, async: true

  alias LatexUnicode

  # Cases ported from pi-tui's test/latex.test.ts (packages/tui).
  describe "Jacobian conjecture session using dollar delimiters" do
    test "\\mathbb{C}^3 \\to \\mathbb{C}^3" do
      assert LatexUnicode.render("\\mathbb{C}^3 \\to \\mathbb{C}^3") == "ℂ³ → ℂ³"
    end

    test "\\{3x+2y,\\; 27x^2-4z-1,\\; x(x-1)(x+1)\\} \\quad\\Rightarrow\\quad x \\in \\{0, \\pm 1\\}," do
      assert LatexUnicode.render(
               "\\{3x+2y,\\; 27x^2-4z-1,\\; x(x-1)(x+1)\\} \\quad\\Rightarrow\\quad x \\in \\{0, \\pm 1\\},"
             ) == "{3x+2y, 27x²-4z-1, x(x-1)(x+1)} ⇒ x ∈ {0, ± 1},"
    end

    test "F_1 = -\\frac{1}{4x^2}." do
      assert LatexUnicode.render("F_1 = -\\frac{1}{4x^2}.") == "F₁ = -1/(4x²)."
    end

    test "-2" do
      assert LatexUnicode.render("-2") == "-2"
    end

    test "(0,0,-1/4)" do
      assert LatexUnicode.render("(0,0,-1/4)") == "(0,0,-1/4)"
    end

    test "(1,-3/2,13/2)" do
      assert LatexUnicode.render("(1,-3/2,13/2)") == "(1,-3/2,13/2)"
    end

    test "(1,1,1)" do
      assert LatexUnicode.render("(1,1,1)") == "(1,1,1)"
    end

    test "(2,1,0)" do
      assert LatexUnicode.render("(2,1,0)") == "(2,1,0)"
    end

    test "(-1/4, 0, 0)" do
      assert LatexUnicode.render("(-1/4, 0, 0)") == "(-1/4, 0, 0)"
    end

    test "\\{(0,0,-1/4), (1,-3/2,13/2), (-1,3/2,13/2)\\}" do
      assert LatexUnicode.render("\\{(0,0,-1/4), (1,-3/2,13/2), (-1,3/2,13/2)\\}") ==
               "{(0,0,-1/4), (1,-3/2,13/2), (-1,3/2,13/2)}"
    end

    test "(2,1,1)" do
      assert LatexUnicode.render("(2,1,1)") == "(2,1,1)"
    end

    test "(7/3,-2/5,11/7)" do
      assert LatexUnicode.render("(7/3,-2/5,11/7)") == "(7/3,-2/5,11/7)"
    end

    test "\\{y - p(x),\\; q(x)\\}" do
      assert LatexUnicode.render("\\{y - p(x),\\; q(x)\\}") == "{y - p(x), q(x)}"
    end

    test "\\deg q = 3" do
      assert LatexUnicode.render("\\deg q = 3") == "deg q = 3"
    end

    test "[\\mathbb{C}(x,y,z):\\mathbb{C}(F_1,F_2,F_3)] = 3" do
      assert LatexUnicode.render("[\\mathbb{C}(x,y,z):\\mathbb{C}(F_1,F_2,F_3)] = 3") ==
               "[ℂ(x,y,z):ℂ(F₁,F₂,F₃)] = 3"
    end

    test "u = 1+xy" do
      assert LatexUnicode.render("u = 1+xy") == "u = 1+xy"
    end

    test "G = u^2 z + y^2(4+3xy)" do
      assert LatexUnicode.render("G = u^2 z + y^2(4+3xy)") == "G = u² z + y²(4+3xy)"
    end

    test "F_1 = uG" do
      assert LatexUnicode.render("F_1 = uG") == "F₁ = uG"
    end

    test "F_2 = y + 3xG" do
      assert LatexUnicode.render("F_2 = y + 3xG") == "F₂ = y + 3xG"
    end

    test "x=0" do
      assert LatexUnicode.render("x=0") == "x = 0"
    end

    test "F_2 = F_3 = 0" do
      assert LatexUnicode.render("F_2 = F_3 = 0") == "F₂ = F₃ = 0"
    end

    test "xy = -3/2" do
      assert LatexUnicode.render("xy = -3/2") == "xy = -3/2"
    end

    test "x^2 z = 13/2" do
      assert LatexUnicode.render("x^2 z = 13/2") == "x² z = 13/2"
    end

    test "\\mathbb{C}^*" do
      assert LatexUnicode.render("\\mathbb{C}^*") == "ℂ^*"
    end

    test "s \\mapsto (s,\\, -\\tfrac{3}{2s},\\, \\tfrac{13}{2s^2})" do
      assert LatexUnicode.render("s \\mapsto (s,\\, -\\tfrac{3}{2s},\\, \\tfrac{13}{2s^2})") ==
               "s ↦ (s, -3/(2s), 13/(2s²))"
    end

    test "X" do
      assert LatexUnicode.render("X") == "X"
    end

    test "p_\\pm" do
      assert LatexUnicode.render("p_\\pm") == "p_±"
    end

    test "F(-x,-y,z) = (F_1, -F_2, -F_3)" do
      assert LatexUnicode.render("F(-x,-y,z) = (F_1, -F_2, -F_3)") ==
               "F(-x,-y,z) = (F₁, -F₂, -F₃)"
    end

    test "p_0" do
      assert LatexUnicode.render("p_0") == "p₀"
    end

    test "s \\to \\infty" do
      assert LatexUnicode.render("s \\to \\infty") == "s → ∞"
    end

    test "(0,0,0)" do
      assert LatexUnicode.render("(0,0,0)") == "(0,0,0)"
    end

    test "\\Rightarrow" do
      assert LatexUnicode.render("\\Rightarrow") == "⇒"
    end

    test "\\ge 2" do
      assert LatexUnicode.render("\\ge 2") == "≥ 2"
    end

    test "\\ge 3" do
      assert LatexUnicode.render("\\ge 3") == "≥ 3"
    end

    test "1" do
      assert LatexUnicode.render("1") == "1"
    end

    test "\\mathrm{diag}(-1/2,1,1),\\quad F_{\\rm intrinsic}(\\lambda)" do
      assert LatexUnicode.render("\\mathrm{diag}(-1/2,1,1),\\quad F_{\\rm intrinsic}(\\lambda)") ==
               "diag(-1/2,1,1), F_intrinsic(λ)"
    end

    test "4+3xy" do
      assert LatexUnicode.render("4+3xy") == "4+3xy"
    end
  end

  describe "satellite calculation session using bracket delimiters" do
    test "E \\approx \\frac{0.1\\ \\text{lux}}{100\\ \\text{lm/W}} = 0.001\\ \\text{W/m}^2" do
      assert LatexUnicode.render(
               "E \\approx \\frac{0.1\\ \\text{lux}}{100\\ \\text{lm/W}} = 0.001\\ \\text{W/m}^2"
             ) ==
               "E ≈ (0.1 lux)/(100 lm/W) = 0.001 W/m²"
    end

    test "\\boxed{1\\ \\text{milliwatt per square metre}}" do
      assert LatexUnicode.render("\\boxed{1\\ \\text{milliwatt per square metre}}") ==
               "[1 milliwatt per square metre]"
    end

    test "5\\ \\text{km}^2 = 5{,}000{,}000\\ \\text{m}^2" do
      assert LatexUnicode.render("5\\ \\text{km}^2 = 5{,}000{,}000\\ \\text{m}^2") ==
               "5 km² = 5,000,000 m²"
    end

    test "P_{\\text{light}} = 0.001 \\times 5{,}000{,}000\n= \\boxed{5{,}000\\ \\text{W}}" do
      assert LatexUnicode.render(
               "P_{\\text{light}} = 0.001 \\times 5{,}000{,}000\n= \\boxed{5{,}000\\ \\text{W}}"
             ) ==
               "P_light = 0.001 × 5,000,000 = [5,000 W]"
    end

    test "P_{\\text{electric}} = 5\\ \\text{kW} \\times 0.2\n= \\boxed{1\\ \\text{kW}}" do
      assert LatexUnicode.render(
               "P_{\\text{electric}} = 5\\ \\text{kW} \\times 0.2\n= \\boxed{1\\ \\text{kW}}"
             ) ==
               "P_electric = 5 kW × 0.2 = [1 kW]"
    end

    test "\\pi(2.5\\ \\text{km})^2 = 19.6\\ \\text{km}^2" do
      assert LatexUnicode.render("\\pi(2.5\\ \\text{km})^2 = 19.6\\ \\text{km}^2") ==
               "π(2.5 km)² = 19.6 km²"
    end

    test "0.001\\ \\text{W/m}^2 \\times 19.6 \\times 10^6\\ \\text{m}^2\n\\approx \\boxed{20\\ \\text{kW optical}}" do
      assert LatexUnicode.render(
               "0.001\\ \\text{W/m}^2 \\times 19.6 \\times 10^6\\ \\text{m}^2\n\\approx \\boxed{20\\ \\text{kW optical}}"
             ) == "0.001 W/m² × 19.6 × 10⁶ m² ≈ [20 kW optical]"
    end

    test "1\\ \\text{kW} \\times \\frac{1}{3600}\\ \\text{hour}\n= \\boxed{0.28\\ \\text{Wh}}" do
      assert LatexUnicode.render(
               "1\\ \\text{kW} \\times \\frac{1}{3600}\\ \\text{hour}\n= \\boxed{0.28\\ \\text{Wh}}"
             ) == "1 kW × 1/3600 hour = [0.28 Wh]"
    end
  end

  describe "Jacobian conjecture sessions using parenthesis and bracket delimiters" do
    test "\\det\\!\\left(\\frac{\\partial(F_1,F_2,F_3)}{\\partial(x,y,z)}\\right)=-2." do
      assert LatexUnicode.render(
               "\\det\\!\\left(\\frac{\\partial(F_1,F_2,F_3)}{\\partial(x,y,z)}\\right)=-2."
             ) ==
               "det((∂(F₁,F₂,F₃))/(∂(x,y,z))) = -2."
    end

    test "\\begin{aligned}\nF(0,0,-\\tfrac14)&=(-\\tfrac14,0,0),\\\\\nF(1,-\\tfrac32,\\tfrac{13}2)&=(-\\tfrac14,0,0),\\\\\nF(-1,\\tfrac32,\\tfrac{13}2)&=(-\\tfrac14,0,0).\n\\end{aligned}" do
      assert LatexUnicode.render(
               "\\begin{aligned}\nF(0,0,-\\tfrac14)&=(-\\tfrac14,0,0),\\\\\nF(1,-\\tfrac32,\\tfrac{13}2)&=(-\\tfrac14,0,0),\\\\\nF(-1,\\tfrac32,\\tfrac{13}2)&=(-\\tfrac14,0,0).\n\\end{aligned}"
             ) ==
               "F(0,0,-1/4) = (-1/4,0,0),\nF(1,-3/2,13/2) = (-1/4,0,0),\nF(-1,3/2,13/2) = (-1/4,0,0)."
    end

    test "F=(F_1,F_2,F_3)" do
      assert LatexUnicode.render("F=(F_1,F_2,F_3)") == "F = (F₁,F₂,F₃)"
    end

    test "F" do
      assert LatexUnicode.render("F") == "F"
    end

    test "3" do
      assert LatexUnicode.render("3") == "3"
    end
  end

  describe "Jacobian matrix session using dollar delimiters" do
    test "J = \\begin{pmatrix}\n\\frac{\\partial f_1}{\\partial x} & \\frac{\\partial f_1}{\\partial y} & \\frac{\\partial f_1}{\\partial z} \\\\\n\\frac{\\partial f_2}{\\partial x} & \\frac{\\partial f_2}{\\partial y} & \\frac{\\partial f_2}{\\partial z} \\\\\n\\frac{\\partial f_3}{\\partial x} & \\frac{\\partial f_3}{\\partial y} & \\frac{\\partial f_3}{\\partial z}\n\\end{pmatrix}" do
      assert LatexUnicode.render(
               "J = \\begin{pmatrix}\n\\frac{\\partial f_1}{\\partial x} & \\frac{\\partial f_1}{\\partial y} & \\frac{\\partial f_1}{\\partial z} \\\\\n\\frac{\\partial f_2}{\\partial x} & \\frac{\\partial f_2}{\\partial y} & \\frac{\\partial f_2}{\\partial z} \\\\\n\\frac{\\partial f_3}{\\partial x} & \\frac{\\partial f_3}{\\partial y} & \\frac{\\partial f_3}{\\partial z}\n\\end{pmatrix}"
             ) ==
               "J = ⎛ (∂ f₁)/(∂ x) │ (∂ f₁)/(∂ y) │ (∂ f₁)/(∂ z) ⎞\n    ⎜ (∂ f₂)/(∂ x) │ (∂ f₂)/(∂ y) │ (∂ f₂)/(∂ z) ⎟\n    ⎝ (∂ f₃)/(∂ x) │ (∂ f₃)/(∂ y) │ (∂ f₃)/(∂ z) ⎠"
    end

    test "\\begin{aligned}\nf_1 &= (1+xy)^3 z + y^2(1+xy)(4+3xy) \\\\\nf_2 &= y + 3x(1+xy)^2 z + 3xy^2(4+3xy) \\\\\nf_3 &= 2x - 3x^2y - x^3z\n\\end{aligned}" do
      assert LatexUnicode.render(
               "\\begin{aligned}\nf_1 &= (1+xy)^3 z + y^2(1+xy)(4+3xy) \\\\\nf_2 &= y + 3x(1+xy)^2 z + 3xy^2(4+3xy) \\\\\nf_3 &= 2x - 3x^2y - x^3z\n\\end{aligned}"
             ) ==
               "f₁ = (1+xy)³ z + y²(1+xy)(4+3xy)\nf₂ = y + 3x(1+xy)² z + 3xy²(4+3xy)\nf₃ = 2x - 3x²y - x³z"
    end

    test "x, y, z" do
      assert LatexUnicode.render("x, y, z") == "x, y, z"
    end

    test "(x, y, z)" do
      assert LatexUnicode.render("(x, y, z)") == "(x, y, z)"
    end

    test "(0,\\; 0,\\; -\\tfrac14)" do
      assert LatexUnicode.render("(0,\\; 0,\\; -\\tfrac14)") == "(0, 0, -1/4)"
    end

    test "(-\\tfrac14,\\; 0,\\; 0)" do
      assert LatexUnicode.render("(-\\tfrac14,\\; 0,\\; 0)") == "(-1/4, 0, 0)"
    end

    test "(1,\\; -\\tfrac32,\\; \\tfrac{13}{2})" do
      assert LatexUnicode.render("(1,\\; -\\tfrac32,\\; \\tfrac{13}{2})") == "(1, -3/2, 13/2)"
    end

    test "(-1,\\; \\tfrac32,\\; \\tfrac{13}{2})" do
      assert LatexUnicode.render("(-1,\\; \\tfrac32,\\; \\tfrac{13}{2})") == "(-1, 3/2, 13/2)"
    end

    test "(-\\frac14, 0, 0)" do
      assert LatexUnicode.render("(-\\frac14, 0, 0)") == "(-1/4, 0, 0)"
    end

    test "F: \\mathbb{C}^3 \\to \\mathbb{C}^3" do
      assert LatexUnicode.render("F: \\mathbb{C}^3 \\to \\mathbb{C}^3") == "F: ℂ³ → ℂ³"
    end

    test "F(0,0,-\\tfrac14) = F(1,-\\tfrac32,\\tfrac{13}{2}) = F(-1,\\tfrac32,\\tfrac{13}{2}) = (-\\tfrac14, 0, 0)" do
      assert LatexUnicode.render(
               "F(0,0,-\\tfrac14) = F(1,-\\tfrac32,\\tfrac{13}{2}) = F(-1,\\tfrac32,\\tfrac{13}{2}) = (-\\tfrac14, 0, 0)"
             ) == "F(0,0,-1/4) = F(1,-3/2,13/2) = F(-1,3/2,13/2) = (-1/4, 0, 0)"
    end

    test "\\mathbb{C}^3" do
      assert LatexUnicode.render("\\mathbb{C}^3") == "ℂ³"
    end

    test "\\begin{aligned}\nf_1 &= \\frac{f_1^{\\text{ut}}(u,t)}{x^2}, \\quad\nf_2 = \\frac{f_2^{\\text{ut}}(u,t)}{x}, \\quad\nf_3 = x\\,(2 - 3u - t)\n\\end{aligned}" do
      assert LatexUnicode.render(
               "\\begin{aligned}\nf_1 &= \\frac{f_1^{\\text{ut}}(u,t)}{x^2}, \\quad\nf_2 = \\frac{f_2^{\\text{ut}}(u,t)}{x}, \\quad\nf_3 = x\\,(2 - 3u - t)\n\\end{aligned}"
             ) == "f₁ = (f₁ᵘᵗ(u,t))/(x²), f₂ = (f₂ᵘᵗ(u,t))/x, f₃ = x (2 - 3u - t)"
    end

    test "\\det J_F" do
      assert LatexUnicode.render("\\det J_F") == "det J_F"
    end

    test "(-\\tfrac14, 0, 0)" do
      assert LatexUnicode.render("(-\\tfrac14, 0, 0)") == "(-1/4, 0, 0)"
    end

    test "u = xy" do
      assert LatexUnicode.render("u = xy") == "u = xy"
    end

    test "t = x^2z" do
      assert LatexUnicode.render("t = x^2z") == "t = x²z"
    end

    test "x \\neq 0" do
      assert LatexUnicode.render("x \\neq 0") == "x ≠ 0"
    end

    test "f_1^{\\text{ut}}, f_2^{\\text{ut}}" do
      assert LatexUnicode.render("f_1^{\\text{ut}}, f_2^{\\text{ut}}") == "f₁ᵘᵗ, f₂ᵘᵗ"
    end

    test "u,t" do
      assert LatexUnicode.render("u,t") == "u,t"
    end

    test "x" do
      assert LatexUnicode.render("x") == "x"
    end

    test "x, x^2" do
      assert LatexUnicode.render("x, x^2") == "x, x²"
    end

    test "\\mathbb{C}^n \\to \\mathbb{C}^n" do
      assert LatexUnicode.render("\\mathbb{C}^n \\to \\mathbb{C}^n") == "ℂⁿ → ℂⁿ"
    end

    test "n \\geq 2" do
      assert LatexUnicode.render("n \\geq 2") == "n ≥ 2"
    end

    test "\\mathbb{P}^3" do
      assert LatexUnicode.render("\\mathbb{P}^3") == "ℙ³"
    end
  end

  describe "extended formulas from a renderer stress-test session" do
    test "e^{i\\pi}+1=0" do
      assert LatexUnicode.render("e^{i\\pi}+1=0") == "e^(iπ)+1 = 0"
    end

    test "\\boxed{\n\\mathcal{Z}(\\beta)\n=\n\\int_{\\mathcal M}\n\\exp\\!\\left(\n-\\beta\\left[\n\\frac12 g^{ij}(x)\\,\\partial_i\\phi\\,\\partial_j\\phi\n+V(\\phi)\n\\right]\\right)\n\\mathcal D\\phi\n}" do
      assert LatexUnicode.render(
               "\\boxed{\n\\mathcal{Z}(\\beta)\n=\n\\int_{\\mathcal M}\n\\exp\\!\\left(\n-\\beta\\left[\n\\frac12 g^{ij}(x)\\,\\partial_i\\phi\\,\\partial_j\\phi\n+V(\\phi)\n\\right]\\right)\n\\mathcal D\\phi\n}"
             ) == "[Z(β) = ∫_ℳ exp( -β[ 1/2 gⁱʲ(x) ∂ᵢϕ ∂ⱼϕ +V(ϕ) ]) Dϕ]"

      # `\mathcal M` is `M` in pi, which leaves the command as a plain wrapper;
      # the letterlike script letters are substituted here (AlphabetTest).
    end

    test "\\begin{aligned}\n\\nabla_\\mu T^{\\mu\\nu}\n&=\n\\frac{1}{\\sqrt{-g}}\n\\partial_\\mu\\!\\left(\\sqrt{-g}\\,T^{\\mu\\nu}\\right)\n+\\Gamma^\\nu_{\\mu\\lambda}T^{\\mu\\lambda}\n=0, \\\\[4pt]\nR_{\\mu\\nu}-\\frac12 Rg_{\\mu\\nu}+\\Lambda g_{\\mu\\nu}\n&=\n\\frac{8\\pi G}{c^4}T_{\\mu\\nu}.\n\\end{aligned}" do
      assert LatexUnicode.render(
               "\\begin{aligned}\n\\nabla_\\mu T^{\\mu\\nu}\n&=\n\\frac{1}{\\sqrt{-g}}\n\\partial_\\mu\\!\\left(\\sqrt{-g}\\,T^{\\mu\\nu}\\right)\n+\\Gamma^\\nu_{\\mu\\lambda}T^{\\mu\\lambda}\n=0, \\\\[4pt]\nR_{\\mu\\nu}-\\frac12 Rg_{\\mu\\nu}+\\Lambda g_{\\mu\\nu}\n&=\n\\frac{8\\pi G}{c^4}T_{\\mu\\nu}.\n\\end{aligned}"
             ) ==
               "∇_μ T^(μν) = 1/(√(-g)) ∂_μ(√(-g) T^(μν)) +Γ^ν_(μλ)T^(μλ) = 0,\nR_(μν)-1/2 Rg_(μν)+Λ g_(μν) = (8π G)/(c⁴)T_(μν)."
    end

    test "f(z)\n=\n\\frac{1}{2\\pi i}\n\\oint_{\\gamma}\n\\frac{f(\\zeta)}{\\zeta-z}\\,d\\zeta,\n\\qquad\n\\det\\!\\begin{pmatrix}\n\\lambda-a & -b & 0\\\\\n-c & \\lambda-d & -e\\\\\n0 & -f & \\lambda-g\n\\end{pmatrix}\n=0." do
      assert LatexUnicode.render(
               "f(z)\n=\n\\frac{1}{2\\pi i}\n\\oint_{\\gamma}\n\\frac{f(\\zeta)}{\\zeta-z}\\,d\\zeta,\n\\qquad\n\\det\\!\\begin{pmatrix}\n\\lambda-a & -b & 0\\\\\n-c & \\lambda-d & -e\\\\\n0 & -f & \\lambda-g\n\\end{pmatrix}\n=0."
             ) ==
               "f(z) = 1/(2π i) ∮_γ (f(ζ))/(ζ-z) dζ, det⎛ λ-a │ -b  │ 0   ⎞ = 0.\n                                        ⎜ -c  │ λ-d │ -e  ⎟\n                                        ⎝ 0   │ -f  │ λ-g ⎠"
    end

    test "\\Psi(x,t)=\n\\sum_{n=1}^{\\infty}\n\\underbrace{\nc_n\n\\sqrt{\\frac{2}{L}}\n\\sin\\!\\left(\\frac{n\\pi x}{L}\\right)\n}_{\\text{spatial eigenmode}}\n\\exp\\!\\left(-\\frac{i\\hbar n^2\\pi^2}{2mL^2}t\\right),\n\\qquad\n|\\Psi(x,t)|^2\n=\n\\begin{cases}\n\\Psi^\\ast\\Psi, & 0<x<L,\\\\\n0, & \\text{otherwise}.\n\\end{cases}" do
      assert LatexUnicode.render(
               "\\Psi(x,t)=\n\\sum_{n=1}^{\\infty}\n\\underbrace{\nc_n\n\\sqrt{\\frac{2}{L}}\n\\sin\\!\\left(\\frac{n\\pi x}{L}\\right)\n}_{\\text{spatial eigenmode}}\n\\exp\\!\\left(-\\frac{i\\hbar n^2\\pi^2}{2mL^2}t\\right),\n\\qquad\n|\\Psi(x,t)|^2\n=\n\\begin{cases}\n\\Psi^\\ast\\Psi, & 0<x<L,\\\\\n0, & \\text{otherwise}.\n\\end{cases}"
             ) ==
               "                                                                                                 ⎧ Ψ^∗Ψ if 0 < x < L,\nΨ(x,t) = ∑ₙ₌₁^∞ cₙ √(2/L) sin((nπ x)/L)_(spatial eigenmode) exp(-(iℏ n²π²)/(2mL²)t), |Ψ(x,t)|² = ⎨\n                                                                                                 ⎩ 0    otherwise."
    end

    test "x=\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}" do
      assert LatexUnicode.render("x=\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}") ==
               "x = (-b±√(b²-4ac))/(2a)"
    end

    test "\\int_0^\\infty e^{-x^2}\\,dx=\\frac{\\sqrt{\\pi}}{2}" do
      assert LatexUnicode.render("\\int_0^\\infty e^{-x^2}\\,dx=\\frac{\\sqrt{\\pi}}{2}") ==
               "∫₀^∞ e^(-x²) dx = (√π)/2"
    end

    test "e^{i\\theta}=\\cos\\theta+i\\sin\\theta" do
      assert LatexUnicode.render("e^{i\\theta}=\\cos\\theta+i\\sin\\theta") ==
               "e^(iθ) = cos θ+i sin θ"
    end

    test "\\sum_{n=1}^{\\infty}\\frac{1}{n^2}=\\frac{\\pi^2}{6}" do
      assert LatexUnicode.render("\\sum_{n=1}^{\\infty}\\frac{1}{n^2}=\\frac{\\pi^2}{6}") ==
               "∑ₙ₌₁^∞1/(n²) = π²/6"
    end

    test "\\lim_{x\\to 0}\\frac{\\sin x}{x}=1" do
      assert LatexUnicode.render("\\lim_{x\\to 0}\\frac{\\sin x}{x}=1") ==
               "lim[x→0] (sin x)/x = 1"
    end

    test "\\lim_{n\\to\\infty}\n\\left(1+\\frac{1}{n}\\right)^n=e" do
      assert LatexUnicode.render("\\lim_{n\\to\\infty}\n\\left(1+\\frac{1}{n}\\right)^n=e") ==
               "lim[n→∞] (1+1/n)ⁿ = e"
    end

    test "\\int_0^1 \\frac{x^2}{1+x^3}\\,dx\n=\\frac{1}{3}\\ln 2" do
      assert LatexUnicode.render("\\int_0^1 \\frac{x^2}{1+x^3}\\,dx\n=\\frac{1}{3}\\ln 2") ==
               "∫₀¹ x²/(1+x³) dx = 1/3 ln 2"
    end

    test "\\sum_{k=1}^{n}\\frac{k}{k+1}\n=n+1-H_{n+1}" do
      assert LatexUnicode.render("\\sum_{k=1}^{n}\\frac{k}{k+1}\n=n+1-H_{n+1}") ==
               "∑ₖ₌₁ⁿk/(k+1) = n+1-Hₙ₊₁"
    end

    test "\\frac{\n  \\displaystyle \\frac{x^2+1}{x-1}\n  -\n  \\displaystyle \\frac{2x}{x+1}\n}{\n  \\displaystyle \\frac{x}{x^2-1}\n}" do
      assert LatexUnicode.render(
               "\\frac{\n  \\displaystyle \\frac{x^2+1}{x-1}\n  -\n  \\displaystyle \\frac{2x}{x+1}\n}{\n  \\displaystyle \\frac{x}{x^2-1}\n}"
             ) == "((x²+1)/(x-1) - 2x/(x+1))/(x/(x²-1))"
    end

    test "\\lim_{x\\to 0}\n\\frac{\n  \\displaystyle \\frac{\\sin x}{x}-1\n}{\n  \\displaystyle \\frac{e^x-1}{x}-1\n}\n=0" do
      assert LatexUnicode.render(
               "\\lim_{x\\to 0}\n\\frac{\n  \\displaystyle \\frac{\\sin x}{x}-1\n}{\n  \\displaystyle \\frac{e^x-1}{x}-1\n}\n=0"
             ) == "lim[x→0] ((sin x)/x-1)/((eˣ-1)/x-1) = 0"
    end

    test "\\frac{\n  1+\\displaystyle\\frac{1}{1+\\frac{1}{x}}\n}{\n  1-\\displaystyle\\frac{1}{1-\\frac{1}{x}}\n}" do
      assert LatexUnicode.render(
               "\\frac{\n  1+\\displaystyle\\frac{1}{1+\\frac{1}{x}}\n}{\n  1-\\displaystyle\\frac{1}{1-\\frac{1}{x}}\n}"
             ) == "(1+1/(1+1/x))/(1-1/(1-1/x))"
    end

    test "\\sum_{n=1}^{\\infty}\n\\frac{\n  \\displaystyle \\frac{1}{n}-\\frac{1}{n+1}\n}{\n  \\displaystyle 1+\\frac{1}{n^2}\n}" do
      assert LatexUnicode.render(
               "\\sum_{n=1}^{\\infty}\n\\frac{\n  \\displaystyle \\frac{1}{n}-\\frac{1}{n+1}\n}{\n  \\displaystyle 1+\\frac{1}{n^2}\n}"
             ) == "∑ₙ₌₁^∞ (1/n-1/(n+1))/(1+1/(n²))"
    end
  end

  describe "renders common symbols, roots, sums, and integrals" do
    test "\\sum_{i=0}^n \\alpha_i + \\int_0^\\infty e^{-x^2}\\,dx = \\sqrt{\\pi}" do
      assert LatexUnicode.render(
               "\\sum_{i=0}^n \\alpha_i + \\int_0^\\infty e^{-x^2}\\,dx = \\sqrt{\\pi}"
             ) ==
               "∑ᵢ₌₀ⁿ αᵢ + ∫₀^∞ e^(-x²) dx = √π"
    end
  end

  describe "renders common accents and binomial notation" do
    test "\\binom{n}{k}+\\vec{x}+\\hat{y}+\\overline{AB}" do
      assert LatexUnicode.render("\\binom{n}{k}+\\vec{x}+\\hat{y}+\\overline{AB}") ==
               "(n choose k)+x⃗+ŷ+overline(AB)"
    end
  end

  describe "centers even case rows around a middle brace" do
    test "f(x) = \\begin{cases} x^{2} & x \\geq 0 \\\\ -x & x < 0 \\end{cases}" do
      assert LatexUnicode.render(
               "f(x) = \\begin{cases} x^{2} & x \\geq 0 \\\\ -x & x < 0 \\end{cases}"
             ) ==
               "       ⎧ x² if x ≥ 0\nf(x) = ⎨\n       ⎩ -x if x < 0"
    end
  end

  describe "renders extended symbols and negated relations" do
    test "\\epsilon+\\varepsilon+\\varsigma+\\varkappa+\\oplus+\\otimes+\\therefore+\\because" do
      assert LatexUnicode.render(
               "\\epsilon+\\varepsilon+\\varsigma+\\varkappa+\\oplus+\\otimes+\\therefore+\\because"
             ) == "ϵ+ε+ς+ϰ+⊕+⊗+∴+∵"
    end

    test "A\\not\\subseteq B,\\quad x\\not\\in X" do
      assert LatexUnicode.render("A\\not\\subseteq B,\\quad x\\not\\in X") == "A ⊈ B, x ∉ X"
    end
  end

  describe "renders relational algebra join operators" do
    test "R\\bowtie S,\\quad R\\Join S" do
      assert LatexUnicode.render("R\\bowtie S,\\quad R\\Join S") == "R ⋈ S, R ⋈ S"
    end

    test "R\\ltimes S,\\quad R\\rtimes S" do
      assert LatexUnicode.render("R\\ltimes S,\\quad R\\rtimes S") == "R ⋉ S, R ⋊ S"
    end

    test "R\\leftouterjoin S,\\quad R\\rightouterjoin S,\\quad R\\fullouterjoin S" do
      assert LatexUnicode.render(
               "R\\leftouterjoin S,\\quad R\\rightouterjoin S,\\quad R\\fullouterjoin S"
             ) ==
               "R ⟕ S, R ⟖ S, R ⟗ S"
    end
  end

  describe "renders delimiter commands and invisible delimiters" do
    test "\\lvert{x}\\rvert+\\lVert{v}\\rVert+\\left.\\frac{dy}{dx}\\right|_{x=0}" do
      assert LatexUnicode.render(
               "\\lvert{x}\\rvert+\\lVert{v}\\rVert+\\left.\\frac{dy}{dx}\\right|_{x=0}"
             ) ==
               "|x|+‖v‖+dy/(dx)|ₓ₌₀"
    end

    test "\\left\\lbrace x \\middle| x>0 \\right\\rbrace" do
      assert LatexUnicode.render("\\left\\lbrace x \\middle| x>0 \\right\\rbrace") ==
               "{ x | x > 0 }"
    end
  end

  describe "renders named, modular, overlaid, and underlaid operators" do
    test "\\operatorname*{arg\\,max}_{x\\in X} f(x)" do
      assert LatexUnicode.render("\\operatorname*{arg\\,max}_{x\\in X} f(x)") ==
               "arg max[x∈X] f(x)"
    end

    test "a\\bmod n,\\quad a\\equiv b\\pmod n" do
      assert LatexUnicode.render("a\\bmod n,\\quad a\\equiv b\\pmod n") ==
               "a mod n, a ≡ b (mod n)"
    end

    test "\\overset{!}{=}+\\underset{n}{x}+\\stackrel{def}{=}" do
      assert LatexUnicode.render("\\overset{!}{=}+\\underset{n}{x}+\\stackrel{def}{=}") ==
               "=^!+xₙ+=ᵈᵉᶠ"
    end
  end

  describe "renders indexed roots and additional accents and wrappers" do
    test "\\sqrt[2]{x}+\\sqrt[3]{x}+\\sqrt[4]{x}+\\sqrt[n]{x}+\\sqrt[k]{x+1}" do
      assert LatexUnicode.render(
               "\\sqrt[2]{x}+\\sqrt[3]{x}+\\sqrt[4]{x}+\\sqrt[n]{x}+\\sqrt[k]{x+1}"
             ) ==
               "√x+∛x+∜x+ⁿ√x+ᵏ√(x+1)"
    end

    test "\\acute{x}+\\grave{y}+\\widehat{xyz}+\\overrightarrow{AB}" do
      assert LatexUnicode.render("\\acute{x}+\\grave{y}+\\widehat{xyz}+\\overrightarrow{AB}") ==
               "x́+ỳ+widehat(xyz)+overrightarrow(AB)"
    end

    test "\\textnormal{hello}+\\mbox{world}+\\boldsymbol{x}+{\\rm roman}+{\\bf bold}+{\\it italic}+{\\sf sans}+{\\tt mono}+{\\cal calligraphic}+{\\sl slanted}" do
      assert LatexUnicode.render(
               "\\textnormal{hello}+\\mbox{world}+\\boldsymbol{x}+{\\rm roman}+{\\bf bold}+{\\it italic}+{\\sf sans}+{\\tt mono}+{\\cal calligraphic}+{\\sl slanted}"
             ) == "hello+world+x+roman+bold+italic+sans+mono+calligraphic+slanted"
    end
  end

  describe "renders additional display environments" do
    test "\\begin{equation}\\begin{split}a&=b\\\\&=c\\end{split}\\end{equation}" do
      assert LatexUnicode.render(
               "\\begin{equation}\\begin{split}a&=b\\\\&=c\\end{split}\\end{equation}"
             ) ==
               "a = b\n= c"
    end

    test "\\begin{alignedat}{2}a&=b&\\quad c&=d\\\\e&=f&g&=h\\end{alignedat}" do
      assert LatexUnicode.render(
               "\\begin{alignedat}{2}a&=b&\\quad c&=d\\\\e&=f&g&=h\\end{alignedat}"
             ) ==
               "a = b c = d\ne = f g = h"
    end
  end

  describe "uses natural case conditions and aligns matrix columns" do
    test "f(x)=\\begin{cases}a & x<0 \\\\ b & \\text{if }x=0 \\\\ c & \\text{otherwise}\\end{cases}" do
      assert LatexUnicode.render(
               "f(x)=\\begin{cases}a & x<0 \\\\ b & \\text{if }x=0 \\\\ c & \\text{otherwise}\\end{cases}"
             ) == "       ⎧ a if x < 0\nf(x) = ⎨ b if x = 0\n       ⎩ c otherwise"
    end

    test "\\begin{pmatrix}1&200\\\\3000&4\\end{pmatrix}" do
      assert LatexUnicode.render("\\begin{pmatrix}1&200\\\\3000&4\\end{pmatrix}") ==
               "⎛ 1    │ 200 ⎞\n⎝ 3000 │ 4   ⎠"
    end
  end

  describe "composes matrices with fractions and adjacent matrices" do
    test "R\\left(\\frac{\\pi}{4}\\right)\n=\n\\begin{pmatrix}\n\\frac{\\sqrt{2}}{2} & -\\frac{\\sqrt{2}}{2}\\\\\n\\frac{\\sqrt{2}}{2} & \\frac{\\sqrt{2}}{2}\n\\end{pmatrix}." do
      assert LatexUnicode.render(
               "R\\left(\\frac{\\pi}{4}\\right)\n=\n\\begin{pmatrix}\n\\frac{\\sqrt{2}}{2} & -\\frac{\\sqrt{2}}{2}\\\\\n\\frac{\\sqrt{2}}{2} & \\frac{\\sqrt{2}}{2}\n\\end{pmatrix}.",
               display: true
             ) == "   π\nR( ─ ) = ⎛ (√2)/2 │ -(√2)/2 ⎞\n   4     ⎝ (√2)/2 │ (√2)/2  ⎠."
    end

    test "\\mathbf w\n=\nR\\left(\\frac{\\pi}{4}\\right)\n\\begin{pmatrix}1\\\\0\\end{pmatrix}\n=\n\\begin{pmatrix}\\frac{\\sqrt{2}}{2}\\\\\\frac{\\sqrt{2}}{2}\\end{pmatrix}." do
      assert LatexUnicode.render(
               "\\mathbf w\n=\nR\\left(\\frac{\\pi}{4}\\right)\n\\begin{pmatrix}1\\\\0\\end{pmatrix}\n=\n\\begin{pmatrix}\\frac{\\sqrt{2}}{2}\\\\\\frac{\\sqrt{2}}{2}\\end{pmatrix}.",
               display: true
             ) == "       π\nw = R( ─ ) ⎛ 1 ⎞ = ⎛ (√2)/2 ⎞\n       4   ⎝ 0 ⎠   ⎝ (√2)/2 ⎠."
    end

    test "A\\mathbf e_1=\\begin{pmatrix}\\pi\\\\0\\end{pmatrix},\\qquad A\\mathbf e_2=\\begin{pmatrix}0\\\\\\frac{1}{\\pi}\\end{pmatrix}." do
      assert LatexUnicode.render(
               "A\\mathbf e_1=\\begin{pmatrix}\\pi\\\\0\\end{pmatrix},\\qquad A\\mathbf e_2=\\begin{pmatrix}0\\\\\\frac{1}{\\pi}\\end{pmatrix}.",
               display: true
             ) == "Ae₁ = ⎛ π ⎞, Ae₂ = ⎛ 0   ⎞\n      ⎝ 0 ⎠        ⎝ 1/π ⎠."
    end

    test "\\sum_{i=0}^n x_i=\\begin{pmatrix}a&b\\\\c&d\\end{pmatrix}." do
      assert LatexUnicode.render("\\sum_{i=0}^n x_i=\\begin{pmatrix}a&b\\\\c&d\\end{pmatrix}.",
               display: true
             ) ==
               " n\n ∑  xᵢ = ⎛ a │ b ⎞\ni=0      ⎝ c │ d ⎠."
    end
  end

  describe "normalizes relation, multiplication, and named-operator spacing" do
    test "x=y" do
      assert LatexUnicode.render("x=y") == "x = y"
    end

    test "x =y" do
      assert LatexUnicode.render("x =y") == "x = y"
    end

    test "x=\ny" do
      assert LatexUnicode.render("x=\ny") == "x = y"
    end

    test "x\n=\ny" do
      assert LatexUnicode.render("x\n=\ny") == "x = y"
    end

    test "x_{i=0}" do
      assert LatexUnicode.render("x_{i=0}") == "xᵢ₌₀"
    end

    test "x\\neq0" do
      assert LatexUnicode.render("x\\neq0") == "x ≠ 0"
    end

    test "A\\to B" do
      assert LatexUnicode.render("A\\to B") == "A → B"
    end

    test "\\pi\\cdot\\frac{1}{\\pi}" do
      assert LatexUnicode.render("\\pi\\cdot\\frac{1}{\\pi}") == "π · 1/π"
    end

    test "\\sin\\theta" do
      assert LatexUnicode.render("\\sin\\theta") == "sin θ"
    end

    test "\\sin^2 x" do
      assert LatexUnicode.render("\\sin^2 x") == "sin² x"
    end

    test "-\\sin\\theta" do
      assert LatexUnicode.render("-\\sin\\theta") == "-sin θ"
    end

    test "i\\sin\\theta" do
      assert LatexUnicode.render("i\\sin\\theta") == "i sin θ"
    end

    test "\\det(A)" do
      assert LatexUnicode.render("\\det(A)") == "det(A)"
    end
  end

  describe "treats a backslash followed by a line ending as control space" do
    test "\\boxed{\n(1,1,1),\\ (1,1,2),\\ (1,2,5),\\ (1,5,13),\\ (2,5,29),\\\n(1,13,34),\\ (1,34,89)\n}." do
      assert LatexUnicode.render(
               "\\boxed{\n(1,1,1),\\ (1,1,2),\\ (1,2,5),\\ (1,5,13),\\ (2,5,29),\\\n(1,13,34),\\ (1,34,89)\n}.",
               display: true
             ) == "[(1,1,1), (1,1,2), (1,2,5), (1,5,13), (2,5,29), (1,13,34), (1,34,89)]."
    end

    test "a\\\r\nb" do
      assert LatexUnicode.render("a\\\r\nb") == "a b"
    end
  end

  describe "stacks operator limits in display mode" do
    test "\\sum_{i=0}^n x_i" do
      assert LatexUnicode.render("\\sum_{i=0}^n x_i", display: true) == " n\n ∑  xᵢ\ni=0"
    end

    test "\\min_{x\\in X} f(x)" do
      assert LatexUnicode.render("\\min_{x\\in X} f(x)", display: true) == "min f(x)\nx∈X"
    end

    test "\\operatorname*{arg\\,max}_{x\\in X} f(x)" do
      assert LatexUnicode.render("\\operatorname*{arg\\,max}_{x\\in X} f(x)", display: true) ==
               "arg max f(x)\n  x∈X"
    end

    test "\\int\\nolimits_0^1 f(x)\\,dx" do
      assert LatexUnicode.render("\\int\\nolimits_0^1 f(x)\\,dx", display: true) == "∫₀¹ f(x) dx"
    end

    test "\\int\\limits_0^1 f(x)\\,dx" do
      assert LatexUnicode.render("\\int\\limits_0^1 f(x)\\,dx", display: true) ==
               "1\n∫ f(x) dx\n0"
    end
  end

  describe "stacks fractions in display mode" do
    test "x=\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}" do
      assert LatexUnicode.render("x=\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}", display: true) ==
               "    -b±√(b²-4ac)\nx = ────────────\n         2a"
    end

    test "\\frac{x^2+1}{x-1}" do
      assert LatexUnicode.render("\\frac{x^2+1}{x-1}", display: true) == "x²+1\n────\nx-1"
    end

    test "\\frac{1}\n{2}" do
      assert LatexUnicode.render("\\frac{1}\n{2}", display: true) == "1\n─\n2"
    end
  end

  describe "keeps nested display fractions linear" do
    test "\\frac{\\frac{x^2+1}{x-1}-\\frac{2x}{x+1}}{\\frac{x}{x^2-1}}" do
      assert LatexUnicode.render("\\frac{\\frac{x^2+1}{x-1}-\\frac{2x}{x+1}}{\\frac{x}{x^2-1}}",
               display: true
             ) ==
               "(x²+1)/(x-1)-2x/(x+1)\n─────────────────────\n      x/(x²-1)"
    end

    test "\\lim_{x\\to 0}\\frac{\\frac{\\sin x}{x}-1}{\\frac{e^x-1}{x}-1}=0" do
      assert LatexUnicode.render(
               "\\lim_{x\\to 0}\\frac{\\frac{\\sin x}{x}-1}{\\frac{e^x-1}{x}-1}=0",
               display: true
             ) ==
               "     (sin x)/x-1\nlim  ─────────── = 0\nx→0  (eˣ-1)/x-1"
    end

    test "\\frac{1+\\frac{1}{1+\\frac{1}{x}}}{1-\\frac{1}{1-\\frac{1}{x}}}" do
      assert LatexUnicode.render(
               "\\frac{1+\\frac{1}{1+\\frac{1}{x}}}{1-\\frac{1}{1-\\frac{1}{x}}}",
               display: true
             ) ==
               "1+1/(1+1/x)\n───────────\n1-1/(1-1/x)"
    end
  end

  describe "lays out unsupported and nested scripts while keeping script fractions linear" do
    test "\\partial_tU_2(t,0)=Aj_*(1-t)^{-A-1}.\\qquad x^{n^2}+x_{i_j}" do
      assert LatexUnicode.render("\\partial_tU_2(t,0)=Aj_*(1-t)^{-A-1}.\\qquad x^{n^2}+x_{i_j}",
               display: true
             ) ==
               "                            2\n                    -A-1   n\n∂ₜU₂(t,0) = Aj (1-t)    . x  +x\n              *                i\n                                j"
    end

    test "e^{\\frac{1}{2}}+\\tfrac{1}{2}" do
      assert LatexUnicode.render("e^{\\frac{1}{2}}+\\tfrac{1}{2}", display: true) == "e^(1/2)+1/2"
    end
  end

  describe "returns undefined for unsupported commands" do
    test "x + \\unknown{y}" do
      assert LatexUnicode.render("x + \\unknown{y}") == nil
    end
  end

  describe "returns undefined for malformed groups and environments" do
    test "\\frac{1}{x" do
      assert LatexUnicode.render("\\frac{1}{x") == nil
    end

    test "x}" do
      assert LatexUnicode.render("x}") == nil
    end

    test "\\begin{matrix}1 & 2" do
      assert LatexUnicode.render("\\begin{matrix}1 & 2") == nil
    end

    test "x\\" do
      assert LatexUnicode.render("x\\") == nil
    end
  end
end
