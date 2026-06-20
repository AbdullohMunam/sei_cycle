const express = require('express');

const {
  createInventoryItem,
  deleteInventoryItem,
  getInventory,
  getInventoryItemById,
  updateInventoryItem,
} = require('../controllers/inventory.controller');

const router = express.Router();

router.get('/', getInventory);
router.post('/', createInventoryItem);
router.get('/:id', getInventoryItemById);
router.patch('/:id', updateInventoryItem);
router.delete('/:id', deleteInventoryItem);

module.exports = router;
