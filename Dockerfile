# Minimal image for runtime
FROM node:20-slim

# Install express for HTTP server
RUN npm install -g express

# Copy built package from builder stage
COPY scripts/notion-openapi.json /usr/local/scripts/
COPY --from=builder /usr/local/lib/node_modules/@notionhq/notion-mcp-server /usr/local/lib/node_modules/@notionhq/notion-mcp-server
COPY --from=builder /usr/local/bin/notion-mcp-server /usr/local/bin/notion-mcp-server

# Set default environment variables
ENV OPENAPI_MCP_HEADERS="{}"

# Set HTTP server
EXPOSE 3000
CMD ["node", "-e", "const express = require('express'); const app = express(); app.get('/', (req, res) => res.json({status: 'ok', service: 'notion-mcp'})); app.listen(3000, () => console.log('HTTP server running on port 3000'));"]
