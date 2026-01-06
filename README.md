# AgentDashboards Plugins

Official Claude Code plugin marketplace for AgentDashboards development.

## Installation

Add this marketplace to Claude Code:

```bash
/plugin marketplace add roboulos/agentdashboards-plugins
```

Then install plugins:

```bash
# Essential - Complete Xano development toolkit
/plugin install xano-sdk-builder@agentdashboards-tools

# Frontend React/TypeScript patterns
/plugin install frontend-dev-guidelines@agentdashboards-tools

# Browser testing with Playwright
/plugin install playwright-testing@agentdashboards-tools

# Pre-configured MCP servers (Playwright + Xano)
/plugin install recommended-mcp-servers@agentdashboards-tools

# Auto TypeScript build checking (RECOMMENDED)
/plugin install typescript-build-checker@agentdashboards-tools

# Smart skill suggestions
/plugin install skill-activation-hook@agentdashboards-tools

# Autonomous Xano builder agent
/plugin install xano-builder-agent@agentdashboards-tools

# Skill creation tools (makes marketplace self-expanding!)
/plugin install skill-builder@agentdashboards-tools
/plugin install skill-developer@agentdashboards-tools
```

## Available Plugins

### Core Development

| Plugin | Type | Description |
|--------|------|-------------|
| **xano-sdk-builder** | Skill | Complete Xano toolkit: XanoScript SDK, curl testing, batch migrations. BUILD→TEST→UPDATE→REPEAT for 95%+ success. |
| **frontend-dev-guidelines** | Skill | React/TypeScript best practices, ShadCN UI, TanStack Router, Suspense patterns |

### Testing

| Plugin | Type | Description |
|--------|------|-------------|
| **playwright-testing** | Skill | Browser automation and E2E testing with Playwright MCP |

### MCP Servers

| Plugin | Type | Description |
|--------|------|-------------|
| **recommended-mcp-servers** | MCP | Pre-configured: Playwright for browser testing, Xano for backend ops |

### Hooks (Automation)

| Plugin | Type | Description |
|--------|------|-------------|
| **typescript-build-checker** | Hook | Auto-runs `tsc --noEmit` after edits, catches TypeScript errors early |
| **skill-activation-hook** | Hook | Smart skill suggestions based on prompt keywords |

### Agents

| Plugin | Type | Description |
|--------|------|-------------|
| **xano-builder-agent** | Agent | Autonomous Xano backend developer |

### Skill Creation (Self-Expanding!)

| Plugin | Type | Description |
|--------|------|-------------|
| **skill-builder** | Skill | Create new skills following showcase pattern, 500-line rule, progressive disclosure |
| **skill-developer** | Skill | Technical reference: trigger types, hooks, skill-rules.json, troubleshooting |

## How the Hooks Work

### typescript-build-checker

1. **PostToolUse**: Tracks every file you edit (Edit, MultiEdit, Write)
2. **Stop**: When Claude finishes responding, runs `tsc --noEmit` on affected repos
3. **Feedback**: Shows TypeScript errors with file:line references

```
## TypeScript Build Errors Detected

Found 3 TypeScript error(s):
- app: 3 errors

Error details:
  app/components/Dashboard.tsx:42:5 - error TS2322: Type 'string' is not assignable to type 'number'.
```

### skill-activation-hook

1. **UserPromptSubmit**: Scans your prompt for keywords
2. **Suggestions**: Recommends relevant skills before Claude responds

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 SKILL ACTIVATION CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 RECOMMENDED SKILLS:
  → xano-sdk-builder (CRITICAL)

ACTION: Use Skill tool BEFORE responding
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Tech Stack

These plugins are designed for the AgentDashboards stack:

- **Frontend:** Next.js, React, TypeScript, Tailwind CSS, ShadCN UI
- **Backend:** Xano (XanoScript)
- **Data Fetching:** SWR hooks
- **Testing:** Playwright, curl

## What's Included

| Plugin | Files | Content |
|--------|-------|---------|
| xano-sdk-builder | 25+ | XanoScript methods, filters, operators, curl patterns, batch migrations, skill-rules.json |
| frontend-dev-guidelines | 10 | Component patterns, data fetching, styling, routing |
| playwright-testing | 4 | Browser automation, debugging, test strategies |
| recommended-mcp-servers | 1 | Playwright + Xano MCP configs |
| typescript-build-checker | 2 | PostToolUse + Stop hooks for TSC validation |
| skill-activation-hook | 1 | UserPromptSubmit hook for skill suggestions |
| xano-builder-agent | 1 | Autonomous backend builder |
| skill-builder | 2 | Skill creation guide + examples |
| skill-developer | 7 | Complete skill system reference (SKILL.md + 6 resource files) |

## License

MIT
