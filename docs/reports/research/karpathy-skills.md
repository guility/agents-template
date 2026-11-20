# Оценка практик Karpathy для агентских шаблонов

**Контекст:** [Wayfinder ticket #12](https://github.com/guility/agents-template/issues/12).
Изучены четыре принципа исходного [Karpathy skill](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/skills/karpathy-guidelines/SKILL.md#L178-L231),
ссылка проекта на [первичный пост Karpathy](https://x.com/karpathy/status/2015883857489522876)
и правила `agents-template` на ревизии `f4b9a55`.

## Рекомендация

Перенять принципы как короткую общую норму поведения, но не копировать skill
целиком в каждый документ. Это поведенческие правила, а не архитектурная модель
или языковой toolchain. Общая политика должна быть одной; роли задают действия
по этапам, ревьюеры — проверяемые признаки, языковые теги — конкретные команды и
соглашения целевого языка. Это соответствует текущему разделению общих и
языковых правил. ([AGENTS.md](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/AGENTS.md#L176-L188))

## Карта размещения

- **Think Before Coding.** Общее правило: называть значимые допущения и
  альтернативы, не угадывать решение, если ответ меняет его. Analyst выясняет
  актора, цель и ограничения; Architect объясняет trade-offs; Developer
  спрашивает только о блокирующей неоднозначности. Requirements reviewer
  проверяет тестируемость критериев, code reviewer — соответствие им.
- **Simplicity First.** Общее правило и Developer: минимальный код, нужный
  требованию, без спекулятивных функций или абстракций. Code reviewer отмечает
  gold plating и лишнюю сложность. Языковой тег добавляет только идиоматичный
  способ реализации и выбранные инструменты.
- **Surgical Changes.** Developer ограничивает diff задачей, сохраняет
  несвязанные код и комментарии, удаляет только созданные им сироты. Code
  reviewer проверяет связь изменений с требованием и посторонний diff. В языке
  остаются правила его форматтера и стиля.
- **Goal-Driven Execution.** Orchestrator задаёт этапы и проверки; Analyst —
  критерии приёмки; QA/Developer — цикл RED → GREEN → REFACTOR. Ревьюеры требуют
  доказательства выполнения критериев. В языке указываются команды проверок.

Не требовать полного плана для тривиальной однострочной правки: исходный skill
оставляет такие случаи на усмотрение агента. Обязательные локальные проверки и
гейты проекта при этом сохраняются. ([Karpathy skill](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/skills/karpathy-guidelines/SKILL.md#L173-L177),
[AGENTS.md](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/AGENTS.md#L118-L121))

Это распределение согласуется с уже заданными обязанностями Analyst по
уточнению задачи, Developer по TDD, QA по покрытию и ревьюеров по проверке
артефактов. Единое описание лучше разместить в небольшом общем документе внутри
`agents/best_practices/`, а из ролей и ревьюеров дать короткие ссылки, не
дублируя текст. ([Analyst](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/agents/roles/analyst/AGENT.md#L8-L13),
[Developer](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/agents/roles/developer/AGENT.md#L15-L21),
[code reviewer](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/agents/reviewers/code_reviewer.md#L8-L18),
[test reviewer](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/agents/reviewers/test_reviewer.md#L8-L21))

Языковые пакеты должны описывать лишь реализацию общей нормы: конкретные
форматтеры, тестовые и mutation-инструменты, команды запуска и соглашения об
ошибках. Например, Python и TypeScript используют разные toolchain, а общие
100% gates наследуются из основного репозитория. Не переносить в языковые теги
правила про допущения, scope diff или простоту. ([Python tag](https://github.com/guility/agents-template-langs/blob/python/v2.0.0/AGENTS.md#L5-L19),
[Node.js tag](https://github.com/guility/agents-template-langs/blob/nodejs/v1.0.1/AGENTS.md#L5-L16))

## Адаптация и границы

- **Термины домена:** сохранять единый язык предметной области в требованиях и
  коде. Языковой тег задаёт только регистр/формат идентификаторов и тестов, не
  переопределяет смысл доменных понятий. ([AGENTS.md](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/AGENTS.md#L185-L188))
- **DDD и простота совместимы:** убирать случайную сложность, но сохранять
  обязательные слои, доменные инварианты, ports и контракты. Простота не отменяет
  разделение ответственности. ([coding best practices](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/agents/best_practices/coding_best_practices.md#L207-L232))
- **Безопасность не ослаблять:** совет избегать обработки невозможных случаев
  нельзя применять к непроверенному вводу, отказам зависимостей или security
  controls. Сохраняются обработка ошибок, проверки секретов и зависимостей и
  статический анализ. ([Karpathy skill](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/skills/karpathy-guidelines/SKILL.md#L188-L198),
  [AGENTS.md](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/AGENTS.md#L112-L121),
  [coding rules](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/AGENTS.md#L190-L198))
- **Покрытие остаётся 100%:** test-first и верификация усиливают правила, но
  один регрессионный тест не завершает задачу. Сохраняются unit line/branch,
  integration, acceptance/e2e и применимые mutation gates, а также обязательные
  CI runners. ([AGENTS.md](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/AGENTS.md#L102-L110))
- **Ветки и CI неизменны:** проверять локально до MR; не ожидать branch pipeline
  и не ослаблять запуск только после merge в защищённую основную ветку. Прямые
  push в неё запрещены; deploy остаётся ручным после обязательных этапов и по
  immutable digest. ([AGENTS.md](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/AGENTS.md#L118-L143))
- **Лимиты файлов:** отчёт остаётся короче 100 строк; будущую общую норму держать
  компактной, не вставлять skill в каждую роль или языковой тег. Для файлов,
  подпадающих под ограничения, действуют максимум 300 строк, 95% до 100 строк и
  запрет искусственного дробления. ([AGENTS.md](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/AGENTS.md#L96-L100),
  [coding best practices](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/agents/best_practices/coding_best_practices.md#L494-L500))
- **Surgical edits с оговоркой:** autoformat запускается pre-commit. Минимизировать
  посторонний diff важно, но нужно пройти форматирование и соблюдать абсолютные
  лимиты. ([Karpathy skill](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/skills/karpathy-guidelines/SKILL.md#L199-L214),
  [AGENTS.md](https://github.com/guility/agents-template/blob/f4b9a55fc45f9b7ce2f5705f7bea6579053bd647/AGENTS.md#L118-L121))
