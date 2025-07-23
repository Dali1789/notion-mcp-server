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

# Set environment
ENV NOTION_API_TOKEN=""

# Expose port
EXPOSE 3000

# Create simple server
RUN echo 'const express = require("express"); \
const { spawn } = require("child_process"); \
const app = express(); \
app.use(express.json()); \
app.get("/", (req, res) => res.json({status: "ok"})); \
app.post("/mcp", (req, res) => { \
  console.log("Request:", req.body); \
  const proc = spawn("node", ["build/src/init-server.js"], { \
    stdio: ["pipe", "pipe", "pipe"], \
    env: {...process.env, INTERNAL_INTEGRATION_TOKEN: process.env.NOTION_API_TOKEN} \
  }); \
  proc.stdin.write(JSON.stringify(req.body) + "\\n"); \
  proc.stdin.end(); \
  let out = ""; \
  let err = ""; \
  proc.stdout.on("data", d => { \
    console.log("MCP stdout:", d.toString()); \
    out += d; \
  }); \
  proc.stderr.on("data", d => { \
    console.log("MCP stderr:", d.toString()); \
    err += d; \
  }); \
  proc.on("close", code => { \
    console.log("MCP closed with code:", code); \
    console.log("Output length:", out.length); \
    console.log("Error length:", err.length); \
    if(out) { \
      try { res.json(JSON.parse(out)); } \
      catch(e) { res.json({raw: out}); } \
    } else { \
      res.json({error: "no output", stderr: err, code: code}); \
    } \
  }); \
}); \
app.listen(3000, () => console.log("Server running"));' > server.cjs

# Start server
CMD ["node", "server.cjs"]
