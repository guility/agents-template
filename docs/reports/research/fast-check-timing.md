# Измерение быстрых push-проверок на 10 000 строк

Дата: 2026-11-21. Источник репозитория: `origin/main` на `f4b9a55`. Замеры выполнены в отдельных временных Git-фикстурах в `/tmp/fastcheck-corpus` и `/tmp/fastcheck-corpus-multi`.

## Методика и ограничения

- Smoke-фикстура содержит пять исходных файлов по 2 000 строк. Основной корпус содержит ровно 10 000 физических исходных строк в 51 файле: по 2 000 строк и 10 файлов на язык, плюс Rust `lib.rs` с объявлениями модулей. Оба корпуса синтетические, с повторяющимися простыми функциями и без внешних зависимостей.
- Система: PikaOS 4, Linux 7.3.1-pikaos x86_64; Intel Core i5-13600K (20 логических CPU). Замер wall time через `perf_counter_ns`, включая запуск процесса.
- Smoke-таблица сохраняет первый замер и медиану следующих пяти. Для основного набора первый проход использовал свежие кэши анализаторов/компиляторов, затем выполнено пять повторов. Кэш страниц ОС и сами бинарники были прогреты; установка инструментов и restore NuGet пакетов не входят во время.
- Полный набор — предложенные в исследовании [quality-metrics](https://github.com/guility/agents-template/blob/research/quality-metrics/docs/reports/research/quality-metrics.md) быстрые проверки: allowlist ветки, Gitleaks commit diff, Lizard, Ruff + mypy, ESLint + `tsc` + Prettier, `cargo fmt` + Clippy, `gofmt` + golangci-lint, C# whitespace + SDK analyzers.
- Успешный проход означает только отсутствие срабатываний на синтетической фикстуре. Нет production-зависимостей, сборки приложения, тестов, SAST/MR-проверок, сетевого доступа или фоновой нагрузки. Для C# выполнен restore минимального проекта до запуска checks; сами format/analyzer jobs работали с `--no-restore`.

## Первичный smoke-тест с пятью большими файлами

| Проверка и команда | Версия | Первый / медиана следующих 5 | Результат |
|---|---:|---:|---|
| `git check-ref-format --branch research//invalid` | Git 2.53.0.697.g625c4fb2daa | 0,658–1,031 мс; медиана 0,718 мс (10 повторов) | Ожидаемый ненулевой код; проверено, что downstream marker не создаётся |
| `/tmp/fastcheck-tools/gitleaks/gitleaks git --log-opts=HEAD~1..HEAD --no-banner --log-level error` | Gitleaks 8.30.1 | 416 / 410 мс | Код 0; commit diff из 10 000 строк |
| `/tmp/fastcheck-tools/gitleaks/gitleaks git --staged --no-banner --log-level error` | Gitleaks 8.30.1 | 232 / 240 мс | Код 0; staged diff из 10 000 строк |
| `/tmp/fastcheck-tools/gitleaks/gitleaks dir --no-banner --log-level error /tmp/fastcheck-corpus` | Gitleaks 8.30.1 | 239 / 239 мс | Код 0; сканирование worktree |
| `/tmp/fastcheck-tools/venv/bin/ruff check --no-cache /tmp/fastcheck-corpus/python/corpus.py` | Python 3.14.8, Ruff 0.17.6 | 9,1 / 9,6 мс | Код 0 |
| `/tmp/fastcheck-tools/venv/bin/ruff format --check /tmp/fastcheck-corpus/python/corpus.py` | Ruff 0.17.6 | 10,7 / 8,9 мс | Код 0 |
| `/tmp/fastcheck-tools/node/node-v26.13.1-linux-x64/bin/node /tmp/fastcheck-tools/node-tools/node_modules/.bin/prettier --check /tmp/fastcheck-corpus/nodejs/corpus.ts` | Node.js 26.13.1, Prettier 3.10.1 | 262 / 257 мс | Код 0 |
| `/home/andrey_zubkov/.cargo/bin/rustfmt --check /tmp/fastcheck-corpus/rust/corpus.rs` | rustfmt 1.10.0-stable (Rust 1.99.1) | 23 / 11 мс | Код 0 |
| `/tmp/fastcheck-tools/go/bin/gofmt -l /tmp/fastcheck-corpus/go/corpus.go` | Go 1.27.4 | 4,9 / 4,9 мс | Код 0, список пуст |
| `/tmp/fastcheck-tools/venv/bin/lizard -C 10 /tmp/fastcheck-corpus/python/corpus.py /tmp/fastcheck-corpus/nodejs/corpus.ts /tmp/fastcheck-corpus/rust/corpus.rs /tmp/fastcheck-corpus/go/corpus.go /tmp/fastcheck-corpus/csharp/Corpus.cs` | Lizard 1.26.1 | 108 / 108 мс | Код 0; изменённые файлы |
| `/tmp/fastcheck-tools/venv/bin/lizard -C 10 /tmp/fastcheck-corpus` | Lizard 1.26.1 | 108 / 110 мс | Код 0; полный каталог фикстуры |
| `dotnet format whitespace Benchmark.csproj --include Corpus.cs --verify-no-changes --no-restore --verbosity quiet` | .NET SDK 10.0.404 | 2,258 / 2,273 мс | Код 0; минимальный C# проект без внешних анализаторов |
| `dotnet format analyzers Benchmark.csproj --include Corpus.cs --verify-no-changes --no-restore --severity warn --verbosity quiet` | .NET SDK 10.0.404 | 2,503 / 2,373 мс | Код 0; SDK/Roslyn анализаторы |

Smoke-набор в одном исходном файле на язык занимал 5,708 с в первом запуске и 5,619 с медианно в следующих пяти при C# checks; без них — 966 / 976 мс. Он не включал mypy, ESLint, `tsc`, Clippy и golangci-lint; основной результат ниже использует полный стек.

## Основной тест: полный fast-набор на 51 файле

| Проверка и версия | Команда/область | Первый проход с новыми кэшами |
|---|---|---:|
| Git 2.53.0.697.g625c4fb2daa | Allowlist `research/*`, `feature/*`, `fix/*`, `dev`, `test`, `main`, затем `git check-ref-format --branch` | Включено в общий итог |
| Gitleaks 8.30.1 | `git --log-opts=HEAD~1..HEAD --no-banner --log-level error` по 10 000 строкам diff | 379 мс |
| Lizard 1.26.1 | `-C 10 --warnings_only` по 51 изменённому исходному файлу | 174 мс |
| Ruff 0.17.6 / Python 3.14.8 | `check --no-cache` и `format --check` по 10 `.py` файлам | 38 мс |
| mypy 2.4.1 | `mypy --cache-dir <fresh-cache>` по 10 `.py` файлам | 626 мс |
| ESLint 8.57.1 / typescript-eslint 7.18.0 / Node 26.13.1 | `eslint --no-cache --no-ignore` с TypeScript parser по 10 `.ts` файлам | 791 мс |
| TypeScript 5.9.3 | `tsc --noEmit --target ES2022 --module ESNext --moduleResolution bundler --strict` по 10 `.ts` файлам | 950 мс |
| Prettier 3.9.10 | `prettier --check` по 10 `.ts` файлам | 294 мс |
| Rust 1.99.1 (`cargo fmt`, rustfmt, Clippy) | `cargo fmt --check`; `cargo clippy --all-targets --all-features -- -D warnings` по 11 `.rs` файлам | 188 мс |
| Go 1.27.4 / golangci-lint 2.14.0 | `gofmt -d` и `golangci-lint run --timeout=1m` по 10 `.go` файлам | 157 мс |
| .NET SDK 10.0.404 | `dotnet format whitespace` и `dotnet format analyzers --severity warn` по 10 `.cs` файлам | 4,041 мс |

Последовательный полный проход на валидной ветке завершился успешно за **7,640 с** при свежих кэшах анализаторов/компиляторов. Медиана пяти повторов составила **6,652 с**. Запрещённая ветка `codex/bench` была отклонена allowlist-ом до запуска Git/линтеров за 0,004 мс; downstream checks — 0. Это укладывается в предел 10 секунд на данном компьютере и корпусе, с запасом примерно 2,36 с в первом проходе.

Lizard в пробе с CCN=11 и порогом `-C 10 --warnings_only` вывел предупреждение и вернул код 1. Это поддерживает gate-режим; в будущей общей обёртке следует сохранять warnings-only поведение, чтобы превышение порога не потерялось.

Из языковых правил набор команд следует рекомендациям [исследования инструментов](https://github.com/guility/agents-template/blob/research/quality-metrics/docs/reports/research/quality-metrics.md) и pinned тегам [Python](https://github.com/guility/agents-template-langs/blob/python/v2.0.0/AGENTS.md), [Node.js/TypeScript](https://github.com/guility/agents-template-langs/blob/nodejs/v1.0.1/AGENTS.md), [Rust](https://github.com/guility/agents-template-langs/blob/rust/v1.0.1/AGENTS.md), [Go](https://github.com/guility/agents-template-langs/blob/go/v1.0.1/AGENTS.md) и [C#](https://github.com/guility/agents-template-langs/blob/csharp/v1.0.2/AGENTS.md). Бенчмарк использует точные версии; не все они уже зафиксированы в языковых пакетах.

## Источники и непокрытые команды

- Git описывает `check-ref-format --branch` как проверку имени ветки: [git-check-ref-format](https://git-scm.com/docs/git-check-ref-format).
- Gitleaks предоставляет команды `git` и `dir`; параметры diff/staged и обхода worktree см. в [официальном README](https://github.com/gitleaks/gitleaks/blob/master/README.md) и [реализации Git-сканера](https://github.com/gitleaks/gitleaks/blob/master/cmd/git.go).
- Lizard принимает пути файлов и настраивает порог CCN через `-C`: [официальный CLI](https://github.com/terryyin/lizard/blob/master/docs/cli.rst).
- Документация команд: [Ruff check](https://docs.astral.sh/ruff/commands/check/), [Ruff format](https://docs.astral.sh/ruff/commands/format/), [mypy](https://mypy.readthedocs.io/en/stable/running_mypy.html), [ESLint CLI](https://eslint.org/docs/latest/use/command-line-interface), [TypeScript `noEmit`](https://www.typescriptlang.org/tsconfig/#noEmit), [Prettier CLI](https://prettier.io/docs/cli), [Clippy](https://doc.rust-lang.org/stable/clippy/usage.html), [rustfmt](https://rust-lang.github.io/rustfmt/), [golangci-lint](https://golangci-lint.run/docs/linters/), [gofmt](https://go.dev/src/cmd/gofmt/doc.go), [.NET format](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-format).
- Version references for added commands: [mypy 2.4.1 on PyPI](https://pypi.org/project/mypy/2.4.1/), [golangci-lint 2.14.0 release](https://github.com/golangci/golangci-lint/releases/tag/v2.14.0), and the pinned Node tool versions in [the language lockfile](https://github.com/guility/agents-template-langs/blob/nodejs/v1.0.1/template/pnpm-lock.yaml). These benchmark versions should be pinned in the project configs before rollout.
- Конфигурации измеренных ESLint правил и .NET SDK analyzers минимальны; внешние analyzer-плагины не подключались. Время установки инструментов, NuGet restore и сеть не измерялись. `dotnet format` использовал `--no-restore`; в проекте не было сторонних зависимостей.
- 10 000 строк синтетических функций не моделируют все проекты: число файлов, импорты, зависимости, правила линтеров, настройки analyzers, состояние CI cache и скорость runner меняют время. Полный multi-file проход укладывается в 10 секунд на указанном хосте, но это не гарантия для медленного или более крупного runner. Для CI следует хранить benchmark fixture и повторить порог на целевом runner перед обязательным rollout.
