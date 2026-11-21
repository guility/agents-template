# Шаблон агентской разработки с DDD и автоматизацией

[![CI/CD](https://github.com/guility/agents-template/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/guility/agents-template/actions/workflows/ci-cd.yml)

Этот репозиторий — меташаблон для разработки приложений с помощью AI-агентов. Он задаёт единый процесс от требований до релиза, архитектурные правила, роли участников, проверки качества и заготовки для нескольких языков.

Шаблон можно использовать с OpenCode, OpenHands, Claude Code, ChatGPT Codex, Cursor и Pi. Основная точка входа для всех инструментов — файл [`AGENTS.md`](./AGENTS.md).

## Что входит в шаблон

- DDD и чистая архитектура со слоями `domain`, `application`, `infrastructure` и `interface`.
- Последовательный процесс: требования → архитектура → тесты → реализация → ревью → релиз.
- Инструкции для аналитика, архитектора, QA, разработчика, оркестратора и ревьюеров.
- Атомарные требования и API-контракты в `docs/`, ADR в `docs/design/`.
- Unit, integration, e2e и мутационные тесты.
- Проверки сложности, безопасности, форматирования и трассируемости.
- GitHub Actions и GitLab CI.
- Языковые заготовки для Python, Node.js/TypeScript, Rust, Go и C#.

## Структура репозитория

```text
.
├── README.md
├── AGENTS.md
├── .gitignore
├── .gitlab-ci.yml              # Канонический файл GitLab CI
├── deploy/                     # Dockerfile и Compose-конфигурации
├── src/
│   ├── core/                   # Слои DDD
│   ├── templates/              # Языковые заготовки
│   └── tests/                  # Unit, integration, mutation, e2e
├── docs/                       # Требования, контракты, ADR и отчеты
├── scripts/                   # Bootstrap, CI, тестирование и анализ
└── agents/                    # Роли, ревьюеры и best practices
```

Скрытые служебные каталоги `.git`, `.github`, `.gitlab` и `.hooks` не входят в список видимых каталогов.

## Быстрый старт

### 1. Создайте проект из шаблона

Создайте новый репозиторий через кнопку **Use this template** на GitHub или клонируйте его:

```bash
git clone <repository-url> my-project
cd my-project
```

Все общие скрипты написаны для Bash. На Windows запускайте их из WSL или Git Bash.

### 2. Загрузите языковой пакет

Языковые правила и шаблоны публикуются отдельно в Git-тегах [`agents-template-langs`](https://github.com/guility/agents-template-langs). Теги и инструкции для каждой версии перечислены в README этого репозитория.

Загрузите нужный пакет в локальный кэш:

```bash
bash scripts/setup/fetch_language_templates.sh python
```

Замените `python` на `nodejs`, `rust`, `go` или `csharp`; значение `all` загрузит все текущие пакеты. Команды для конкретного шаблона указаны в его `README.md`.

Для отдельного production-проекта перенесите содержимое загруженной заготовки в проект, удалите неиспользуемые задания из CI и замените их рабочие каталоги на корень проекта. Это удобно поручить агенту отдельной задачей:

```text
Адаптируй этот меташаблон под Python-проект: сначала загрузи тег Python, затем перенеси
его каталог template в src/core,
сохрани AGENTS.md, agents и scripts, удали из CI задания других
языков и проверь локальные команды и GitHub Actions.
```

### 3. Подготовьте общие инструменты

Перед запуском изучите [`scripts/setup/bootstrap.sh`](./scripts/setup/bootstrap.sh): он устанавливает глобальные инструменты разработки и Git hooks. Если такое поведение подходит вашему окружению, выполните:

```bash
bash scripts/setup/bootstrap.sh
```

Хук также можно подключить вручную:

```bash
git config core.hooksPath .hooks
```

### 4. Проверьте, что агент видит правила

Откройте репозиторий именно из его корня и начните с безопасного запроса без изменений:

```text
Не изменяй файлы. Изучи AGENTS.md, опиши обязательный workflow,
архитектурные ограничения, требования к тестам и команды проверок.
```

В ответе должны появиться DDD, чистая архитектура, последовательность этапов, обязательное чтение `agents/best_practices/`, покрытие тестами и ограничение сложности не выше 10.

## Как устроена работа с агентами

Файлы в `agents/` являются инструкциями ролей, а не автоматически запущенными процессами. Поддерживаемые AI-инструменты загрузят общий `AGENTS.md`, но для конкретного этапа следует явно попросить прочитать файл нужной роли и соответствующий документ из `agents/best_practices/`.

## Дополнительные правила качества

- Структурные и строковые лимиты, Docker/Compose-пути, тестовые гейты и порядок GitLab CI обязательны и описаны в `AGENTS.md`.
- Для отклонений от рекомендуемых, но не абсолютных правил нужен ADR с владельцем и сроком пересмотра. Предел 300 строк абсолютный.
- Production pipeline не получает секреты в недоверенных MR; образы для релиза рекомендуется снабжать SBOM и подписью, а после deploy проверять health-check и иметь документированный откат.
- Нестабильные тесты не считаются пройденными после автоматического повторного запуска.

| Этап | Инструкция роли | Обязательный результат |
|---|---|---|
| Анализ | `agents/roles/analyst/AGENT.md` | один файл `docs/requirements/REQ-XXX.md` на требование |
| Проектирование | `agents/roles/architect/AGENT.md` | ADR в `docs/design/`, модель и контракты |
| Подготовка тестов | `agents/roles/qa/AGENT.md` | падающие тесты, описывающие ожидаемое поведение |
| Реализация | `agents/roles/developer/AGENT.md` | код, проходящий согласованные тесты |
| Ревью | `agents/reviewers/*.md` | замечания либо подтверждение соответствия |
| Координация | `agents/roles/orchestrator/AGENT.md` | контроль порядка этапов и возвратов |

Универсальный стартовый запрос для новой задачи:

```text
Изучи AGENTS.md и определи текущий этап workflow. Сначала загрузи языковой пакет
Python командой scripts/setup/fetch_language_templates.sh python. Работай с кодом в
src/templates/python. Перед действиями прочитай инструкцию нужной роли, языковые
правила из соответствующего тега и связанный документ из agents/best_practices. Не переходи к следующему этапу, пока артефакты
текущего этапа не готовы и не проверены. В конце перечисли изменённые файлы и
выполненные проверки.
```

Примеры запросов по этапам:

```text
# Требования
Работай как аналитик. Прочитай agents/roles/analyst/AGENT.md и
agents/best_practices/requirements_best_practices.md. Сформируй атомарное требование
REQ-001 с критериями Given-When-Then. Код пока не изменяй.

# Архитектура
Требование REQ-001 утверждено. Прочитай agents/roles/architect/AGENT.md и
agents/best_practices/architecture_best_practices.md. Подготовь ADR и контракты.
Реализацию не начинай.

# Тесты
Для утверждённых REQ-001 и ADR подготовь тесты по TDD. Прочитай
agents/roles/qa/AGENT.md и agents/best_practices/testing_best_practices.md. Покажи, что новые
тесты падают по ожидаемой причине.

# Реализация
Реализуй REQ-001 по утверждённому ADR и существующим падающим тестам. Прочитай
agents/roles/developer/AGENT.md и agents/best_practices/coding_best_practices.md. После
изменений запусти форматирование, линтер, тесты и анализ сложности.

# Ревью
Проведи ревью текущего diff по agents/reviewers/code_reviewer.md. Не изменяй
код. Сначала перечисли замечания по приоритету со ссылками на файлы и строки.
```

## Использование с OpenCode

[OpenCode](https://opencode.ai/docs/) автоматически ищет `AGENTS.md` в текущем каталоге и выше по дереву.

Установите OpenCode одним из способов, описанных в официальной документации. Например, через npm:

```bash
npm install -g opencode-ai
cd my-project
opencode
```

Дополнительная настройка шаблона не требуется. Не запускайте `/init`, если не хотите, чтобы OpenCode предложил изменить уже подготовленный `AGENTS.md`.

Первый запрос:

```text
Подтверди, что загрузил корневой AGENTS.md. Не изменяй файлы. Определи текущий
этап workflow и предложи следующий безопасный шаг.
```

Если нужны дополнительные инструкции, добавьте их в `opencode.json` через поле `instructions`, не дублируя содержимое `AGENTS.md`.

## Использование с OpenHands

[OpenHands](https://docs.openhands.dev/openhands/usage/cli/installation) использует корневой `AGENTS.md` как постоянный контекст репозитория.

Установка CLI через `uv`:

```bash
uv tool install openhands --python 3.12
cd my-project
openhands
```

На Windows OpenHands CLI следует запускать в WSL. При использовании OpenHands Cloud подключите репозиторий и убедитесь, что рабочая область открыта от его корня. Отдельный файл в `.openhands/` для чтения правил не нужен.

Запуск сразу с задачей:

```bash
openhands -t "Изучи AGENTS.md и проверь готовность проекта к этапу разработки"
```

Для специализированных процедур OpenHands можно дополнительно использовать `.agents/skills/<skill-name>/SKILL.md`, оставляя общие правила в `AGENTS.md`.

## Использование с Claude Code

[Claude Code](https://code.claude.com/docs/en/quickstart) автоматически читает `CLAUDE.md`, но не `AGENTS.md`. Создайте в корне проекта файл `CLAUDE.md` со следующим содержимым:

```markdown
@AGENTS.md
```

Так Claude Code будет использовать единый источник правил без копирования и рассинхронизации. При необходимости ниже импорта можно добавить только Claude-специфичные указания.

Запуск:

```bash
cd my-project
claude
```

Внутри сессии выполните `/context` и убедитесь, что `CLAUDE.md` присутствует среди загруженных файлов памяти. После этого используйте общий стартовый запрос из этого README.

На Windows импорт `@AGENTS.md` предпочтительнее символической ссылки: он не требует прав администратора или Developer Mode. Подробнее — в [официальной документации о памяти Claude Code](https://code.claude.com/docs/en/memory#agentsmd).

## Использование с ChatGPT Codex

[ChatGPT Codex](https://learn.chatgpt.com/docs/codex/cli) автоматически читает `AGENTS.md` до начала работы. Корневой файл уже подготовлен, поэтому `/init` запускать не нужно.

Установите Codex согласно официальной инструкции для своей платформы, откройте корень проекта и запустите:

```bash
cd my-project
codex
```

В Codex Desktop или IDE-расширении достаточно открыть папку репозитория как рабочую область. Для проверки контекста попросите:

```text
Не изменяй файлы. Перечисли инструкции, загруженные из AGENTS.md, и укажи,
какие файлы роли и best_practices нужно прочитать для реализации новой функции.
```

Codex объединяет инструкции от корня репозитория до текущего рабочего каталога. Если позже появятся вложенные `AGENTS.md`, более близкие к редактируемому коду правила должны уточнять, а не противоречить корневому файлу. Подробнее — в [официальной документации OpenAI по `AGENTS.md`](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

## Использование с Cursor

[Cursor](https://docs.cursor.com/context/rules-for-ai) поддерживает корневой `AGENTS.md` как простой вариант Project Rules. Дополнительный `.cursorrules` не нужен.

1. Откройте корень репозитория в Cursor.
2. В режиме **Ask** сначала запросите анализ проекта без изменений.
3. Для согласованной реализации переключитесь в **Agent** и передайте задачу вместе с нужным этапом workflow.
4. Перед применением проверьте diff и результаты тестов.

Пример запроса:

```text
Изучи AGENTS.md. Пока работай в режиме анализа: определи, какие требования и
ADR относятся к задаче, какие тесты потребуются и какой этап workflow сейчас
активен. Не изменяй файлы до согласования плана.
```

Cursor Agent можно использовать и из терминала:

```bash
curl https://cursor.com/install -fsS | bash
cd my-project
cursor-agent
```

CLI также читает корневой `AGENTS.md`. Для узких правил по каталогам или типам файлов можно дополнительно создать `.cursor/rules/*.mdc`; общие правила шаблона при этом оставляйте в `AGENTS.md`.

## Использование с Pi

[Pi](https://pi.dev/) загружает `AGENTS.md` при старте из текущего каталога, родительских каталогов и пользовательского каталога `~/.pi/agent/`.

Установка на Linux/macOS/WSL:

```bash
curl -fsSL https://pi.dev/install.sh | sh
```

Установка в PowerShell:

```powershell
powershell -c "irm https://pi.dev/install.ps1 | iex"
```

Запускайте Pi из корня проекта, чтобы область действия правил была однозначной:

```bash
cd my-project
pi
```

При первом запуске выберите провайдера и модель, затем проверьте контекст:

```text
Не изменяй файлы. Кратко перескажи корневой AGENTS.md и назови обязательные
артефакты этапов Analyst, Architect, QA и Developer.
```

Для этого шаблона не требуется отдельный `SYSTEM.md`: он заменяет или расширяет системный промпт Pi и нужен только для Pi-специфичного поведения.

## Полезные проверки

Проверка формата требований:

```bash
bash scripts/common/validate_requirements.sh
```

Проверка последовательности workflow:

```bash
bash scripts/common/check_workflow_status.sh
```

Перед проверкой выбранной заготовки загрузите соответствующий языковой пакет:

```bash
bash scripts/setup/fetch_language_templates.sh python
```

Анализ сложности выбранной заготовки:

```bash
python scripts/testing/complexity_analyzer.py \
  --root src/templates/python \
  --max-complexity 10 \
  --patterns '*.py'
```

Мутационное тестирование выбранной заготовки:

```bash
python scripts/testing/mutation_runner.py \
  --project-root src/templates/python \
  --language python \
  --generate-report
```

Матрица трассируемости:

```bash
python scripts/testing/traceability_matrix.py --root .
```

Полная пост-агентная валидация:

```bash
python scripts/common/validation/post_agent_validator.py --project-root .
```

GitHub и GitLab запускают быстрые проверки на каждый push в разрешённую ветку и полный SAST → build → security → unit gate на MR. После merge в защищённую `main` запускаются полные suites, mutation и release-проверки. Стадии GitLab заданы в `.gitlab/ci/`; открытый MR подавляет дубликат branch pipeline. Прямой push в `main` запрещён.

## Рекомендации по безопасной работе

- Запускайте агента из корня репозитория и проверяйте, какие инструкции он загрузил.
- Начинайте крупные задачи с режима анализа или плана.
- Не включайте безусловное автоматическое подтверждение команд для незнакомого репозитория.
- Не передавайте ключи и токены в запросах и не сохраняйте их в Git.
- Просматривайте `git diff` после каждого этапа.
- Не разрешайте переход к реализации без утверждённых требований, ADR и тестов.
- Перед коммитом запускайте проверки выбранного стека и pre-commit hook.
- Не просите агента одновременно менять требования, архитектуру и реализацию без явного решения оркестратора.

## Официальная документация интеграций

- [OpenCode: правила и `AGENTS.md`](https://opencode.ai/docs/rules/)
- [OpenHands: Skills и постоянный контекст](https://docs.openhands.dev/overview/skills)
- [Claude Code: `CLAUDE.md` и импорт `AGENTS.md`](https://code.claude.com/docs/en/memory#agentsmd)
- [ChatGPT Codex: CLI](https://learn.chatgpt.com/docs/codex/cli)
- [ChatGPT Codex: инструкции `AGENTS.md`](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [Cursor: Project Rules и `AGENTS.md`](https://docs.cursor.com/context/rules-for-ai)
- [Pi: установка и контекст проекта](https://pi.dev/)

## Лицензия

Перед публикацией проекта добавьте подходящий файл лицензии. Для открытых производных проектов можно использовать MIT License.

## Матрица качества

CI публикует таблицу «компонент × метрика» с badge-ссылками на отчёты. В каждой сводке отображаются измерения этого запуска. История метрик обновляется только успешным pipeline защищённой `main` в ветке `feature/quality-metrics`; значения `n/a` означают, что метрика для компонента не измерена. Общего рейтинга языков нет.

<!-- QUALITY-METRICS-START -->

| Component | Max CCN | CCN > 10 | Cognitive | Max depth | Max NLOC | Halstead V | Halstead D | Halstead E | Min MI | Line cov. | Branch cov. | Lint | Secrets | SAST | Dependency vulns | Mutation |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Common | [![Max CCN](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-max_ccn.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![CCN > 10](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-functions_over_10.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![Cognitive](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-cognitive_complexity_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![Max depth](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-nesting_depth_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![Max NLOC](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-max_nloc.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![Halstead V](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-halstead_volume_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![Halstead D](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-halstead_difficulty_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![Halstead E](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-halstead_effort_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![Min MI](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-maintainability_index_min.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![Line cov.](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-line_coverage.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![Branch cov.](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-branch_coverage.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![Lint](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-lint.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![Secrets](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-secrets.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![SAST](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-sast.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![Dependency vulns](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-dependency_vulnerabilities.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) | [![Mutation](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcommon-mutation_score.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/common.md) |
| Python | [![Max CCN](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-max_ccn.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![CCN > 10](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-functions_over_10.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![Cognitive](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-cognitive_complexity_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![Max depth](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-nesting_depth_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![Max NLOC](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-max_nloc.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![Halstead V](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-halstead_volume_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![Halstead D](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-halstead_difficulty_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![Halstead E](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-halstead_effort_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![Min MI](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-maintainability_index_min.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![Line cov.](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-line_coverage.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![Branch cov.](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-branch_coverage.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![Lint](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-lint.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![Secrets](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-secrets.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![SAST](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-sast.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![Dependency vulns](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-dependency_vulnerabilities.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) | [![Mutation](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fpython-mutation_score.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/python.md) |
| Node.js / TypeScript | [![Max CCN](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-max_ccn.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![CCN > 10](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-functions_over_10.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![Cognitive](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-cognitive_complexity_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![Max depth](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-nesting_depth_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![Max NLOC](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-max_nloc.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![Halstead V](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-halstead_volume_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![Halstead D](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-halstead_difficulty_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![Halstead E](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-halstead_effort_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![Min MI](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-maintainability_index_min.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![Line cov.](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-line_coverage.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![Branch cov.](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-branch_coverage.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![Lint](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-lint.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![Secrets](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-secrets.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![SAST](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-sast.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![Dependency vulns](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-dependency_vulnerabilities.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) | [![Mutation](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fnodejs-mutation_score.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/nodejs.md) |
| Rust | [![Max CCN](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-max_ccn.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![CCN > 10](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-functions_over_10.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![Cognitive](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-cognitive_complexity_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![Max depth](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-nesting_depth_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![Max NLOC](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-max_nloc.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![Halstead V](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-halstead_volume_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![Halstead D](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-halstead_difficulty_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![Halstead E](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-halstead_effort_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![Min MI](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-maintainability_index_min.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![Line cov.](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-line_coverage.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![Branch cov.](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-branch_coverage.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![Lint](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-lint.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![Secrets](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-secrets.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![SAST](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-sast.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![Dependency vulns](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-dependency_vulnerabilities.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) | [![Mutation](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Frust-mutation_score.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/rust.md) |
| Go | [![Max CCN](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-max_ccn.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![CCN > 10](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-functions_over_10.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![Cognitive](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-cognitive_complexity_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![Max depth](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-nesting_depth_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![Max NLOC](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-max_nloc.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![Halstead V](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-halstead_volume_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![Halstead D](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-halstead_difficulty_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![Halstead E](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-halstead_effort_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![Min MI](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-maintainability_index_min.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![Line cov.](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-line_coverage.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![Branch cov.](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-branch_coverage.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![Lint](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-lint.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![Secrets](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-secrets.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![SAST](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-sast.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![Dependency vulns](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-dependency_vulnerabilities.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) | [![Mutation](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fgo-mutation_score.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/go.md) |
| C# | [![Max CCN](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-max_ccn.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![CCN > 10](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-functions_over_10.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![Cognitive](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-cognitive_complexity_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![Max depth](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-nesting_depth_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![Max NLOC](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-max_nloc.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![Halstead V](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-halstead_volume_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![Halstead D](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-halstead_difficulty_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![Halstead E](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-halstead_effort_max.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![Min MI](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-maintainability_index_min.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![Line cov.](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-line_coverage.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![Branch cov.](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-branch_coverage.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![Lint](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-lint.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![Secrets](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-secrets.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![SAST](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-sast.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![Dependency vulns](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-dependency_vulnerabilities.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) | [![Mutation](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fguility%2Fagents-template%2Ffeature%2Fquality-metrics%2Fdocs%2Fquality%2Fbadges%2Fcsharp-mutation_score.json)](https://github.com/guility/agents-template/blob/feature/quality-metrics/docs/quality/reports/csharp.md) |

<!-- QUALITY-METRICS-END -->

Класс быстрых проверок и отдельные замеры каждого инструмента описаны в [`docs/quality/fast-check-benchmark.md`](./docs/quality/fast-check-benchmark.md).
