const { admin, db } = require('../config/firebase');
const { FIRESTORE_CONNECTION_MESSAGE } = require('../utils/firestore');
const { errorResponse } = require('../utils/response');

const authenticate = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, null, 503);
  }

  const authorizationHeader = req.headers.authorization || '';
  const [scheme, token] = authorizationHeader.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return errorResponse(
      res,
      'Token autentikasi diperlukan',
      null,
      401,
    );
  }

  try {
    req.user = await admin.auth().verifyIdToken(token);
    return next();
  } catch (error) {
    return errorResponse(
      res,
      'Token autentikasi tidak valid',
      null,
      401,
    );
  }
};

module.exports = { authenticate };
