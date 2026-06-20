const express = require('express');

const { getCurrentUser } = require('../controllers/user.controller');
const { authenticate } = require('../middlewares/authenticate');

const router = express.Router();

router.get('/me', authenticate, getCurrentUser);

module.exports = router;
