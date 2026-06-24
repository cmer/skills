# Skills

A public, open-source Claude Code plugin marketplace maintained by Carl Mercier.

Contact: [foss@carlmercier.com](mailto:foss@carlmercier.com)

## Installation

This repo is a Claude Code plugin marketplace. Add it once:

```
/plugin marketplace add cmer/skills
```

Then install any of the skills below:

```
/plugin install <skill-name>@cmer-skills
```

## Skills

- [**Design System**](#design-system) — Scaffold a shadcn-backed React + Tailwind v4 design-system reference page and agent guardrails.
- [**Orchestrator Setup**](#orchestrator-setup) — Configure Rails projects for agent orchestrators with isolated worktrees, databases, ports, and lifecycle hooks.

### Design System

`design-system`

Scaffolds a shadcn-backed design system into a React + Tailwind v4 codebase: initializes or reuses shadcn, optionally applies a shadcn preset, installs a baseline set of official shadcn components, adds a live reference page at `/admin/design-system`, and writes managed instructions in `AGENTS.md`/`CLAUDE.md` so future agents use shadcn as the source of truth.

```
/plugin install design-system@cmer-skills
```

### Orchestrator Setup

`orchestrator-setup`

Configures a Rails project for agent orchestrators including Conductor, Paseo, Superset, Superconductor, Orca, and others. It detects existing workspace conventions, creates or updates orchestrator config files, scaffolds optional `bin/orchestrator/` lifecycle scripts, handles database isolation, manages dev-server ports, and documents the resulting setup for future agents.

```
/plugin install orchestrator-setup@cmer-skills
```

## License

MIT

## Attribution

This project was forked and adapted from [buildermethods/bm-skills](https://github.com/buildermethods/bm-skills).
