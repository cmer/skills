# Changelog

All notable changes to this marketplace are tracked here. Versions follow a date-based scheme: `YYYY.MM.DD`.

## 2026.11.4

- `orchestrator-setup`: added T3 Code (`t3.json` actions, a 10-port block per worktree, `.worktreeinclude` copied by `bin/orchestrator/worktree-include` because T3 Code doesn't copy it).
- `orchestrator-setup`: managed layout. Generic scripts (`env`, `port`, `dev-port`, `worktree-include`, one `adapters/<id>.sh` per orchestrator) are installed verbatim by `scripts/orchestrator-install`; project settings moved to `bin/orchestrator/config`; `setup`/`teardown` call `workspace_prepare_setup`, `workspace_begin_teardown`, `workspace_finish_teardown`.
- `orchestrator-setup`: `scripts/orchestrator-check` records what the scripts do for every orchestrator context in a sandbox and compares recordings, so adding an orchestrator or upgrading can be proven not to change the others.
- `orchestrator-setup`: upgrade path from hand-adapted scripts, verified against every earlier release of the examples. Worktree-folder teardown now releases the port block (it exited before the release step).

## 2026.8.29

- `orchestrator-setup`: split workspace name resolution in two. `workspace_name` now reads what `config/database.yml` reads, in the same order, so shell scripts and Rails always resolve the same database; orchestrator name vars and the `basename "$PWD"` fallback moved to a setup-only `workspace_setup_name`.
- `orchestrator-setup`: teardown resolves the name the way setup did, so it drops the databases setup created even when `tmp/WORKSPACE_NAME` is gone.

## 2026.8.1

- Added the `github` plugin with the manually invoked `/github:configure-repo` skill.
- Bundled repository configuration for squash-only merging, merged-branch cleanup, Dependabot, and least-privilege Actions defaults.

## 2026.6.24

- Initial release as an unprefixed `design-system` plugin and skill.
- Removed Builder Methods branding and `bm-` naming.
