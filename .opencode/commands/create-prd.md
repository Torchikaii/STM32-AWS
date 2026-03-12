# Create PRD: Generate Product Requirements Document

## Purpose

Generate a comprehensive Product Requirements Document (PRD) from the current conversation context.

---

## Output

Write to: `$ARGUMENTS` (default: `.opencode/PRD.md`)

---

## PRD Template

### 1. Executive Summary
- 2-3 paragraph product overview
- Core value proposition
- MVP goal statement

### 2. Mission & Principles
- Product mission statement
- 3-5 core principles guiding development

### 3. Target Users
- Primary user personas
- Technical comfort level
- What problem/problems does this project solve

### 4. Scope

**In Scope (MVP)** — ✅ checkboxes
- Core functionality
- Technical requirements
- Integration needs
- Deployment requirements

**Out of Scope** — ❌ checkboxes
- Features deferred to future phases

### 5. User Stories
- 5-8 stories in format: "As a [user], I want [action], so that [benefit]"
- Include concrete examples
- Add technical user stories where relevant

### 6. Architecture & Design
- High-level system architecture
- Directory structure (if applicable)
- Key design patterns and principles

### 7. Technology Stack
- Backend/Frontend with versions
- Dependencies (required + optional)
- Third-party integrations

### 8. Security & Configuration
- Authentication/authorization approach
- Configuration management
- Security scope

### 9. API Specification (if applicable)
- Endpoint definitions
- Request/response formats
- Example payloads

### 10. Success Criteria
- Measurable MVP success metrics
- Functional acceptance criteria (✅ checkboxes)
- Quality indicators

### 11. Implementation Phases
- 3-4 phases with:
  - Phase goal
  - Deliverables (✅ checkboxes)
  - Validation criteria
  - Realistic timeline

### 12. Risks & Mitigations
- 3-5 key risks
- Specific mitigation strategies for each

### 13. Future Considerations
- Post-MVP enhancements
- Integration opportunities

---

## Instructions

### Step 1: Extract Requirements
- Review conversation history
- Identify explicit requirements and implicit needs
- Note technical constraints and preferences

### Step 2: Synthesize
- Organize into appropriate sections
- Fill reasonable assumptions where details are missing
- Ensure technical feasibility

### Step 3: Write
- Use clear, professional language
- Use markdown: headings, lists, code blocks, ✅/❌ checkboxes
- Keep sections scannable but comprehensive

### Step 4: Quality Check
- ✅ All required sections present
- ✅ User stories have clear benefits
- ✅ MVP scope is realistic
- ✅ Technology choices justified
- ✅ Success criteria measurable

---

## Style Guidelines

- **Tone:** Professional, clear, action-oriented
- **Format:** Markdown with headings, tables, code blocks
- **Checkboxes:** ✅ for in-scope, ❌ for out-of-scope
- **Specificity:** Concrete examples over abstract descriptions

---

## Notes

- Ask clarifying questions if critical information is missing
- Adapt section depth to available details
- Emphasize architecture for technical products, user stories for consumer products
