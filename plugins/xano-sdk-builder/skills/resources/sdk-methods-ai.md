# SDK AI Methods

AI agent execution, MCP integration, and intelligent operations.

## Status Overview

**Working Methods:** 2 of 4 (50%)
**Coverage:** Core AI functionality verified, discovery tools not implemented

---

## ✅ Verified Working Methods

### 1. `aiAgentRun(args, allowToolExecution?, alias?)` ✅ VERIFIED 2025-01-13

**Description:** Execute an AI agent with specified arguments and optional tool execution.

**Parameters:**
- `args` (object) - Arguments to pass to the AI agent (prompt, data, etc.)
- `allowToolExecution` (boolean, optional) - Whether to allow the agent to execute tools
- `alias` (string, optional) - Variable to store the result

**Example:**
```json
{
  "operations": [
    {"method": "input", "args": ["prompt", "text"]},
    {"method": "aiAgentRun", "args": [
      {"prompt": "$input.prompt", "data": "context"},
      true,
      "result"
    ]},
    {"method": "response", "args": [{"analysis": "$result"}]}
  ]
}
```

**Generated XanoScript:**
```xanoscript
ai.agent.run {
  args = {"prompt":"$input.prompt","data":"context"}
  allow_tool_execution = true
} as result
```

**Use Cases:**
- Run AI agents for natural language processing
- Execute intelligent data analysis
- Perform automated reasoning tasks
- Allow agents to use external tools

---

### 2. `aiExternalMcpToolRun(mcpUrl, apiKey, toolName, input, alias?)` ✅ VERIFIED 2025-01-13

**Description:** Execute a tool from an external MCP (Model Context Protocol) server.

**Parameters:**
- `mcpUrl` (string) - URL of the MCP server
- `apiKey` (string) - API key for authentication
- `toolName` (string) - Name of the tool to execute
- `input` (object) - Input data for the tool
- `alias` (string, optional) - Variable to store the result

**Example:**
```json
{
  "operations": [
    {"method": "aiExternalMcpToolRun", "args": [
      "https://mcp.example.com",
      "$env.MCP_KEY",
      "web_search",
      {"query": "$input.search"},
      "search_results"
    ]},
    {"method": "response", "args": [{"results": "$search_results"}]}
  ]
}
```

**Generated XanoScript:**
```xanoscript
ai.external.mcp.tool.run {
  mcp_url = "https://mcp.example.com"
  api_key = $env.MCP_KEY
  tool_name = "web_search"
  input = {"query":"$input.search"}
} as search_results
```

**Use Cases:**
- Integrate external AI tools and services
- Execute MCP protocol tools
- Connect to third-party AI capabilities
- Extend Xano with external intelligence

---

## ❌ Not Implemented Methods

### 3. `aiExternalMcpToolList()` ❌ NOT IMPLEMENTED

**Description:** List available tools from an MCP server.

**Expected Parameters:**
- `mcpUrl` (string) - URL of the MCP server
- `apiKey` (string) - API key for authentication
- `alias` (string, optional) - Variable to store the list

**Status:** Method does not exist in SDK Builder. Returns "Method not found" error.

**Workaround:** Hardcode tool names based on external MCP server documentation.

---

### 4. `aiExternalMcpServerDetails()` ❌ NOT IMPLEMENTED

**Description:** Get details and capabilities of an MCP server.

**Expected Parameters:**
- `mcpUrl` (string) - URL of the MCP server
- `apiKey` (string) - API key for authentication
- `alias` (string, optional) - Variable to store the details

**Status:** Method does not exist in SDK Builder. Returns "Method not found" error.

**Workaround:** Reference MCP server documentation directly for capabilities.

---

## Template Engine (Now in Utilities)

**Note:** `utilTemplateEngine()` has been moved to `sdk-methods-utilities.md` as it's a general utility function, not AI-specific.

---

## Coverage Summary

| Category | Total | Implemented | Missing | Coverage |
|----------|-------|-------------|---------|----------|
| **AI Agent Execution** | 1 | 1 | 0 | 100% |
| **MCP Tool Execution** | 1 | 1 | 0 | 100% |
| **MCP Discovery** | 2 | 0 | 2 | 0% |
| **TOTAL** | 4 | 2 | 2 | **50%** |

**Analysis:**
- ✅ **Core functionality works** - You can run AI agents and execute MCP tools
- ❌ **Discovery tools missing** - Cannot programmatically discover MCP capabilities
- 🎯 **Practical impact** - Low. You typically know tool names in advance.

---

## What Works vs What Doesn't

### ✅ You CAN:
- Execute AI agents with custom prompts and data
- Allow agents to use tools
- Call external MCP tools by name
- Pass input data to MCP tools
- Integrate AI capabilities into Xano backends

### ❌ You CANNOT:
- Programmatically list available MCP tools
- Discover MCP server capabilities via code
- Query what tools an MCP server provides
- Get MCP server metadata

### 🔧 Workaround:
Document MCP tool names externally and reference them directly in your code.

---

## Real-World Example

**AI-Powered Customer Support Endpoint:**

```json
{
  "type": "endpoint",
  "name": "/api/support/analyze",
  "method": "POST",
  "operations": [
    {"method": "input", "args": ["customer_message", "text"]},
    {"method": "input", "args": ["customer_id", "integer"]},

    {"method": "dbGet", "args": ["customers", "$input.customer_id", "customer"]},

    {"method": "aiAgentRun", "args": [
      {
        "prompt": "Analyze this customer support message and suggest a response",
        "message": "$input.customer_message",
        "customer_history": "$customer"
      },
      true,
      "ai_analysis"
    ]},

    {"method": "aiExternalMcpToolRun", "args": [
      "$env.MCP_SERVER_URL",
      "$env.MCP_API_KEY",
      "sentiment_analysis",
      {"text": "$input.customer_message"},
      "sentiment"
    ]},

    {"method": "response", "args": [{
      "analysis": "$ai_analysis",
      "sentiment": "$sentiment",
      "customer": "$customer"
    }]}
  ]
}
```

**Generated XanoScript:**
```xanoscript
query "support_analyze" verb=POST {
  input {
    text customer_message
    integer customer_id
  }

  stack {
    db.get customers {
      id = $input.customer_id
    } as customer

    ai.agent.run {
      args = {
        "prompt": "Analyze this customer support message and suggest a response",
        "message": "$input.customer_message",
        "customer_history": "$customer"
      }
      allow_tool_execution = true
    } as ai_analysis

    ai.external.mcp.tool.run {
      mcp_url = $env.MCP_SERVER_URL
      api_key = $env.MCP_API_KEY
      tool_name = "sentiment_analysis"
      input = {"text": "$input.customer_message"}
    } as sentiment
  }

  response = {
    analysis: $ai_analysis,
    sentiment: $sentiment,
    customer: $customer
  }
}
```

---

**Total Methods in this File: 4**
- ✅ 2 Working (aiAgentRun, aiExternalMcpToolRun)
- ❌ 2 Not Implemented (aiExternalMcpToolList, aiExternalMcpServerDetails)

**Verification Status:**
- ✅ Verified 2025-01-13
- Core AI functionality confirmed working
- Discovery methods confirmed missing

For workflow guidance, see [workflow.md](workflow.md)
