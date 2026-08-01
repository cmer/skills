---
name: configure-repo
description: Configure a GitHub repository with standard merge, Dependabot, and Actions settings.
argument-hint: "[OWNER/REPOSITORY] [--dry-run]"
disable-model-invocation: true
user-invocable: true
---

# Configure GitHub Repository

Run the bundled configuration script:

```text
"${CLAUDE_PLUGIN_ROOT}/scripts/configure-repo" $ARGUMENTS
```

Requirements:

- Pass the user's arguments through unchanged. With no arguments, let the script infer the repository from the current checkout.
- Do not add branch protection or rulesets.
- Do not replace the bundled script with direct `gh api` calls.
- If the command fails, report the exact failure and stop. Do not claim partial settings were applied.
- On success, report the configured repository and whether this was a dry run.
