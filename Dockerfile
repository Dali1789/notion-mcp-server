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

# Check what was actually built
RUN echo "=== BUILD CONTENTS ===" && find build -name "*.js" -type f

# Install express for HTTP wrapper
RUN npm install express

# Set environment
ENV NOTION_API_TOKEN=""

# Expose port
EXPOSE 3000

# Create server file properly
COPY <<EOF server.cjs
const express = require("express");
const { spawn } = require("child_process");
const app = express();

app.use(express.json());
app.get("/", (req, res) => res.json({status: "ok"}));

app.post("/mcp", (req, res) => {
  console.log("Request:", req.body);
  
  // Show what files exist
  const listProc = spawn("find", ["build", "-name", "*.js"], {
    stdio: ["pipe", "pipe", "pipe"]
  });
  
  let files = "";
  listProc.stdout.on("data", d => files += d);
  listProc.on("close", () => {
    console.log("Available files:", files);
    res.json({
      available_files: files.split("\\n").filter(f => f)
    });
  });
});

app.listen(3000, () => console.log("Server running"));
EOF

# Start server
CMD ["node", "server.cjs"]
