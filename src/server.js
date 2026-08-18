const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Application Health Check Endpoint for Zero-Downtime Verification
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Sample Business Route
app.get('/api/v1/info', (req, res) => {
  res.status(200).json({
    service: 'user-service',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

app.listen(PORT, () => {
  console.log(`Application started and listening on port ${PORT}`);
});