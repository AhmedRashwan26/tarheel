const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 8085;
const staticDir = path.join(__dirname, 'tarheel_app', 'build', 'web');

app.use(express.static(staticDir));

app.get('*', (req, res) => {
  res.sendFile(path.join(staticDir, 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`📱 Tarheel Web App running on http://localhost:${PORT}`);
});
