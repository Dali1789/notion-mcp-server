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
  proc.stdout.on("data", d => out += d); \
  proc.on("close", () => { \
    if(out) res.json(JSON.parse(out)); \
    else res.json({error: "no output"}); \
  }); \
}); \
app.listen(3000);' > server.js

# Start server
CMD ["node", "server.js"]
