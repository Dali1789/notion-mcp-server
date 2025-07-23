# Use Node.js LTS
FROM node:18-alpine

# Install git and build dependencies
RUN apk add --no-cache git python3 make g++

# Clone the official notion-mcp-server
WORKDIR /app
RUN git clone https://github.com/makenotion/notion-mcp-server.git .

# Install dependencies and build
RUN npm install
RUN npm run build

# Install express for HTTP wrapper
RUN npm install express

# Create the HTTP wrapper as .cjs file
RUN echo 'const express = require("express"); \
const { spawn } = require("child_process"); \
const app = express(); \
app.use(express.json()); \
app.get("/", (req, res) => res.json({status: "ok", service: "notion-mcp"})); \
app.post("/mcp", async (req, res) => { \
  console.log("MCP request received:", req.body); \
  try { \
    const mcpProcess = spawn("node", ["bin/cli.mjs", "--help"], { \
      stdio: ["pipe", "pipe", "pipe"], \
      env: { ...process.env, INTERNAL_INTEGRATION_TOKEN: process.env.NOTION_API_TOKEN } \
    }); \
    mcpProcess.stdin.end(); \
    let output = ""; \
    mcpProcess.stdout.on("data", (data) => { \
      console.log("Directory listing:", data.toString()); \
      output += data.toString(); \
    }); \
    mcpProcess.stderr.on("data", (data) => { \
      console.log("Listing stderr:", data.toString()); \
    }); \
    mcpProcess.on("close", (code) => { \
      console.log("Listing process closed with code:", code); \
      res.json({ build_contents: output }); \
    }); \
  } catch (error) { \
    res.status(500).json({ error: error.message }); \
  } \
}); \
app.listen(3000, () => console.log("HTTP server running on port 3000"));' > server.cjs

# Set environment
ENV NOTION_API_TOKEN=""

# Expose port
EXPOSE 3000

# Start the HTTP wrapper
CMD ["node", "server.cjs"]
