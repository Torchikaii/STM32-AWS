# Prime: Load Project Context

## Purpose

Rebuild project awareness in a new OpenCode session. This command provides the AI coding agent with all necessary context to continue working on the project effectively.

---

## Instructions

### Step 1: Read Core Documents

You **MUST** read these files in order:

1. **`.opencode/PRD.md`** - Product Requirements Document

2. **`.opencode/AGENTS.md`** - AI Agent Rules (obey these)

3. **`.opencode/progress/current.md`** - Project progress
   - Current phase number
   - What has been completed (human-marked ✅)

4. **`README.md`** Files
   - `README.md` inside project root
   - `README.md` inside other folders (they likely document
     specific folders)

### Step 2: Explore Project Structure

Examine the actual project structure:
- List root directory contents
- Identify key directories (src/, lib/, tests/, etc.)
- Note any configuration files


## Notes

- This command is designed for **new sessions** - when you start working after a break or in a fresh context
- The goal is to get the AI agent "primed" with project knowledge within 30-60 seconds
- If PRD.md doesn't exist, prompt the user to create it first
- If AGENTS.md doesn't exist, prompt the user to run `/create-rules`
