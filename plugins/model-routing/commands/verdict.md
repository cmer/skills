---
description: Get a ship / fix-first / rethink verdict from the Fable skeptic on the current branch's work before committing, merging, or reporting done.
---

Run the commitment-boundary check on the current work.

1. Determine what is being committed to: the accumulated branch diff against the target branch (`git diff <target>...HEAD` plus uncommitted changes), or, if the argument names a plan or design doc, that document. Arguments: $ARGUMENTS
2. Dispatch the `fable-skeptic` agent with: the stated goal of the work (from the conversation, the plan, or the branch's commits), the diff or document, and any verification commands it may run.
3. Relay the verdict and findings verbatim — do not soften `fix-first` or `rethink`. If the verdict is `fix-first`, list the blocking findings as the immediate next steps. If `rethink`, stop and surface it to the user before any further implementation.

Do not skip the dispatch and review the work yourself — the point of the check is fresh Fable eyes, not self-review.
