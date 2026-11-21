# Настройки защиты репозиториев

Файлы репозитория проверяют имена веток и порядок CI. Запрет прямого push в `main` задаётся в настройках хостинга и должен быть включён отдельно для обоих репозиториев.

## GitHub

Создать ruleset для `main` в `guility/agents-template` и `guility/agents-template-langs`:

- Require a pull request before merging.
- Require `branch-gate`, `fast-checks`, `prebuild-gates`, and `image-gate` for pull requests.
- Block force pushes and branch deletion.
- Leave bypass actors empty so administrators and CI actors cannot push commits directly to `main`.
- Permit GitHub Actions to update only `feature/quality-metrics`; its publisher job runs only after every protected-main quality gate succeeds.
- Require `branch-gate`, `fast-checks`, `prebuild-gates`, and `image-gate` on pull requests. Incremental push and post-merge status contexts use distinct names, so skipped MR gates on branch pushes cannot satisfy those requirements.
- The only manual workflow is `Deploy production`. Run it from protected `main`, select a successful protected-main `Quality pipeline` run ID, and configure the `production` environment with at least one required reviewer and a protected `DEPLOY_COMMAND` secret.

Fork pull requests use the `pull_request` event and the workflow's read-only `contents` and `pull-requests` token permissions. Do not pass repository secrets into these workflows.

`language-suites`, `mutator`, and metrics publication run after merge and cannot be required before the merge that starts them.

## GitLab

Protect `main` in both projects:

- Allowed to push and merge: **No one**.
- Allowed to merge: **Maintainers**.
- Allow force push: **off**.
- Require a successful pipeline before merge.
- Enable CI job-token pushes to the repository for `publish-quality-metrics`; it pushes only `feature/quality-metrics` after all protected-main gates succeed.

For fork merge requests, set the project API property `ci_allow_fork_pipelines_to_run_in_parent_project` to `false`. The root `workflow:rules` also drops parent-context fork pipelines while allowing the normal pipeline in the fork project. Keep both controls: a fork can change its own CI configuration, so its YAML rule cannot replace the project setting. A parent-context pipeline uses the fork's CI configuration together with the parent's CI/CD variables and job permissions, including the parent project's registry token. Keep production variables protected and run image builds on isolated, unprivileged runners.

The fast branch gate accepts only `research/*`, `feature/*`, `fix/*`, `dev`, `test`, and `main`; `agents-template-langs` also accepts its five language branch exceptions.
