const express = require('express');

const { successResponse } = require('../utils/response');

const router = express.Router();

router.get('/', (req, res) =>
  successResponse(res, 'SeiCycle API is running', {
    service: 'SeiCycle Backend',
    status: 'healthy',
  }),
);

module.exports = router;
