---
name: design-system
description: Scaffold and maintain a shadcn-backed design-system reference page and agent guardrails.
---

# shadcn Design System Builder

You are guiding a builder through setting up a shadcn-backed design system in a React + Tailwind v4 codebase. shadcn is the source of truth for `components/ui`, theme tokens, aliases, component APIs, icons, and presets. This skill owns the app-specific reference page, route wiring, migration scan, and managed agent instructions.

The output is:

- A working shadcn setup (`components.json`, theme CSS, aliases, and installed shadcn components).
- A live reference page at `/admin/design-system` by default.
- Managed instructions in `AGENTS.md` and/or `CLAUDE.md` telling future agents to use shadcn first.
- A migration scan for existing UI that is not yet using shadcn.

## Core principles

1. **Follow shadcn as closely as possible.** Do not create custom `components/ui` primitives when shadcn already has a component. Use `npx shadcn@latest add`, `info`, `docs`, `view`, `add --diff`, and `preset` commands.
2. **Use shadcn defaults unless the user provides a preset.** If the user gives a preset code, validate it with `npx shadcn@latest preset decode <code> --json` and apply it through shadcn. Do not invent or persist a custom preset field outside shadcn-managed files.
3. **Treat the shadcn skill as a required sidekick.** This repo's plugin manifest does not support dependency metadata, so document and enforce this behavior in chat and agent instructions. Tell the user to install it with `pnpm dlx skills add shadcn/ui` when it is not already available.
4. **The reference page documents the installed system.** It should import official shadcn components from the project's configured alias and use shadcn semantic utilities (`bg-background`, `text-foreground`, `text-muted-foreground`, `border-border`, `bg-card`, etc.).
5. **Do not overwrite user-modified UI silently.** Use `shadcn add --diff`, skip conflicting files, or ask before overwriting.

## Phase 0 - Detect target codebase state

Inspect the codebase before asking questions.

### Framework detection

Use the first matching framework:

1. **Vite** - `vite.config.ts` / `vite.config.js` / `vite.config.mts` exists.
2. **Next.js app router** - `next.config.*` exists and `app/` exists.
3. **Next.js pages router** - `next.config.*` exists and `pages/` exists, with no `app/`.
4. **Rails + Inertia** - `Gemfile` contains `inertia-rails` or `inertia_rails` and `app/frontend/` or `app/javascript/pages/` exists.
5. **Rails + react-on-rails** - `Gemfile` contains `react_on_rails`.
6. **Unknown React** - continue, but print manual route/setup snippets instead of editing unknown router files.

### Tailwind v4 check

Look for one of:

- `@import "tailwindcss"` in CSS under `src/`, `app/`, `app/javascript/`, or `app/frontend/`.
- `@tailwindcss/vite`, `@tailwindcss/postcss`, or `tailwindcss@^4` in `package.json`.

If none is found, or if Tailwind v3 markers are found (`tailwind.config.js`, `@tailwind base;`), stop:

> This skill requires Tailwind CSS v4 or later. Please upgrade first - see https://tailwindcss.com/docs/upgrade-guide - and re-run.

### shadcn state

Check:

- `components.json`
- `npx shadcn@latest info --json`
- `npx shadcn@latest preset resolve --json`
- Existing `components/ui/*`
- Existing design-system route
- Existing `design-system:start` markers in `AGENTS.md` or `CLAUDE.md`

If `components.json` exists, treat shadcn as already initialized and use its aliases. If it is missing, initialize shadcn in Phase 2.

State a brief detection summary before continuing. Example:

> Detected: Vite + React + Tailwind v4. shadcn is not initialized. I'll initialize shadcn with defaults unless you provide a preset code, then add the design-system reference page.

## Phase 1 - Confirm route

Default route: `/admin/design-system`.

Use AskUserQuestion:

- Question: "Where should the design system reference page live?"
- Options: `Use /admin/design-system (recommended)`, `Use /design-system`, `Use /styleguide`

If the user picks Other and provides a custom path, accept it if it starts with `/`.

Save the value as `routePath`.

## Phase 2 - Configure shadcn

### 2a. Companion skill

Tell the user:

> This design-system skill relies on shadcn as the source of truth. If the shadcn skill is not installed in this environment, install it with `pnpm dlx skills add shadcn/ui` so future agents can inspect `components.json` and use shadcn correctly.

Do not stop only because the shadcn skill is absent; continue using the shadcn CLI.

### 2b. Preset choice

Ask whether to use a preset only when shadcn is missing or the user explicitly asked to change theme:

- Question: "Do you want to use a shadcn preset code?"
- Options:
  - `Use shadcn defaults (recommended)` - initialize/apply the current shadcn default.
  - `Use a preset code` - ask for the code, then validate and apply it.
  - `Keep current shadcn setup` - only available when `components.json` exists.

If the user provides a preset code:

1. Run `npx shadcn@latest preset decode <code> --json`.
2. If decode fails, ask for a different code or continue with shadcn defaults.
3. If shadcn is missing, run `npx shadcn@latest init --base radix --preset <code> -y`.
4. If shadcn already exists, run `npx shadcn@latest apply <code> --yes`.

If no preset is provided:

- If shadcn is missing, run `npx shadcn@latest init --base radix --preset nova -y`. `nova` is the current default shadcn preset name in the CLI's project-creation flow.
- If shadcn exists, do not change the theme.

For Rails or unknown layouts where `init` cannot infer paths cleanly, create or update `components.json` only with explicit user confirmation. Prefer printing the recommended shadcn setup command and manual alias guidance instead of guessing.

### 2c. Install baseline components

Install the baseline components that the reference page documents:

```bash
npx shadcn@latest add button button-group badge card input textarea label field checkbox radio-group select native-select dialog dropdown-menu table separator tabs toggle toggle-group switch sheet tooltip -y
```

If a file already exists, do not use `--overwrite` by default. Use:

```bash
npx shadcn@latest add <component> --diff
```

Ask before overwriting any existing user-modified `components/ui/*` file.

## Phase 3 - Write the reference page

Resolve target paths using the detected framework and shadcn aliases from `components.json`.

Canonical targets:

| Logical path | Vite target |
| --- | --- |
| route page | `src/admin/design-system/page.tsx` |
| reference component | `src/components/design-system/DesignSystem.tsx` |

Framework overrides:

- **Next.js app router** - route page at `app/admin/design-system/page.tsx`; component at `components/design-system/DesignSystem.tsx` unless `src/` is used.
- **Next.js pages router** - route page at `pages/admin/design-system.tsx`.
- **Rails + Inertia** - route page at `app/frontend/pages/admin/design-system.tsx` or `app/javascript/pages/admin/design-system.tsx`, matching project convention.
- **Rails + react-on-rails** - write the component and print a manual registration snippet.
- **Unknown React** - write the component under `src/components/design-system/` if `src/` exists, otherwise `components/design-system/`, and print a manual route snippet.

Copy `references/page/DesignSystem.tsx` into the component target. Substitute:

| Token | Replacement |
| --- | --- |
| `__ROUTE_PATH__` | chosen route path |
| `@/components/ui/` | the configured shadcn UI alias from `components.json` |
| `@/lib/utils` | the configured utils alias from `components.json`, if needed |

Create the route entry file for the framework. It should import and render `DesignSystem`.

For app-router/client environments, make sure a `"use client"` directive is present because the reference page uses interactive shadcn components.

## Phase 4 - Register the route

Use the corresponding snippet under `references/routing/`.

- Vite + React Router: edit the existing `<Routes>` block when detection is clean.
- Next.js app/pages router: file-based routing, no router edit needed.
- Rails + Inertia: add the route/controller entry that matches the app's existing Inertia route pattern.
- Rails + react-on-rails or unknown: print a manual snippet and exact file path where it should be registered.

## Phase 5 - Update agent instructions

Open `AGENTS.md` if it exists, else `CLAUDE.md` if it exists, else create `AGENTS.md`. If both exist, update both.

Before appending the managed block, reconcile existing UI/styling directives outside `design-system` markers:

- Remove directives that hardcode a competing palette, typography system, or custom component API.
- Rewrite useful non-visual intent so it defers visual conventions to shadcn and the design-system route.
- Ask before changing ambiguous instructions.

Append or replace the block from `references/agent-instructions.md`, substituting `__ROUTE_PATH__`.

## Phase 6 - Scan for existing UI to migrate

After the reference page is in place, scan user-facing UI outside `components/ui/` and `components/design-system/`.

Look for:

- Raw `<button>`, `<input>`, `<select>`, `<textarea>`, dialogs, dropdowns, tabs, tables, switches, and cards that should use shadcn components.
- Tailwind utilities that bypass shadcn semantic tokens, especially raw grays, hardcoded brand colors, or raw hex styles.
- Local custom component systems that duplicate shadcn.

Group findings by broad bucket:

- Pages / routes
- Layouts / shells / navigation
- Forms / inputs
- Buttons / links
- Cards / data display
- Overlapping custom primitives

If findings exist, ask:

- Question: "Want me to migrate existing UI to shadcn?"
- Options:
  - `Yes, migrate everything now`
  - `Yes, but just one bucket`
  - `Not now`

Do not auto-migrate without explicit opt-in.

When migrating, preserve behavior and copy. Replace visual implementation with shadcn components and semantic tokens only.

## Phase 7 - Wrap up

Print a short summary:

- The route URL.
- shadcn status: initialized, existing config reused, or preset applied.
- Components installed or skipped.
- Agent instruction files updated.
- Migration scan result.
- Companion skill reminder: `pnpm dlx skills add shadcn/ui`.

## Reference page requirements

The page must:

- Use official shadcn components and semantic theme utilities.
- Document the installed shadcn component API, not custom variants.
- Include at least: colors/theme tokens, radius, typography notes, buttons, forms, selection controls, overlays, navigation/menu components, data display, cards, tabs, and tooltips.
- Link to shadcn docs and show `shadcn` CLI commands for adding/diffing components.
- Avoid custom `components/ui` exports, custom token names, and custom variant systems.

## shadcn command reference

Use the current CLI command surface:

```bash
npx shadcn@latest init --base radix --preset nova -y
npx shadcn@latest init --base radix --preset <code> -y
npx shadcn@latest apply <code> --yes
npx shadcn@latest add <component> -y
npx shadcn@latest add <component> --diff
npx shadcn@latest docs <component>
npx shadcn@latest info --json
npx shadcn@latest preset decode <code> --json
npx shadcn@latest preset resolve --json
```
