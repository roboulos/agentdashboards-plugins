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

# Autonomous Xano builder agent
/plugin install xano-builder-agent@agentdashboards-tools
```

## Available Plugins

### Core Development

| Plugin | Description |
|--------|-------------|
| **xano-sdk-builder** | Complete Xano toolkit: XanoScript SDK, curl testing, batch migrations, MCP workflow. BUILD→TEST→UPDATE→REPEAT for 95%+ success. |
| **frontend-dev-guidelines** | React/TypeScript best practices, ShadCN UI, TanStack Router, Suspense patterns |

### Testing

| Plugin | Description |
|--------|-------------|
| **playwright-testing** | Browser automation and E2E testing with Playwright MCP |

### MCP Servers

| Plugin | Description |
|--------|-------------|
| **recommended-mcp-servers** | Pre-configured MCP servers: Playwright for browser testing, Xano for backend ops |

### Agents

| Plugin | Description |
|--------|-------------|
| **xano-builder-agent** | Autonomous Xano backend developer agent |

## Tech Stack

These plugins are designed for the AgentDashboards stack:

- **Frontend:** Next.js, React, TypeScript, Tailwind CSS, ShadCN UI
- **Backend:** Xano (XanoScript)
- **Data Fetching:** SWR hooks
- **Testing:** Playwright, curl

## What's Included

| Plugin | Files | Content |
|--------|-------|---------|
| xano-sdk-builder | 25+ | XanoScript methods, filters, operators, curl patterns, batch migrations |
| frontend-dev-guidelines | 10 | Component patterns, data fetching, styling, routing |
| playwright-testing | 4 | Browser automation, debugging, test strategies |
| recommended-mcp-servers | 1 | Playwright + Xano MCP configs |
| xano-builder-agent | 1 | Autonomous backend builder |

## License

MIT
