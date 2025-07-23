const express = require('express');
const { spawn } = require('child_process');
const app = express();

app.post('/mcp', (req, res) => {
  // MCP stdio calls hier wrappen
});

app.listen(process.env.PORT || 3000);
