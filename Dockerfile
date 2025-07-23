FROM node:18-alpine

# Install express for HTTP wrapper
WORKDIR /app
RUN npm init -y && npm install express

# Install docker CLI to run notion MCP container
RUN apk add --no-cache docker-cli

# Set HTTP server with MCP wrapper
EXPOSE 3000
CMD ["node", "-e", "const express = require('express'); const { spawn } = require('child_process'); const app = express(); app.use(express.json()); app.get('/', (req, res) => res.json({status: 'ok', service: 'notion-mcp'})); app.post('/mcp', async (req, res) => { console.log('MCP request received:', req.body); try { console.log('Starting notion MCP container...'); const mcpProcess = spawn('docker', ['run', '-i', '--rm', '-e', 'INTERNAL_INTEGRATION_TOKEN=' + (process.env.NOTION_API_TOKEN || ''), 'mcp/notion'], { stdio: ['pipe', 'pipe', 'pipe'] }); mcpProcess.on('error', (err) => { console.error('Docker spawn error:', err); res.status(500).json({ error: 'Docker failed: ' + err.message }); }); mcpProcess.stdin.write(JSON.stringify(req.body) + '\\n'); mcpProcess.stdin.end(); let output = ''; let errorOutput = ''; mcpProcess.stdout.on('data', (data) => { console.log('MCP stdout:', data.toString()); output += data.toString(); }); mcpProcess.stderr.on('data', (data) => { console.log('MCP stderr:', data.toString()); errorOutput += data.toString(); }); mcpProcess.on('close', (code) => { console.log('MCP process closed with code:', code); if (output) { try { res.json(JSON.parse(output)); } catch (e) { res.status(500).json({ error: 'Invalid JSON: ' + output }); } } else { res.status(500).json({ error: 'No output from MCP server' }); } }); } catch (error) { console.error('Catch error:', error); res.status(500).json({ error: error.message }); } }); app.listen(3000, () => console.log('HTTP server running on port 3000'));"]
