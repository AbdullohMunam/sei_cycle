const express = require('express');

const { getCurrentUser } = require('../controllers/user.controller');
const {
  verifyFirebaseToken,
} = require('../middlewares/auth.middleware');

const router = express.Router();

router.get('/me', verifyFirebaseToken, getCurrentUser);

module.exports = router;
