{
  "mcpServers": {
    "Get clean url via MCP": {
      "command": "uv",
      "args": [
        "run",
        "--with",
        "markdownify",
        "--with",
        "mcp[cli]",
        "--with",
        "toml",
        "mcp",
        "run",
        "/Users/reuteras/Documents/workspace/mcp-clean-url/src/mcp_clean_url/server.py"
      ]
    },
    "Searxng via MCP": {
      "command": "uv",
      "args": [
        "run",
        "--with",
        "mcp[cli]",
        "--with",
        "toml",
        "mcp",
        "run",
        "/Users/reuteras/Documents/workspace/mcp-search-searxng/src/mcp_search_searxng/server.py"
      ]
    },
    "Readwise MCP": {
      "command": "npx",
      "args": [
        "-y",
        "@readwise/readwise-mcp"
      ],
      "env": {
        "ACCESS_TOKEN": "${READWISE_API_KEY}"
      }
    }
  },
  "globalShortcut": ""
}
