const { db } = require('../config/firebase');
const {
  FIRESTORE_CONNECTION_MESSAGE,
  serializeTimestamp,
} = require('../utils/firestore');
const { errorResponse, successResponse } = require('../utils/response');

const getCurrentUser = async (req, res, next) => {
  if (!req.user?.uid) {
    return errorResponse(res, 'Token autentikasi tidak valid', null, 401);
  }

  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const document = await db.collection('users').doc(req.user.uid).get();

    if (!document.exists) {
      return successResponse(
        res,
        'Profil user berhasil diambil dari Firebase Authentication',
        {
          user_id: req.user.uid,
          name: req.user.name || '',
          email: req.user.email || '',
          role: '',
          photo_url: req.user.picture || '',
          is_active: true,
          created_at: null,
          updated_at: null,
        },
      );
    }

    const user = document.data();

    return successResponse(res, 'Profil user berhasil diambil', {
      user_id: document.id,
      name: user.name || '',
      email: user.email || req.user.email || '',
      role: user.role || '',
      photo_url: user.photo_url || req.user.picture || '',
      is_active: user.is_active ?? true,
      created_at: serializeTimestamp(user.created_at),
      updated_at: serializeTimestamp(user.updated_at),
    });
  } catch (error) {
    error.message = 'Gagal mengambil profil user';
    return next(error);
  }
};

module.exports = { getCurrentUser };
