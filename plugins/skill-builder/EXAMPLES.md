# Skill Builder Examples

Complete examples for creating and reorganizing Claude Code skills.

## Table of Contents

- [Example 1: Reorganizing xano-sdk-builder](#example-1-reorganizing-xano-sdk-builder)
- [Example 2: Creating xano-api-development](#example-2-creating-xano-api-development)

## Example 1: Reorganizing xano-sdk-builder

### Scenario
User asks to reorganize the xano-sdk-builder skill to follow the showcase pattern.

### Analysis Phase

**Current content:**
- SKILL.md: 378 lines (good!)
- WORKFLOW.md - Iterative development process
- SYNTAX.md - Complete SDK reference
- WHAT_BREAKS.md - Limitations & workarounds
- (Additional resource files exist)

### Proposed Structure

```
SKILL.md (< 500 lines)
├── Core philosophy
├── Quick start checklist
├── Critical gotchas (top 5)
├── Navigation guide
└── Quick reference

Resource files:
├── WORKFLOW.md - Iterative development process
├── SYNTAX.md - Complete SDK reference
├── WHAT_BREAKS.md - Limitations & workarounds
├── EXAMPLES.md - Production patterns
├── ERROR_RESPONSES.md - Common errors & fixes
└── QUICK_REFERENCE.md - Cheat sheet
```

### Verification

1. **500-line rule:** Main file already compliant
2. **skill-rules.json:** Already added
3. **Test activation:** Already tested

### Result

No changes needed - skill already follows showcase pattern perfectly!

## Example 2: Creating xano-api-development

### Scenario
User wants to create a new skill for Xano architecture and best practices.

### Step 1: Gather Requirements

**Topic:** Xano architecture & best practices
**Keywords:** xano architecture, xano best practices, organize workspace, endpoint vs function, xano design
**Priority:** high
**Enforcement:** suggest

### Step 2: Create Structure

```
SKILL.md
├── Purpose: High-level Xano patterns
├── When to use vs xano-sdk-builder
├── Navigation guide
└── Quick patterns

Resource files:
├── ARCHITECTURE.md - Workspace organization
├── ENDPOINTS_VS_FUNCTIONS.md - When to use each
├── BACKGROUND_TASKS.md - Async patterns
├── EXTERNAL_APIS.md - Integration patterns
├── DATABASE_DESIGN.md - Schema design
├── AUTH_PATTERNS.md - Authentication
└── TESTING.md - Testing strategies
```

### Step 3: Main SKILL.md

```markdown
---
name: xano-api-development
description: Xano API architecture and best practices for high-level design decisions. Use when organizing Xano workspaces, deciding between endpoints vs functions, designing background tasks, planning external API integrations, structuring databases, or implementing auth patterns. Covers workspace organization, architectural patterns, when to use each Xano feature, database design principles, and authentication strategies. Keywords: Xano architecture, Xano best practices, organize Xano, workspace organization, endpoint vs function, Xano design, database design, auth patterns, background tasks, API planning, Xano structure.
---

# Xano API Development

## Purpose

High-level architectural guidance for building robust Xano backends. Focuses on design decisions, workspace organization, and when to use each Xano feature.

## When to Use This Skill

Use when:
- Organizing Xano workspaces
- Deciding between endpoints vs functions
- Designing background tasks
- Planning external API integrations
- Structuring databases
- Implementing authentication patterns

**NOT for:** SDK-level code generation (use xano-sdk-builder for that)

## Quick Patterns

### Endpoint vs Function Decision Tree

Need to...
├─ Expose to external clients? → Endpoint
├─ Share logic between endpoints? → Function
├─ Run on schedule? → Background Task
└─ React to database changes? → Trigger

### Workspace Organization

**Best Practice:**
- Development → Staging → Production (separate instances)
- Branch-based development within each instance
- Environment-specific variables in .env

## Navigation Guide

| Need to... | Read this |
|------------|-----------|
| Organize workspace structure | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Choose endpoint vs function | [ENDPOINTS_VS_FUNCTIONS.md](ENDPOINTS_VS_FUNCTIONS.md) |
| Design async workflows | [BACKGROUND_TASKS.md](BACKGROUND_TASKS.md) |
| Integrate 3rd party APIs | [EXTERNAL_APIS.md](EXTERNAL_APIS.md) |
| Design database schema | [DATABASE_DESIGN.md](DATABASE_DESIGN.md) |
| Implement authentication | [AUTH_PATTERNS.md](AUTH_PATTERNS.md) |
| Set up testing | [TESTING.md](TESTING.md) |

## Quick Reference

**Common Patterns:**
- Input validation: Use functions for reusable validation logic
- Error handling: Centralize in shared functions
- Rate limiting: Implement at endpoint level
- Caching: Use background tasks to refresh
- Webhooks: Endpoints with signature verification

## Resource Files

### [ARCHITECTURE.md](ARCHITECTURE.md)
Workspace organization, instance management, branch strategy, environment variables

### [ENDPOINTS_VS_FUNCTIONS.md](ENDPOINTS_VS_FUNCTIONS.md)
Decision criteria, use cases, performance considerations, security implications

### [BACKGROUND_TASKS.md](BACKGROUND_TASKS.md)
Scheduled tasks, async processing, queue management, error recovery

### [EXTERNAL_APIS.md](EXTERNAL_APIS.md)
API integration patterns, authentication, rate limiting, webhook handling

### [DATABASE_DESIGN.md](DATABASE_DESIGN.md)
Schema design, relationships, indexes, migrations, data modeling

### [AUTH_PATTERNS.md](AUTH_PATTERNS.md)
JWT, OAuth, API keys, role-based access, session management

### [TESTING.md](TESTING.md)
Testing strategies, test data, API testing, integration testing

## Related Skills

- **xano-sdk-builder** - For SDK-level code generation
- **backend-dev-guidelines** - General backend patterns

---

**Skill Status**: COMPLETE
**Line Count**: < 500
**Progressive Disclosure**: 7 resource files
```

### Step 4: skill-rules.json Entry

```json
{
  "xano-api-development": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "high",
    "description": "Xano API architecture and best practices",
    "promptTriggers": {
      "keywords": [
        "xano architecture",
        "xano best practices",
        "organize xano",
        "xano workspace",
        "endpoint vs function",
        "xano design",
        "database design",
        "auth patterns",
        "background tasks",
        "api planning",
        "xano structure"
      ],
      "intentPatterns": [
        "how.*?(organize|structure).*?xano",
        "(when|should).*?(endpoint|function)",
        "xano.*?(best practice|pattern|architecture)",
        "design.*?xano.*?(database|api|backend)",
        "(plan|planning).*?xano"
      ]
    },
    "fileTriggers": {
      "pathPatterns": [],
      "contentPatterns": []
    }
  }
}
```

### Step 5: Create Resource Files

Each resource file would be created following the same pattern:
- Clear topic focus
- Table of contents if > 100 lines
- Code examples
- Best practices
- Anti-patterns

### Step 6: Test Activation

```bash
echo '{"prompt": "How should I organize my Xano workspace?", "cwd": ".", "session_id": "test"}' | \
  ~/.claude/hooks/skill-activation-prompt.sh
```

Expected output: Skill activates

### Final Output

```
Skill Created: xano-api-development

Structure:
~/.claude/skills/xano-api-development/
├── SKILL.md (215 lines)
├── ARCHITECTURE.md (180 lines)
├── ENDPOINTS_VS_FUNCTIONS.md (145 lines)
├── BACKGROUND_TASKS.md (160 lines)
├── EXTERNAL_APIS.md (170 lines)
├── DATABASE_DESIGN.md (195 lines)
├── AUTH_PATTERNS.md (155 lines)
└── TESTING.md (140 lines)

Auto-Activation:
Keywords: xano architecture, xano best practices, organize xano, workspace organization, endpoint vs function, xano design, database design, auth patterns, background tasks, API planning, xano structure
Intent: how to organize/structure xano, when/should use endpoint/function, xano best practices/patterns/architecture
Files: None (prompt-based activation only)

Added to skill-rules.json

Test Results:
- Activates on "How should I organize my Xano workspace?"
- Activates on "Should I use an endpoint or function?"
- Activates on "Xano best practices for background tasks"

Next Steps:
1. Test in real usage
2. Refine triggers based on false positives/negatives
3. Add more examples as patterns emerge
```

## Key Takeaways

### Structure Pattern
- Main SKILL.md < 500 lines (navigation + quick reference)
- One resource file per major topic
- Table of contents for files > 100 lines
- Clear relationships between skills

### Activation Pattern
- Keywords in description (max 1024 chars)
- Intent patterns for implicit questions
- File triggers only when technology-specific
- Test with real user prompts

### Content Organization
- Essential info in SKILL.md
- Details in resource files
- Examples throughout
- Quick reference always accessible

### Quality Metrics
- Line count compliance
- Progressive disclosure
- Clear navigation
- Auto-activation working
- Showcase-level quality
