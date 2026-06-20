const { admin } = require('../config/firebase');
const { errorResponse } = require('../utils/response');

const verifyFirebaseToken = async (req, res, next) => {
  const authorizationHeader = req.headers.authorization || '';
  const [scheme, token, extraPart] = authorizationHeader.trim().split(/\s+/);

  if (scheme !== 'Bearer' || !token || extraPart) {
    return errorResponse(
      res,
      'Token autentikasi tidak ditemukan',
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

module.exports = { verifyFirebaseToken };
