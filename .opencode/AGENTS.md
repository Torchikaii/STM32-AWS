# AI Agent Rules - STM32-AWS

## Project Overview

- **Project name:** STM32-AWS
- **Core purpose:** IoT framework for connecting STM32 microcontrollers to AWS cloud services with integrated latency benchmarking
- **Target users:** Embedded developers (primary), DevOps engineers

---

## Core Principles

1. **Ask questions instead of assuming** - When unclear about requirements, ask the user before implementing
2. **Verify before acting** - Read existing code before making changes, understand the codebase first
3. **Keep it simple** - Prefer simple solutions over complex ones unless complexity is justified
4. **Document decisions** - Explain why you made certain choices
5. **Test thoroughly** - Verify your changes work and don't break existing functionality
6. **Environment parity** - Changes must work in both local Docker and CI/CD environments
7. **MCU agnosticism** - Avoid hardcoding MCU-specific logic where possible

---

## Coding Style

- **Languages:** C (embedded), Python (scripts/TUI), HCL (Terraform), Bash (CI/CD)
- **Build System:** Makefile (ARM GCC)
- **Formatting:** Follow existing code patterns in the project
- **Naming conventions:** snake_case for C variables/functions, SCREAMING_SNAKE_CASE for constants
- **Code organization:** 
  - Framework source in `src/`
  - Scripts in `scripts/`
  - Infrastructure as code in `infrastructure/`

### Key Patterns

- **Embedded:** Use STM32CubeMX-generated code as base, add framework code separately
- **CI/CD:** Use xvfb for headless STM32CubeMX, expect/xdotool for license automation
- **Terraform:** Modular structure with reusable components

---

## Testing Strategy

- **Test framework:** Custom scripts + manual testing
- **Test location:** `tests/` for unit/integration, hardware testing for HIL
- **Types of tests:**
  - Unit tests for C modules (MQTT, ethernet, latency)
  - Integration tests for AWS services
  - Hardware-in-the-loop tests for actual STM32 devices
  - CI/CD validation for all supported MCU families

---

## Questions Policy

**Always ask when:**
- Requirements are unclear or ambiguous
- Edge cases aren't specified
- You're about to make assumptions about business logic
- Security or performance implications are unclear
- The existing code contradicts the requirements
- You need clarification on MCU family support

**Don't assume when:**
- User intent is unclear
- Technology choices aren't documented
- Error handling isn't specified
- The license automation approach isn't working

---

## Project Structure

```
STM32-AWS/
├── .github/workflows/           # CI/CD pipelines
├── infrastructure/              # Terraform IaC
├── src/                        # Framework source (C)
├── scripts/                    # Utility scripts
│   └── project-generator/      # TUI for new projects
├── docker/                     # Docker configs
└── docs/                       # Documentation
```

---

## Important Files

- **PRD:** `.opencode/PRD.md` - Product requirements and scope
- **Problems:** `.opencode/problems.md` - Known issues and challenges
- **CI/CD:** `.github/workflows/stm32_generate_code.yml` - Main build pipeline
- **Docker:** `Dockerfile` - Container for STM32CubeMX
- **Scripts:** `setup-repo.sh`, `generate_script.sh`, `run-cubemx.sh`, `compile-flash.sh`
- **Docs:** `docs/getting-started.md`, `docs/network-connection.md`

---

## Communication Guidelines

- Speak as little as you can, preserve token usage, unless told otherwise or you want to ask a question.
- Prefer saying too little then too much.
- When AI agent is asked to execute a task it should never print summary or something but "Done" or "Completed". 1 Word, no speeches, no poems.
- When asked a simple question AI agent has to always say "yes" or "no". 1 word answer.

```
Example:
q: Can you clone a public git repository without github token ?
a: yes
```

- When it's hard to answer "yes" or "no" to the question (or the question is incorrect). You can give one (in some cases two) sentence answer.

```
Example:
q: How do you install numpy via apt ?
a: Numpy is not a linux package, it's a python package and can be installed via pip.
```
- If a user doesn't understand what are you saying and asking you why certain things work in certain ways or ask you to explain then you can go on with normal explanation, instead of one or two sentences.

```
Example
q1: Is sky on earth green ?
a1: no
q2: why not ?
a2: Because <go on with explanation, about dispersion and other optics related stuff, light travelling, bending, absorbtion, etc>
```

---

## Common Pitfalls to Avoid

1. Don't skip reading existing code before making changes
2. Don't implement features without understanding the architecture
3. Don't assume "it should work" - verify explicitly
4. Don't leave broken code - either fix it or document the issue
5. Don't rush - take time to understand the problem first
6. Don't hardcode MCU-specific values when abstraction is possible
7. Don't forget that local and CI environments must behave identically

---

## Success Criteria

- Code follows existing patterns in the codebase
- Tests pass and coverage meets expectations
- No security vulnerabilities introduced
- Documentation updated if needed
- Changes validated before marking complete
- Local and CI/CD builds produce identical results
