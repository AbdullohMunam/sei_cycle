const express = require('express');

const { getFarmModules } = require('../controllers/farmModule.controller');

const router = express.Router();

router.get('/', getFarmModules);

module.exports = router;
