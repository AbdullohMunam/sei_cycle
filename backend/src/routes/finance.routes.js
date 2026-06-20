const express = require('express');

const {
  createTransaction,
  deleteTransaction,
  getFinanceSummary,
  getTransactionById,
  getTransactions,
  updateTransaction,
} = require('../controllers/finance.controller');

const router = express.Router();

router.get('/transactions', getTransactions);
router.post('/transactions', createTransaction);
router.get('/transactions/:id', getTransactionById);
router.patch('/transactions/:id', updateTransaction);
router.delete('/transactions/:id', deleteTransaction);
router.get('/summary', getFinanceSummary);

module.exports = router;
