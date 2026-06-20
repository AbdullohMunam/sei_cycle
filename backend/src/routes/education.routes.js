const express = require('express');

const {
  createContent,
  deleteContent,
  getContentById,
  getContents,
  updateContent,
} = require('../controllers/education.controller');

const router = express.Router();

router.get('/', getContents);
router.post('/', createContent);
router.get('/:id', getContentById);
router.patch('/:id', updateContent);
router.delete('/:id', deleteContent);

module.exports = router;
