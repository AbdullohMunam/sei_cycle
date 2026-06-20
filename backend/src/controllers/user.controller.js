const { db } = require('../config/firebase');
const { serializeTimestamp } = require('../utils/firestore');
const { errorResponse, successResponse } = require('../utils/response');

const getCurrentUser = async (req, res, next) => {
  try {
    const document = await db.collection('users').doc(req.user.uid).get();

    if (!document.exists) {
      return errorResponse(res, 'Profil user tidak ditemukan', null, 404);
    }

    const user = document.data();

    return successResponse(res, 'Profil user berhasil diambil', {
      user_id: document.id,
      name: user.name || '',
      email: user.email || req.user.email || '',
      role: user.role || '',
      photo_url: user.photo_url || '',
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
