# Changelog

All notable changes to this marketplace are tracked here. Versions follow a date-based scheme: `YYYY.MM.DD`.

## 2026.8.29

- `orchestrator-setup`: split workspace name resolution in two. `workspace_name` now reads what `config/database.yml` reads, in the same order, so shell scripts and Rails always resolve the same database; orchestrator name vars and the `basename "$PWD"` fallback moved to a setup-only `workspace_setup_name`.
- `orchestrator-setup`: teardown resolves the name the way setup did, so it drops the databases setup created even when `tmp/WORKSPACE_NAME` is gone.

## 2026.8.1

- Added the `github` plugin with the manually invoked `/github:configure-repo` skill.
- Bundled repository configuration for squash-only merging, merged-branch cleanup, Dependabot, and least-privilege Actions defaults.

## 2026.6.24

- Initial release as an unprefixed `design-system` plugin and skill.
- Removed Builder Methods branding and `bm-` naming.
