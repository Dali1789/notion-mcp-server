const express = require('express');
const { spawn } = require('child_process');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'notion-mcp-server' });
});

app.post('/mcp', async (req, res) => {
  try {
    const mcpProcess = spawn('notion-mcp-server', [], {
      stdio: ['pipe', 'pipe', 'pipe']
    });
    
    mcpProcess.stdin.write(JSON.stringify(req.body) + '\n');
    mcpProcess.stdin.end();
    
    let output = '';
    mcpProcess.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    mcpProcess.on('close', () => {
      try {
        res.json(JSON.parse(output));
      } catch (e) {
        res.status(500).json({ error: 'Invalid JSON response' });
      }
    });
    
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(port, () => {
  console.log(`MCP HTTP Server running on port ${port}`);
});
