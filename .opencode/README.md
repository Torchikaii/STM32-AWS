# Context Engineering

Boilerplate for context-driven development using opencode.
Copy `.opencode/` folder to any project (greenfield or
brownfield) to and follow steps below.

---

### Workflow

Each `SESSION` in diagram below means opening new opencode
session. This yields better LLM context utilisation.   

`/<command name>` (e.g. `/create-prd` ) below tells which command
you should run in which session. Commands are stored inside 
`/commands` folder (see [project structure](#Structure) and
[command](#Commands) section below).

```
SESSION 1: Initial Planning
├── 1. Briefly describe project idea to AI agent (or tell it to 
│   │  analyze brownfield)
│   └── Tell AI agent to ask clarifying questions
├── 2. /create-prd → creates .opencode/PRD.md
└── 3. /create-rules → creates .opencode/AGENTS.md

SESSION 2: Feature Planning
├── 1. /prime → loads PRD + AGENTS.md + current.md context
├── 2. /plan-feature → creates .opencode/plans/phase-1-plan.md
└── (optional: iterate within session)

SESSION 3: Execution
├── 1. /prime → loads context + current state
├── 2. /execute phase-1-plan.md (phase-1-pland.md is $ARGUMENT)
│   └── AI validates as it goes (tests, checks)
└── 3. AI reports completion in chat
    └── Human reviews → marks ✅ in .opencode/progress/current.md

REPEAT SESSION 2 for each phase planning (create phase-n-plan.md)
REPEAT SESSION 3 for each phase execution (execute
phase-1-plan.md).

PERIODIC:
├── /document-project → this will update project's docs (READMEs)
├── /rewrite-prd → rewrites PRD.md based on current.md
└── update current.md manually (no LLM intervention)
```

---

### Commands

| Command | Description |
|---------|-------------|
| `/create-prd` | Generate PRD.md from conversation |
| `/create-rules` | Generate AGENTS.md from template + PRD |
| `/prime` | Load project context in new session |
| `/plan-feature` | Create phase-X-plan.md in plans/ |
| `/execute <plan>` | Execute plan with validation |
| `/document-project` | Create folder documentation |
| `/rewrite-prd` | Rewrite PRD based on current.md |

---

### Structure

```
.opencode/
├── AGENTS-template.md      # Template for AI agent rules
├── PRD.md                  # Product Requirements Document
├── AGENTS.md               # Generated agent rules
├── commands/
│   ├── create-prd.md
│   ├── create-rules.md
│   ├── prime.md
│   ├── plan-feature.md
│   ├── execute.md
│   ├── document-project.md
│   └── rewrite-prd.md
├── progress/
│   └── current.md          # Human marks ✅ completed tasks
└── plans/
    └── phase-X-plan.md      # Implementation plans
```

---

### Key Concepts

- **PRD.md** - Brief product overview, updated periodically with `/rewrite-prd`
- **AGENTS.md** - Coding rules for AI agents, generated from template
- **progress/current.md** - Human-only marks ✅ completed tasks
- **phase-X-plan.md** - Detailed implementation plans
- **Folder docs** - `<foldername>.README.md` in relevant subfolders
