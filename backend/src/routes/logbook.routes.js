const express = require('express');

const {
  createLogbook,
  deleteLogbook,
  getLogbookById,
  getLogbooks,
  updateLogbook,
} = require('../controllers/logbook.controller');

const router = express.Router();

router.get('/', getLogbooks);
router.post('/', createLogbook);
router.get('/:id', getLogbookById);
router.patch('/:id', updateLogbook);
router.delete('/:id', deleteLogbook);

module.exports = router;
