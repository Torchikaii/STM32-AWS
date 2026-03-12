# Plan Feature: Create Implementation Plan

## Purpose

Generate a detailed implementation plan for a specific feature or phase. The plan should be actionable with clear steps, dependencies, and validation criteria.

---

## Output

Write to: `$ARGUMENTS` (default: `.opencode/plans/phase-1-plan.md`)

If the `plans/` directory doesn't exist, create it first.

---

## Input

- **PRD.md** - For understanding scope and requirements
- **AGENTS.md** - For understanding coding standards
- Any existing plans for context

---

## Plan Template

### Phase X: [Feature/Component Name]

**Goal:** [One sentence describing what this phase accomplishes]

**Prerequisites:**
- [What must be done/ready before starting this phase]

---

#### Task 1: [Task Name]

**Description:** [Brief description of what to do]

**Files to modify:**
- `path/to/file1.ext`
- `path/to/file2.ext`

**New files to create:**
- `path/to/new-file.ext`

**Validation:**
- [ ] Specific validation step
- [ ] Another validation step

**Estimated complexity:** [Low/Medium/High]

---

#### Task 2: [Task Name]

[Same structure as Task 1]

---

## Instructions

### Step 1: Analyze Requirements

1. Read PRD.md to understand the feature scope
2. Read AGENTS.md for coding standards
3. Identify what needs to be built

### Step 2: Break Down into Tasks

1. Break the feature into logical, independent tasks
2. Each task should be:
   - Completable in a reasonable time
   - Validatable (you can verify it works)
   - Has clear file changes

### Step 3: Identify Dependencies

- Mark tasks that depend on other tasks
- Order tasks logically
- Identify blockers early

### Step 4: Define Validation

For each task, define concrete validation:
- "Run `npm test` and all tests pass"
- "API endpoint returns 200 with expected response"
- "Manual: Click button X and see result Y"

### Step 5: Write the Plan

Use the template above. Be specific:
- Use actual file paths
- Include exact commands to run
- Define measurable success criteria

---

## Quality Checklist

- [ ] All tasks have clear descriptions
- [ ] Each task has specific file changes listed
- [ ] Validation criteria are concrete and testable
- [ ] Dependencies are identified and ordered correctly
- [ ] Plan is realistic and achievable

---

## Notes

- Default to Phase 1 unless specified otherwise
- If the plan file already exists, ask whether to overwrite
- Keep plans focused - one phase per file
- Phase naming: phase-1-plan.md, phase-2-plan.md, etc.
