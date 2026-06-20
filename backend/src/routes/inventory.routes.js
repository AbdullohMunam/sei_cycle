const express = require('express');

const {
  createInventoryItem,
  getInventory,
} = require('../controllers/inventory.controller');

const router = express.Router();

router.get('/', getInventory);
router.post('/', createInventoryItem);

module.exports = router;
