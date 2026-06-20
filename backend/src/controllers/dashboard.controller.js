const { db } = require('../config/firebase');
const { FIRESTORE_CONNECTION_MESSAGE } = require('../utils/firestore');
const { getOperationalSummary } = require('../utils/operationalSummary');
const { errorResponse, successResponse } = require('../utils/response');

const formatLocalDate = (date) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');

  return `${year}-${month}-${day}`;
};

const getDocumentLocalDate = (document) => {
  const data = document.data();

  if (typeof data.date === 'string' && data.date) {
    return data.date;
  }

  if (typeof data.activity_date === 'string' && data.activity_date) {
    return data.activity_date;
  }

  if (data.created_at && typeof data.created_at.toDate === 'function') {
    return formatLocalDate(data.created_at.toDate());
  }

  if (data.created_at instanceof Date) {
    return formatLocalDate(data.created_at);
  }

  return '';
};

const getDashboardSummary = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  const selectedDate = req.query.date || formatLocalDate(new Date());
  if (!/^\d{4}-\d{2}-\d{2}$/.test(selectedDate)) {
    return errorResponse(
      res,
      'Field date harus berformat YYYY-MM-DD',
      null,
      400,
    );
  }

  try {
    const [summary, logbooksSnapshot, schedulesSnapshot] = await Promise.all([
      getOperationalSummary(db, true),
      db.collection('logbooks').get(),
      db.collection('operational_schedules').get(),
    ]);

    return successResponse(
      res,
      'Ringkasan dashboard berhasil diambil',
      {
        ...summary,
        today_logbooks: logbooksSnapshot.docs.filter(
          (document) => getDocumentLocalDate(document) === selectedDate,
        ).length,
        today_schedules: schedulesSnapshot.docs.filter(
          (document) => document.data().schedule_date === selectedDate,
        ).length,
      },
    );
  } catch (error) {
    error.message = 'Gagal mengambil ringkasan dashboard';
    return next(error);
  }
};

module.exports = { getDashboardSummary };
