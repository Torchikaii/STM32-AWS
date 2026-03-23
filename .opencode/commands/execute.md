# Execute: Run Implementation Plan

## Purpose

Execute tasks from an implementation plan file. Process tasks sequentially, validate each step, and report progress.

---

## Input

Path to a plan file (e.g., `.opencode/plans/phase-1-plan.md`)

---

## Instructions

### Step 1: Read the Plan

Read the specified plan file completely. Understand:
- The phase goal
- All tasks and their order
- Dependencies between tasks
- Validation criteria for each task

### Step 2: Process Tasks Sequentially

Execute tasks **in order** - do not skip tasks unless:
- A dependency failed and blocks this task
- You explicitly flag and discuss with user

For each task:

1. **Understand the task** - Read the description, identify files to modify
2. **Read existing code** - Before changing anything, read the relevant files
3. **Implement** - Make the required changes
4. **Validate** - Run the validation steps defined in the plan
5. **Report** - Report task completion status

### Step 3: Handle Issues

If a task fails validation:
1. Attempt to fix the issue
2. If you can't fix it, stop and report:
   - What failed
   - What you tried
   - Why it didn't work

### Step 4: Don't Skip Steps

- Complete every task in order
- Don't skip validation steps
- Don't assume "it probably works" - verify explicitly
- Don't leave tasks partially complete

### Step 5: Output Execution Report

After execution (or when blocked), output a structured report:

```
## Execution Report: [Plan Name]

### Completed Tasks:
- [ ] Task 1 - ✅ COMPLETED
- [ ] Task 2 - ✅ COMPLETED

### Current Task:
- Task 3: [Name] - IN PROGRESS

### Blocked/Failed:
- Task 4: [Name] - BLOCKED
  - Reason: [explanation]
  - Attempted: [what you tried]

### Summary:
- Total: X tasks
- Completed: Y
- Remaining: Z
```

---

## Validation Requirements

For each task, you MUST validate:
1. Code changes compile/build without errors
2. Tests pass (if applicable)
3. Manual verification steps from the plan
4. No regressions introduced

---

## Progress Updates

Provide brief progress updates:
- When a task completes
- When you encounter a blocker
- When you need clarification

---

## Notes

- If no plan file is specified, ask for the path
- If the plan file doesn't exist, report error
- Execute ONLY the specified plan - don't branch to other phases
- After completing all tasks, summarize what was accomplished
