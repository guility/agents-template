# Измерение быстрых push-проверок на 10 000 строк

Дата: 2026-11-21. Источник репозитория: `origin/main` на `f4b9a55`. Замеры выполнены в отдельной временной Git-фикстуре в `/tmp/fastcheck-corpus`.

## Методика и ограничения

- Фикстура содержит ровно 10 000 физических строк: по 2 000 Python, TypeScript, Rust, Go и C#. Исходники синтетические, без внешних зависимостей; все пять файлов добавлены одним commit для измерения commit diff.
- Система: PikaOS 4, Linux 7.3.1-pikaos x86_64; Intel Core i5-13600K (20 логических CPU). Замер wall time через `perf_counter_ns`, включая запуск процесса.
- Для строк ниже: первый замер в серии и медиана следующих пяти запусков. Это не холодный запуск диска: страницы инструментов могли быть в кэше ОС. Для проверки ветки сделано 10 повторов.
- Успешный проход означает только отсутствие срабатываний на синтетической фикстуре. Замеры не включают реальный код, зависимости, сборку, тесты, сетевой доступ или другие фоновые нагрузки.

## Результаты

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

Последовательный push-fast набор на валидной ветке проверял имя, полный worktree Gitleaks, Lizard, Ruff check/format, Prettier, rustfmt, gofmt, `dotnet format whitespace` и SDK analyzers для C#. Код завершения — 0 во всех шести запусках: первый 5,708 с, медиана следующих пяти 5,619 с. Отдельный набор без C# analyzers занял 966 мс в первом запуске и 976 мс медианно на следующих пяти. Проверка запрещённой ветки `codex/bench` завершилась до инструментов за 0,004 мс; downstream checks — 0. `git check-ref-format` отдельно также отсеял синтаксически невалидное `research//invalid`, после чего marker следующего шага не создался.

Lizard в пробе с CCN=11 и порогом `-C 10 --warnings_only` вывел предупреждение и вернул код 1. Это поддерживает gate-режим; в будущей общей обёртке следует сохранять warnings-only поведение, чтобы превышение порога не потерялось.

Из языковых правил командный набор выбран по закреплённым тегам [Python](https://github.com/guility/agents-template-langs/blob/python/v2.0.0/AGENTS.md), [Node.js/TypeScript](https://github.com/guility/agents-template-langs/blob/nodejs/v1.0.1/AGENTS.md), [Rust](https://github.com/guility/agents-template-langs/blob/rust/v1.0.1/AGENTS.md), [Go](https://github.com/guility/agents-template-langs/blob/go/v1.0.1/AGENTS.md) и [C#](https://github.com/guility/agents-template-langs/blob/csharp/v1.0.2/AGENTS.md).

## Источники и непокрытые команды

- Git описывает `check-ref-format --branch` как проверку имени ветки: [git-check-ref-format](https://git-scm.com/docs/git-check-ref-format).
- Gitleaks предоставляет команды `git` и `dir`; параметры diff/staged и обхода worktree см. в [официальном README](https://github.com/gitleaks/gitleaks/blob/master/README.md) и [реализации Git-сканера](https://github.com/gitleaks/gitleaks/blob/master/cmd/git.go).
- Lizard принимает пути файлов и настраивает порог CCN через `-C`: [официальный CLI](https://github.com/terryyin/lizard/blob/master/docs/cli.rst).
- Документация команд: [Ruff check](https://docs.astral.sh/ruff/commands/check/), [Ruff format](https://docs.astral.sh/ruff/commands/format/), [Prettier CLI](https://prettier.io/docs/cli), [rustfmt](https://rust-lang.github.io/rustfmt/), [gofmt](https://go.dev/src/cmd/gofmt/doc.go).
- Из C# измерены только SDK `dotnet format` и встроенные Roslyn analyzers на минимальном проекте; дополнительные проектные analyzers, ESLint/tsc, mypy, Clippy, goimports/golangci-lint и остальные линтеры из языковых правил не измерялись. Поэтому 5,6 с — результат лишь проверенного набора команд, а не подтверждение, что полный набор всех текущих языковых средств укладывается в 10 с. Для `dotnet format` Microsoft описывает restore/build/analyzer behavior и параметры ограничения файлов в [официальной документации](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-format).
