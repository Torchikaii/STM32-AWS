# Create Rules: Generate AGENTS.md

## Purpose

Generate `AGENTS.md` - a comprehensive rules document for AI coding agents working on this project. Combines the template from `AGENTS-template.md` with project-specific context from `PRD.md`.

---

## Output

Write to: `.opencode/AGENTS.md`

---

## Instructions

### Step 1: Read the Template

Read `.opencode/AGENTS-template.md` to understand the base structure of `.opencode/AGENTS.md` file youre creating

### Step 2: Read PRD Context

Read `.opencode/PRD.md` (or the path specified) to extract:
- Project name and core purpose
- Target users and their needs
- Technology stack (from Technology Stack section)
- Architecture patterns (from Architecture & Design)
- Key requirements and success criteria
- Any specific coding standards mentioned

### Step 3: Merge and Customize

Fill in the placeholders in the template:

1. **Project Overview** - Extract from Executive Summary in PRD
2. **Coding Style** - Use technology stack from PRD, infer from existing code
3. **Testing Strategy** - Reference any testing requirements in PRD
4. **Project Structure** - Use actual directory structure if project exists, or proposed structure from PRD
5. **Important Files** - Add PRD.md path, any other key documents

### Step 4: Add Project-Specific Rules

Based on the PRD, add custom rules for:
- Specific frameworks or libraries being used
- Any security requirements
- Deployment or infrastructure constraints
- Integration patterns

### Step 5: Write AGENTS.md

Write the completed file to `.opencode/AGENTS.md`.

---

## Quality Checklist

- [ ] All template placeholders filled in
- [ ] Technology stack accurately reflected
- [ ] Project structure matches actual or proposed structure
- [ ] Questions Policy clearly states when to ask vs assume
- [ ] Success criteria aligned with PRD metrics

---

## Notes

- If PRD.md doesn't exist yet, ask the user to run `/create-prd` first
- Keep the "Questions Policy" section prominent - it's critical
- Adapt the template to the project's specific needs
- Don't just copy - customize based on project context
