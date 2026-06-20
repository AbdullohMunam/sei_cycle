const express = require('express');

const router = express.Router();

router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'SeiCycle API is running',
    data: {
      service: 'SeiCycle Backend',
      status: 'healthy',
    },
  });
});

module.exports = router;
