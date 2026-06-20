const { db } = require('../config/firebase');
const {
  FIRESTORE_CONNECTION_MESSAGE,
  serializeTimestamp,
} = require('../utils/firestore');
const { errorResponse, successResponse } = require('../utils/response');

const COLLECTION_NAME = 'farm_modules';

const mapFarmModule = (document) => {
  const moduleData = document.data();

  return {
    module_id: moduleData.module_id || document.id,
    module_name: moduleData.module_name || '',
    module_type: moduleData.module_type || '',
    description: moduleData.description || '',
    is_active: moduleData.is_active ?? false,
    created_at: serializeTimestamp(moduleData.created_at),
    updated_at: serializeTimestamp(moduleData.updated_at),
  };
};

const sendFirestoreConnectionError = (res) =>
  errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);

const getFarmModules = async (req, res, next) => {
  if (!db) {
    return sendFirestoreConnectionError(res);
  }

  try {
    const snapshot = await db.collection(COLLECTION_NAME).get();
    const farmModules = snapshot.docs
      .map(mapFarmModule)
      .sort((firstModule, secondModule) =>
        firstModule.module_name.localeCompare(secondModule.module_name, 'id'),
      );

    return successResponse(res, 'Data modul berhasil diambil', farmModules);
  } catch (error) {
    error.message = 'Gagal mengambil data modul';
    return next(error);
  }
};

const getFarmModuleById = async (req, res, next) => {
  if (!db) {
    return sendFirestoreConnectionError(res);
  }

  try {
    const document = await db
      .collection(COLLECTION_NAME)
      .doc(req.params.id)
      .get();

    if (!document.exists) {
      return errorResponse(res, 'Modul tidak ditemukan', [], 404);
    }

    return successResponse(
      res,
      'Detail modul berhasil diambil',
      mapFarmModule(document),
    );
  } catch (error) {
    error.message = 'Gagal mengambil detail modul';
    return next(error);
  }
};

module.exports = { getFarmModuleById, getFarmModules };
