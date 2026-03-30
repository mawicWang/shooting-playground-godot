## Parallel Implementation

You are implementing a multi-file feature using a 3-phase parallel agent pattern. The user's feature request is in their last message.

---

### Phase 1: Plan

Launch ONE Plan agent (foreground, wait for result) with this exact prompt:

```
Feature request: [paste user's feature description here]

Analyze the codebase to find ALL files that need changes to implement this feature.
Group the files by logical coupling — files in the same signal chain, data flow, or system belong in one group.
Aim for 3-6 groups total. Do NOT create one group per file.

Output a structured plan in this format:

## Implementation Plan

### Group 1: [group_name]
Files: [list of file paths]
Responsibility: [what this group implements]
Interface contracts: [signals, function signatures, class names that other groups depend on]

### Group 2: ...

### Cross-group dependencies
[List any ordering constraints between groups]
```

Do not proceed to Phase 2 until you have the plan.

---

### Phase 2: Parallel Workers

For each group in the plan, launch one Agent in parallel (all in a single message). Each agent prompt should include:

1. The full plan from Phase 1 (all groups + interface contracts)
2. This group's specific files and responsibility
3. These instructions:
   - Read all files listed under your group before making any edits
   - Read any dependency files from other groups to verify the interface contracts
   - Edit ONLY the files assigned to your group
   - Do NOT edit files from other groups
   - Report a summary of every change you made

Launch all workers simultaneously. Wait for all to complete before Phase 3.

---

### Phase 3: Verify

1. **Consistency check** — search for cross-file references:
   - Signal names: verify every `emit_signal` / `SignalBus.*emit*` has a matching `signal` declaration
   - Function calls: verify called functions exist in their target files
   - Class names: verify `preload` / `load` paths and class_name references are correct

2. **Headless validation** — run:
   ```
   godot --headless --path . --script tests/validate.gd
   ```

3. **Report** — output a summary of:
   - Changes made per group
   - Consistency check results
   - validate.gd output

   Then wait for human confirmation before considering the task complete.
