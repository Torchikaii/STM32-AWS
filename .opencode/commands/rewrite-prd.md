# Rewrite PRD: Regenerate Product Requirements Document

## Purpose

Rewrite PRD.md based on current project progress. Use this command periodically to keep PRD accurate without appending indefinitely.

---

## Output

Overwrites: `.opencode/PRD.md`

---

## Instructions

### Step 1: Read Current PRD

Read `.opencode/PRD.md` to understand:
- Original project overview
- Tech stack
- Current phase tracking
- Completed vs pending sections

### Step 2: Check Progress

Read `.opencode/progress/current.md` to identify:
- Current phase number
- Completed tasks (marked with ✅)
- In-progress tasks
- Any blockers

### Step 3: Explore Project Structure

1. List root directory: `ls -la`
2. Check for new folders since last PRD
3. Read any new `<foldername>.README.md` files

### Step 4: Check for Other Changes

Ask user: "Any other changes to the project I should know about that aren't reflected in the files?"

Examples:
- New dependencies added
- Architecture changes
- Third-party integrations

### Step 5: Rewrite PRD

Maintain original structure but:

1. **Executive Summary** - Update to reflect current state
2. **Current Phase** - Update to reflect progress
3. **Completed Features** - Move from "In Scope" to completed section
4. **Implemented Features** - Document what was actually built
5. **Project Structure** - Update to match current state
6. **Keep** - Tech stack, core principles (unless changed)

### Step 6: Quality Check

- [ ] Current phase reflected
- [ ] Completed tasks documented
- [ ] New features added
- [ ] Project structure up to date
- [ ] Still concise and scannable

---

## Notes

- Don't just append - rewrite to keep concise
- If PRD is getting stale, ask user about bulk updates
- Compare with git history to see what actually changed
- Archive old versions if needed (user decision)
