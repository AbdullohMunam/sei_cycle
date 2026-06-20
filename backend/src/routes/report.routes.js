const express = require('express');

const {
  getReportSummary,
} = require('../controllers/report.controller');

const router = express.Router();

router.get('/summary', getReportSummary);

module.exports = router;
