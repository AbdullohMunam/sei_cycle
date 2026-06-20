const express = require('express');

const {
  createLogbook,
  getLogbooks,
} = require('../controllers/logbook.controller');

const router = express.Router();

router.get('/', getLogbooks);
router.post('/', createLogbook);

module.exports = router;
