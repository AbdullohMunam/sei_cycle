const { db } = require('../config/firebase');
const { FIRESTORE_CONNECTION_MESSAGE } = require('../utils/firestore');
const { errorResponse, successResponse } = require('../utils/response');

const getCollectionCount = async (collectionName) => {
  const snapshot = await db.collection(collectionName).count().get();
  return snapshot.data().count;
};

const getDashboardSummary = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, null, 503);
  }

  try {
    const [
      totalModules,
      activeModulesSnapshot,
      totalLogbooks,
      totalInventoryItems,
    ] = await Promise.all([
      getCollectionCount('farm_modules'),
      db
        .collection('farm_modules')
        .where('is_active', '==', true)
        .count()
        .get(),
      getCollectionCount('logbooks'),
      getCollectionCount('inventory_items'),
    ]);

    return successResponse(res, 'Ringkasan dashboard berhasil diambil', {
      total_modules: totalModules,
      active_modules: activeModulesSnapshot.data().count,
      total_logbooks: totalLogbooks,
      total_inventory_items: totalInventoryItems,
    });
  } catch (error) {
    error.message = 'Gagal mengambil ringkasan dashboard';
    return next(error);
  }
};

module.exports = { getDashboardSummary };
