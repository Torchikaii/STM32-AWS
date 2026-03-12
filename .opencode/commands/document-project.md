# Document Project: Generate Folder Documentation

## Purpose

Document the project structure by creating `README.md` files
with folder path comments in relevant subfolders. Run this
command after `/prime` to document an existing project.

---

## Output

Creates `README.md` files with `<!-- folder: path -->` comments
inside folders and subfolders based on the sweet spot rules
below.

---

## README Naming

**All folders use standard `README.md`** with a folder path
comment at the top.

| Folder Level | Filename | Comment |
|--------------|----------|---------|
| Root | `README.md` | `<!-- folder: ./ -->` |
| Subfolder | `README.md` | `<!-- folder: root/sub-folder/ -->` |
| Sub-subfolder | `README.md` | `<!-- folder: root/sub-folder/sub-sub-folder/ -->` |


---

## Sweet Spot Rules

Decide whether a folder needs documentation or not:

| Folder Type | Decision | Depth | Reasoning |
|-------------|----------|-------|-----------|
| **Root** | ALWAYS | Brief | Project overview |
| **Subfolder with diverse children** (e.g., `/flask` has `/backend` + `/frontend`) | YES | Brief | Mention children have own docs |
| **Subfolder with single purpose** (e.g., `/terraform` - one function) | YES | In-depth | Full documentation |
| **Sub-subfolder** (independently complex/diverse) | YES | In-depth | Same as subfolder |
| **Sub-subfolder** (simple, few files) | NO | - | Reference in parent instead |
| **Small/simple folders** (few files, single purpose) | NO | - | Reference in parent README |

### Decision Flow

```
Is this the root folder?
  YES → Create README.md (brief, <!-- folder: ./ -->)

  NO → Is this folder diverse (contains multiple subfolders with DIFFERENT purposes)?
    YES → Create README.md (brief, mention children have own docs, <!-- folder: flask/ -->)

    NO → Does this folder serve a single, specific purpose?
      YES → Create README.md (in-depth, <!-- folder: src/components/ -->)
      NO → Skip (reference in parent's README)
```

### Example for decision flow

```
flask/                  # Diverse children → brief README
├── backend/            # Independent function → in-depth README
└── frontend/           # Independent function → in-depth README

terraform/              # Single purpose → in-depth README
├── main.tf
└── variables.tf
```

---

## Detect Changes

Every time this command runs, you MUST:

1. **Grep full file structure** - Get complete directory listing
2. Detect any file/folder changes since last documentation
3. **If changes found** → Update/create READMEs accordingly
4. **Check existing READMEs** - If they don't exist or don't
follow conventions or are out of date → create/update them

---

## Content Guidelines

### Root README

Typical structure (in order):
1. Project name (+ optional image)
2. Brief description
3. How to use / How to run (stable + dev if available)
4. How to dev (build from source, contribute)
5. Tree-like **BRIEF** file/folder structure
6. Optional: github stats, etc


### Subfolder with Diverse Children

- Brief description
- Mention children have their own README files

### Subfolder without Diverse Children / Independent Sub-subfolder

- Brief description of what this folder is
- Structure (tree + file labels). If contains redundand
files (e.g. /languages folder has so many html templates with
shared structure, only list a few of them and add "..." at the
end, no need to list 100 common files).
- Purpose/Usage section. Go in depth here, but be concise and
clear. Provide examples from that folder's filesystem with their
working principles explanation

---

## Folder-Specific Requirements

Some folders may need specialized docs beyond the standard structure. Use sober brain to decide what is right in which situation:

- `database/` may need schema, migrations info
- `scripts/` may need what each script does
- Any folder with specific domain knowledge should document it

Document what's relevant to understanding that particular folder.

---

## Instructions

### Step 1: Detect Changes

1. Run git commands to see what changed
2. Get full file structure: `find . -type f -o -type d | head -100` (adjust as needed)
3. Check which folders are new/modified
4. Identify existing READMEs and check if they follow conventions

### Step 2: Explore Project Structure

If no git repo or first run, understand:
- All directories and their purposes
- File types and organization
- Configuration vs source vs tests

### Step 3: Map the Tree

Create a mental map:
- Root folders and their purposes
- Which folders are diverse (contain multiple concerns)
- Which folders are simple/leaves
- Which subfolders have children with independent functions

### Step 4: Apply Sweet Spot Rules

For each folder, decide:
1. Does this folder need documentation?
2. How detailed should it be?

### Step 5: Write Each README

**Naming:** All folders use `README.md` with folder path comment.

**Root README:**
```
<!--folder: ./ -->
steps 1 to 6 above
```
**Subfolder with Diverse Children (Brief):**
```
<!-- folder: flask/ -->
# Flask

Brief description of what this folder contains.

Contains backend/ and frontend/ - each has its own documentation.
```

**Subfolder without Diverse Children / Independent Sub-subfolder (Strict):**
```
<!-- folder: src/components/ -->
# Components

Brief description of what this folder is.

## Structure

```
src/components/
├── Button.js
└── Input.js
```

## Purpose/Usage

What this folder contains and how other parts use it.
```

### Step 6: Validate

- No redundant information across READMEs
- Each README has a clear purpose
- Tree structures are accurate
- No fluff sentences
- Naming follows convention (all = README.md with folder path comment)
- All changes detected and documented

---

## Quality Checklist

- [ ] Root folder always documented as README.md with folder comment
- [ ] All README files have `<!-- folder: path -->` comment in their first line
- [ ] Diverse subfolders (with multiple independent children) have brief docs
- [ ] Single-purpose subfolders have in-depth docs
- [ ] Simple folders skipped (referenced in parent instead)
- [ ] No sentences like "This folder contains important files"
- [ ] Tree structures are accurate and concise
- [ ] Each README answers: "What is this folder for?"
- [ ] No duplicate information across READMEs
- [ ] git diff run and changes documented
- [ ] Existing READMEs checked for folder path comments

---

## Notes

- Be selective - better fewer quality docs than many half-hearted ones
- If unsure whether a folder needs docs, lean towards skipping
- A folder with 2-3 simple files doesn't need its own README

