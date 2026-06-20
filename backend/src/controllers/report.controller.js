const { db } = require('../config/firebase');
const { FIRESTORE_CONNECTION_MESSAGE } = require('../utils/firestore');
const { getOperationalSummary } = require('../utils/operationalSummary');
const { errorResponse, successResponse } = require('../utils/response');

const getReportSummary = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const summary = await getOperationalSummary(db);
    return successResponse(res, 'Ringkasan laporan berhasil diambil', summary);
  } catch (error) {
    error.message = 'Gagal mengambil ringkasan laporan';
    return next(error);
  }
};

module.exports = { getReportSummary };
