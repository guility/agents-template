# Правила агентской разработки

Этот файл задаёт общие обязательные правила. Ролевые обязанности и этапы работы описаны в [`agents/workflow.md`](agents/workflow.md), лучшие практики — в [`agents/best_practices/`](agents/best_practices/). Перед работой изучи соответствующую роль и практику. Правила языка загружаются из закреплённого тега `agents-template-langs`.

## Общие принципы

- Используй ubiquitous language, DDD и Dependency Rule чистой архитектуры. Межкомпонентное взаимодействие задавай через версионируемые контракты.
- Применяй четыре принципа Think Before Coding, Simplicity First, Surgical Changes и Goal-Driven Execution из [`coding_best_practices.md`](agents/best_practices/coding_best_practices.md). Они не отменяют требования безопасности, архитектуры, тестирования и обязательные CI-гейты. Для очевидной тривиальной правки допустимо не писать отдельный план.
- Предпочитай простые решения, изменяй только относящиеся к цели файлы, явно фиксируй допущения и проверяй заявленный критерий результата.

## Структура и размер

- Видимый корень проекта: `README.md`, `AGENTS.md`, `.gitignore`, `.gitlab-ci.yml` и каталоги `deploy`, `src`, `docs`, `scripts`, `agents`. Скрытые служебные каталоги исключены из структурного подсчёта.
- В одном каталоге — не более 8 файлов и 5 подкаталогов непосредственно на этом уровне.
- Исходный код, тесты, скрипты и редактируемая вручную конфигурация, включая CI, Dockerfile и Compose, — не более 300 физических строк на файл; не менее 95% таких файлов — до 100 строк. Lock-файлы, генерация, vendored-код, зависимости и сборочные выходы исключены.
- Разбивай большие файлы по ответственности, сохраняя связность. Не дроби код только ради метрики.

## Тестирование и безопасность

- Для unit, integration, mutation и e2e suites CI требует 100% согласованного покрытия; отсутствующая или пустая обязательная suite — ошибка. Unit требуют 100% line и branch coverage там, где инструмент поддерживает метрику; Go сохраняет 100% statement gate, а line/branch отображаются `n/a` по [DECISION-002](docs/design/DECISION-002-go-coverage.md). Ограничение branch coverage Rust зафиксировано в [DECISION-001](docs/design/DECISION-001-rust-branch-coverage.md). Integration покрывают задокументированные пути, e2e — критерии приёмки, mutation — применимые мутации.
- Полный GitLab pipeline запускает каждый тип suite отдельным обязательным скриптом `scripts/ci/test-{unit,integration,mutation,e2e}.sh`; отсутствующий runner или пропуск suite завершает pipeline ошибкой.
- Тесты независимы, воспроизводимы и не обращаются к production. Используй Testcontainers для изолированных интеграций.
- Секреты в коде запрещены. Gitleaks проверяет исходящие коммиты перед push и в CI. Зависимости и построенные образы сканируются на уязвимости; Semgrep выполняет SAST.
- Для поддерживаемых языков Dryer обязателен как отчёт о кандидатах на дублирование. Uncle Bob Mutator обязателен в post-merge mutation suite для Python, TypeScript/JavaScript, Rust и Go; для C# он не применяется. APS остаётся справочным документом, SCRAP и AgNesse не входят в стандартный toolchain.

## Сложность и метрики

- Lizard ограничивает цикломатическую сложность значением 10 на функцию. Локальный отчёт запускается командой `bash scripts/common/complexity-check.sh`.
- В CI и quality-матрице измеряются max CCN и число превышений, Cognitive Complexity, max nesting depth, max NLOC, максимальные Halstead Volume, Difficulty и Effort, а также минимальный Maintainability Index по единой зафиксированной формуле. Gate действует только на CCN выше 10; остальные показатели информационные.
- Метрики покрытия, lint, секретов, SAST, уязвимостей зависимостей и mutation score публикуются как badges в матрице «компонент × метрика». Отсутствующее значение обозначается `n/a`; общий рейтинг языков не строится. Источник — `docs/quality/quality-metrics.json` и ссылки на отчёты.
- Зафиксированные версии и выбор инструментария описаны в [`docs/quality/toolchain.md`](docs/quality/toolchain.md).

## Ветки, hooks и CI

- Общие допустимые ветки: `research/*`, `feature/*`, `fix/*`, `dev`, `test`, `main`. В `agents-template-langs` также допустимы постоянные ветки `python`, `nodejs`, `rust`, `go`, `csharp`.
- Первый шаг каждого push pipeline и pre-push hook — валидация имени ветки. Неверное имя немедленно завершает проверку.
- Быстрый набор на каждый push включает только инструменты, измеренные быстрее 0,5 секунды на 10 000 строк: Gitleaks diff, Lizard CCN на изменённых файлах, Ruff check/format, Prettier, `cargo fmt`, Clippy, `gofmt` и `golangci-lint` для затронутых языков. C# быстрых проверок в этом классе нет. Измерения записаны в `docs/quality/fast-check-benchmark.md`.
- MR pipeline запускает полный Semgrep SAST и метрики, Dryer, build `production` → `tests`, Trivy по собранным образам и unit suite из того же `tests` image ID. Для fork MR сборка и проверки должны быть credentialless.
- После merge в защищённую `main` запускаются integration/e2e, native и Mutator mutation, оставшиеся security/release checks и публикация матрикса в README. README обновляет только успешный protected-main pipeline.
- GitHub Actions: fast checks на branch push, MR gate на `pull_request`, post-merge на push в `main`; tag и schedule pipelines выключены. GitLab использует MR pipeline и `workflow:rules`/`CI_OPEN_MERGE_REQUESTS` для подавления дубликатов, а post-merge — push в default branch.
- `main` должна быть защищена от прямого push. Production credentials и deploy environments доступны только protected pipeline. Deploy — ручной и использует неизменяемый registry digest.
- Настройки обязательной защиты `main` для GitHub и GitLab описаны в [`repository-settings.md`](docs/quality/repository-settings.md); их нужно применить в административных настройках обоих хостинговых проектов.

## Docker и языковые пакеты

- Прикладные Dockerfile размещаются в `deploy/Dockerfiles/`, Compose — в `deploy/composes/`. Каждый Dockerfile предоставляет `production` и `tests` targets; `tests` объявляется после и наследуется от `production`, добавляя инструменты unit-тестирования. Для прикладных образов tests target предоставляет `/usr/local/bin/run-unit-tests`.
- Языковой пакет содержит свой пример Dockerfile в `template/deploy/Dockerfiles/Dockerfile`; CI строит targets из каждого закреплённого языкового тега и запускает unit suite внутри созданного tests image. Проверка image ID гарантирует, что тестируется именно ранее собранный образ.
- Тестовые Compose-конфигурации используют deploy-конфигурацию через overlays.
- Языковые правила и шаблоны хранятся только в соответствующей ветке и immutable теге [`agents-template-langs`](https://github.com/guility/agents-template-langs). Общие правила в языковых пакетах не дублируются.
- Используй lock-файл из языка. Версии Git-тегов закреплены в `scripts/setup/fetch_language_templates.sh`; новый тег `<language>/v<major>.<minor>.<patch>` выпускай только после проверки и никогда не перемещай уже опубликованный тег.
- `src/templates/` — временный кэш; его содержимое не коммитится.

## Обязательное поведение

Не обходи архитектурные контракты, не игнорируй ошибки, не добавляй новый код без тестов и не повышай CCN выше 10. При обнаружении нарушения зафиксируй проблему и план исправления, не усугубляя её новым кодом.
