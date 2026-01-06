---
name: skill-builder
description: Automatically create new Claude Code skills following the established showcase pattern with proper structure, progressive disclosure, and 500-line rule compliance. Use when creating new skills, reorganizing existing skills to match showcase quality, building comprehensive domain skills, or ensuring proper structure and auto-activation configuration.
---

# Skill Builder

## Purpose

Comprehensive guide for creating new Claude Code skills following the established showcase pattern with proper structure, progressive disclosure, and 500-line rule compliance.

## When to Use This Skill

Automatically activates when:
- Creating a new skill from scratch
- Reorganizing an existing skill to match showcase quality
- Building a comprehensive skill for a specific domain
- Ensuring proper structure and auto-activation configuration
- Working with skill-rules.json
- Setting up skill triggers and activation

## Systematic Approach

### Step 1: Gather Requirements

Ask the user:

1. **What is this skill about?** (domain/topic)
2. **When should it activate?** (keywords, scenarios)
3. **What content exists?** (existing docs, notes, patterns)
4. **Priority level?** (high, medium, low)
5. **Enforcement type?** (suggest or block)

### Step 2: Analyze Existing Content (If Any)

If reorganizing existing skill:
1. Read all existing files
2. Identify main topics
3. Count total lines
4. Determine what goes in SKILL.md vs resource files

### Step 3: Create Structure Following Template

Use the **skill-developer** skill as the exact template:

**Main SKILL.md (< 500 lines):**
```markdown
---
name: skill-name
description: [Detailed description with ALL trigger keywords]
---

# Skill Name

## Purpose
[What this skill helps with]

## When to Use This Skill
[Auto-activation scenarios]

---

## Quick Start / Core Principles
[Most important concepts upfront]

---

## Navigation Guide

| Need to... | Read this |
|------------|-----------|
| Topic 1 | [file1.md](file1.md) |
| Topic 2 | [file2.md](file2.md) |

---

## Quick Reference
[Copy-paste ready patterns]

---

## Resource Files

### [file1.md](file1.md)
Brief description of what's in this file

### [file2.md](file2.md)
Brief description of what's in this file

---

## Related Skills
- Other relevant skills

---

**Skill Status**: COMPLETE
**Line Count**: < 500
**Progressive Disclosure**: N resource files
```

**Resource Files (topic-focused):**
- One file per major topic
- Table of contents if > 100 lines
- Self-contained but can reference others
- Examples and code snippets

### Step 4: Create skill-rules.json Entry

```json
{
  "skill-name": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "high",
    "description": "Brief description",
    "promptTriggers": {
      "keywords": [
        "keyword1",
        "keyword2",
        "related-term"
      ],
      "intentPatterns": [
        "(create|build|make).*?topic",
        "how.*?topic",
        "topic.*?(pattern|best practice)"
      ]
    },
    "fileTriggers": {
      "pathPatterns": [
        "**/*relevant*.ts",
        "src/topic/**/*"
      ],
      "contentPatterns": [
        "import.*specific-library",
        "specificPattern"
      ]
    }
  }
}
```

### Step 5: Organize Content by Topic

**Topic Selection Criteria:**
- Group related concepts
- Keep each file focused on ONE area
- Break down large topics into subtopics
- Create clear navigation

**Common Resource File Topics:**
1. Core concepts / Architecture
2. Quick start / Getting started
3. Common patterns / Examples
4. Advanced usage
5. Troubleshooting
6. API reference / Syntax
7. Best practices
8. Anti-patterns / What not to do

### Step 6: Ensure Quality Standards

**Check:**
- [ ] SKILL.md < 500 lines
- [ ] YAML frontmatter with name + description
- [ ] Description includes ALL trigger keywords
- [ ] Navigation guide present
- [ ] Quick reference section
- [ ] Resource files properly linked
- [ ] Table of contents in files > 100 lines
- [ ] skill-rules.json entry created
- [ ] Keywords cover all activation scenarios
- [ ] Intent patterns capture user questions

### Step 7: Add to skill-rules.json

1. Read existing skill-rules.json
2. Add new entry in alphabetical order
3. Validate JSON syntax
4. Test activation with sample prompts

### Step 8: Test Activation

Create test prompts:
```bash
echo '{"prompt": "test prompt with keywords", "cwd": ".", "session_id": "test"}' | \
  ~/.claude/hooks/skill-activation-prompt.sh
```

Verify the skill activates correctly.

### Step 9: Document the Skill

Create a summary showing:
- What the skill covers
- When it activates
- How to use it
- Links to key resource files

## Output Format

Return to user:

```
Skill Created: [skill-name]

Structure:
~/.claude/skills/[skill-name]/
├── SKILL.md (XXX lines)
├── topic1.md
├── topic2.md
└── topic3.md

Auto-Activation:
Keywords: [list]
Intent: [list]
Files: [patterns]

Added to skill-rules.json

Test Results:
[Show test activation output]

Next Steps:
1. Test in real usage
2. Refine triggers based on false positives/negatives
3. Add more examples as patterns emerge
```

## Resource Files

See [EXAMPLES.md](EXAMPLES.md) for complete skill creation examples including reorganizing xano-sdk-builder and creating xano-api-development from scratch.

## Quick Reference

**Tools Available:**
- Read - Read existing files
- Write - Create new files
- Edit - Modify existing files
- Bash - Test activation, validate JSON
- Skill tool - Reference skill-developer for structure

**Success Criteria:**
- Follows showcase pattern exactly
- SKILL.md < 500 lines
- Progressive disclosure with resource files
- Clear navigation guide
- Auto-activation configured and tested
- Quality matches backend-dev-guidelines or frontend-dev-guidelines

**Anti-Patterns to Avoid:**
- Main file > 500 lines
- All content in one file
- Missing navigation guide
- Generic trigger keywords
- No skill-rules.json entry
- Not testing activation
- Inconsistent structure with showcase

---

**Skill Status**: COMPLETE
**Template**: skill-developer skill
**Quality Standard**: Showcase level
