# AgentDashboards Plugins

Official Claude Code plugin marketplace for AgentDashboards development.

## Installation

Add this marketplace to Claude Code:

```bash
/plugin marketplace add sboulos/agentdashboards-plugins
```

Then install plugins:

```bash
/plugin install xano-sdk-builder@agentdashboards-tools
/plugin install frontend-dev-guidelines@agentdashboards-tools
```

## Available Plugins

### Core Xano Development

| Plugin | Description |
|--------|-------------|
| **xano-sdk-builder** | Expert XanoScript SDK development with BUILD→TEST→UPDATE→REPEAT workflow |
| **xano-mcp-workflow** | Battle-tested patterns for the Xano MCP tool |
| **xano-api-development** | High-level Xano architecture and design decisions |

### Frontend Development

| Plugin | Description |
|--------|-------------|
| **frontend-dev-guidelines** | React/TypeScript best practices, ShadCN UI, TanStack patterns |
| **xano-nextjs-integration** | Connect Xano backend to Next.js frontend |

### Testing & Debugging

| Plugin | Description |
|--------|-------------|
| **debug-fix-verify** | Systematic 7-step debug workflow |
| **playwright-testing** | Browser automation and E2E testing |

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

## License

MIT
