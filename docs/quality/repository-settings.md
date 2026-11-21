# Настройки защиты репозиториев

Файлы репозитория проверяют имена веток и порядок CI. Запрет прямого push в `main` задаётся в настройках хостинга и должен быть включён отдельно для обоих репозиториев.

## GitHub

Создать ruleset для `main` в `guility/agents-template` и `guility/agents-template-langs`:

- Require a pull request before merging.
- Require `branch-gate`, `fast-checks`, `prebuild-gates`, and `image-gate` for pull requests.
- Block force pushes and branch deletion.
- Leave bypass actors empty so administrators and CI actors cannot push commits directly to `main`.
- Permit GitHub Actions to update only `feature/quality-metrics`; its publisher job runs only after every protected-main quality gate succeeds.

`language-suites`, `mutator`, and metrics publication run after merge and cannot be required before the merge that starts them.

## GitLab

Protect `main` in both projects:

- Allowed to push and merge: **No one**.
- Allowed to merge: **Maintainers**.
- Allow force push: **off**.
- Require a successful pipeline before merge.
- Enable CI job-token pushes to the repository for `publish-quality-metrics`; it pushes only `feature/quality-metrics` after all protected-main gates succeed.

The fast branch gate accepts only `research/*`, `feature/*`, `fix/*`, `dev`, `test`, and `main`; `agents-template-langs` also accepts its five language branch exceptions.
