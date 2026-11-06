# Adding an orchestrator

An orchestrator is supported through two pieces: a reference file (what the tool does) and an adapter (how `bin/orchestrator/env` sees it). No generic managed file mentions any orchestrator by name, and none may start to.

## Gather the facts

Read the tool's docs, and its source when available. Don't infer from the name or from other tools:

1. **Detection**: which variables are set, in which contexts (lifecycle hooks, terminals, agent shells, the main checkout). Tools often differ per context, like Orca and T3 Code.
2. **Workspace path and name** variables, if any.
3. **Ports**: a port variable (the tool provides ports), or none (the project allocates a block).
4. **Port labels**: does the tool read `.superset/ports.json`, or discover listening ports itself?
5. **`.worktreeinclude`**: does the tool copy those files into new worktrees?
6. **Config file**: path, schema, lifecycle key names, the dev command, and whether the app must import it.
7. **Lifecycle**: setup and teardown hooks, and their working directory and environment.

## Write the adapter

`adapters/<id>.sh` defines every function of the contract at the top of the managed `env`:

```sh
orchestrator_<id>_detected        # true when active, from this tool's variables only
orchestrator_<id>_path            # workspace root; identical string in every context
orchestrator_<id>_name            # the tool's workspace name, or return 1
orchestrator_<id>_port            # tool-provided port, or return 1
orchestrator_<id>_main_checkout   # main checkout path, or return 1 (git fallback applies)
orchestrator_<id>_in_main_checkout  # true only when the context is known to be the main checkout
orchestrator_<id>_traits          # allocate-ports, port-labels, worktree-include, discover-port
```

Rules:

- Read only this tool's variables. An adapter that reads another tool's variables couples the two.
- Port allocations are keyed by `path`. If some context has no path variable, derive a path that equals the others (git top-level, normalized with `pwd -P`). The T3 Code adapter is the model.
- If the tool sets its variables in the main checkout too, implement `in_main_checkout`, so the main checkout keeps the shared databases.

## In the skill (supported for everyone)

1. Add `references/managed/bin/orchestrator/adapters/<id>.sh` with the managed stamp header.
2. Add `references/orchestrators/<id>.md`, following the existing files (Adapter, Environment variables, Config file, Port strategy, Lifecycle, Custom dev command, Workspace name resolution, Notes).
3. Add a row to the supported-orchestrators table and the Phase 3 table in `SKILL.md`, and add the id to the canonical order in Phase 5a and in `references/examples/orchestrator-config.sh`.
4. Add a scenario to `SCENARIOS` in `scripts/orchestrator-check` that covers every context from "Gather the facts", including the main checkout if the tool's variables appear there.
5. Prove it: record a fixture project with all other adapters enabled, enable the new one, record again, and compare with `--allow <id>`. It must print `No unexpected changes.` Then read the new scenario's rows: setup databases, ports, names, teardown.

## In a project only

When the user needs the orchestrator now and the skill doesn't ship it, write the adapter as a **project adapter**: `bin/orchestrator/adapters/<id>.sh` without the managed stamp, then list `<id>` in `ORCHESTRATOR_ADAPTERS`. `orchestrator-install` keeps project adapters as is. The check has no scenario for it, so it proves only that the other orchestrators didn't change. Test the new one by running setup, `dev-port` and teardown with the tool's variables exported. Suggest contributing the adapter to the skill afterwards.
