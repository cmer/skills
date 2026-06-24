<!-- design-system:start -->
## Design system

This codebase uses a shadcn-backed design system documented at [`__ROUTE_PATH__`](__ROUTE_PATH__). shadcn is the source of truth for `components/ui`, component APIs, theme tokens, aliases, icon library, and installed component inventory.

When implementing UI:

1. **Use shadcn first.** Before writing frontend markup or styles, inspect `components.json` and run `npx shadcn@latest info --json` if the project shape is unclear. Use existing components from `components/ui` and examples from `__ROUTE_PATH__`.

2. **Install missing primitives through shadcn.** If a needed primitive is missing, add it with `npx shadcn@latest add <component>`. For existing files, check changes first with `npx shadcn@latest add <component> --diff` and ask before overwriting user-modified components.

3. **Use shadcn semantic tokens.** Prefer `bg-background`, `text-foreground`, `text-muted-foreground`, `border-border`, `bg-card`, `text-card-foreground`, `bg-primary`, `text-primary-foreground`, and related shadcn variables. Do not introduce raw hex values, competing token names, or one-off color systems.

4. **Do not fork component APIs casually.** Use the variant names and props provided by the installed shadcn component source. If the app needs a new reusable variant, update the shadcn component intentionally and document it on `__ROUTE_PATH__`.

5. **Use the shadcn sidekick skill.** Future agents should have the shadcn skill installed with `pnpm dlx skills add shadcn/ui`; it knows how to read `components.json`, inspect installed components, and follow shadcn conventions.

6. **Re-run `design-system` for system work.** Use this skill to refresh the reference page, apply a shadcn preset, re-scan migration candidates, or update the managed instructions.
<!-- design-system:end -->
