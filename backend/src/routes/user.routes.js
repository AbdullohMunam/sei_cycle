const express = require('express');

const { getCurrentUser } = require('../controllers/user.controller');

const router = express.Router();

router.get('/me', getCurrentUser);

module.exports = router;
