# Maintainability Index for five languages

Context: [Wayfinder ticket #18](https://github.com/guility/agents-template/issues/18).

## Finding

A single equation is computable, but the current tools do not provide defensibly comparable inputs for Python, Node.js/TypeScript, Rust, Go and C#. Keep the conditional MI requirement excluded. This is an inference from the formula variants, tool definitions and current language rules below.

## Formula variants and inputs

- The baseline formula is `171 - 5.2 ln(HV) - 0.23 CC - 16.2 ln(LOC)`. The Visual Studio variant clamps negative values and rescales to 0–100; it omits a comment term. [Radon’s formula comparison](https://radon.readthedocs.io/en/v6.0.1/intro.html) and [Microsoft’s definition](https://learn.microsoft.com/en-us/visualstudio/code-quality/code-metrics-maintainability-index-range-and-meaning?view=visualstudio) document this form.
- The SEI derivative adds a comment-percentage term and uses base-2 logarithms for volume and LOC. Radon combines that comment term with natural logs and the 0–100 normalization. Therefore “MI” alone does not identify a unique formula, input scale or comment policy. [Radon formula comparison](https://radon.readthedocs.io/en/v6.0.1/intro.html).
- The inputs are Halstead Volume (operator/operand counts), cyclomatic complexity, a chosen LOC definition, and—only in some variants—comment percentage. Radon distinguishes LOC, logical LOC and source LOC; its docs say SLOC does not necessarily equal LLOC and exclude Python multiline strings from comments. [Radon metric definitions](https://radon.readthedocs.io/en/v6.0.1/intro.html).
- Microsoft’s current Code Metrics returns MI on a 0–100 scale; its command-line metrics support C# and Visual Basic. The current implementation counts logical `IOperations`, and Microsoft notes results can differ from older IL-based metrics. [Code Metrics generation](https://learn.microsoft.com/en-us/visualstudio/code-quality/how-to-generate-code-metrics-data?view=visualstudio) and [MI range and formula](https://learn.microsoft.com/en-us/visualstudio/code-quality/code-metrics-maintainability-index-range-and-meaning?view=visualstudio).
- Radon explicitly calls MI “very experimental.” SEI’s maintainability report says such single-number indices are not widely adopted because they are not actionable, lack empirical support and omit design complexity. [Radon](https://radon.readthedocs.io/en/v6.0.1/intro.html), [SEI report](https://www.sei.cmu.edu/library/maintainability/).

## Language/tool coverage

| Language | Current language guidance and tool output |
| --- | --- |
| Python | The [Python rules](https://github.com/guility/agents-template-langs/blob/python/v2.0.0/AGENTS.md) recommend Radon and Lizard; Radon computes MI from a Python AST and reports HV, CC, LLOC and comment percentage. [Radon API](https://radon.readthedocs.io/en/v6.0.1/api.html). |
| Node.js/TypeScript | [Rules](https://github.com/guility/agents-template-langs/blob/nodejs/v1.0.1/AGENTS.md) use ESLint/TypeScript; ESLint’s `complexity` rule measures cyclomatic complexity, not MI. [ESLint rule](https://eslint.org/docs/latest/rules/complexity). |
| Rust | [Rules](https://github.com/guility/agents-template-langs/blob/rust/v1.0.1/AGENTS.md) recommend Clippy; its complexity lints suggest simplifications and do not define MI. [Clippy lint groups](https://doc.rust-lang.org/clippy/lints.html). |
| Go | [Rules](https://github.com/guility/agents-template-langs/blob/go/v1.0.1/AGENTS.md) select Lizard or gocyclo for complexity; gocyclo reports cyclomatic complexity only. [gocyclo](https://github.com/fzipp/gocyclo). |
| C# | [Rules](https://github.com/guility/agents-template-langs/blob/csharp/v1.0.2/AGENTS.md) recommend Roslyn analyzers; Microsoft Code Metrics can emit MI for C#/VB, but uses its own extraction and scoring implementation. [Microsoft Code Metrics](https://learn.microsoft.com/en-us/visualstudio/code-quality/how-to-generate-code-metrics-data?view=visualstudio). |

Lizard supports all five target languages and its Halstead extension can emit per-function volume. However, its extension says Halstead depends on operator/operand classification, provides a Python-specific classifier, and falls back to a generic C-family approximation for other languages. The repository’s current [complexity analyzer](https://github.com/guility/agents-template/blob/main/scripts/testing/complexity_analyzer.py) invokes Lizard without the Halstead extension. [Lizard language/metric support](https://github.com/terryyin/lizard), [Halstead extension documentation](https://github.com/terryyin/lizard/blob/master/lizard_ext/README.md), [classifier implementation](https://github.com/terryyin/lizard/blob/master/lizard_ext/lizardhalstead.py).

## Recommendation

Keep Maintainability Index out of the common requirement and all five language packs for now. Python Radon and .NET Code Metrics can produce MI locally, but they do not establish a shared cross-language input contract; current Lizard Halstead classification is explicitly approximate outside Python. Reconsider only after language-specific operator/operand rules and consistent CC/LOC scopes are specified and validated for all five languages. Continue using the existing per-language complexity and lint tools without presenting their outputs as one cross-language MI score.
