const express = require('express');

const {
  getFarmModuleById,
  getFarmModules,
} = require('../controllers/farmModule.controller');

const router = express.Router();

router.get('/', getFarmModules);
router.get('/:id', getFarmModuleById);

module.exports = router;
