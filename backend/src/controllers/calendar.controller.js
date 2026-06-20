const { admin, db } = require('../config/firebase');
const {
  FIRESTORE_CONNECTION_MESSAGE,
  serializeTimestamp,
} = require('../utils/firestore');
const { errorResponse, successResponse } = require('../utils/response');

const COLLECTION_NAME = 'operational_schedules';
const REQUIRED_FIELDS = [
  'title',
  'module_id',
  'activity_type',
  'schedule_date',
  'created_by',
];
const EDITABLE_FIELDS = [
  ...REQUIRED_FIELDS,
  'schedule_time',
  'notes',
  'status',
];

const mapSchedule = (document) => {
  const data = document.data();

  return {
    schedule_id: data.schedule_id || document.id,
    title: data.title || '',
    module_id: data.module_id || '',
    activity_type: data.activity_type || '',
    schedule_date: data.schedule_date || '',
    schedule_time: data.schedule_time || '',
    notes: data.notes || '',
    status: data.status || 'pending',
    created_by: data.created_by || '',
    created_at: serializeTimestamp(data.created_at),
    updated_at: serializeTimestamp(data.updated_at),
  };
};

const validateSchedule = (body, isPartial = false) => {
  for (const field of REQUIRED_FIELDS) {
    if (
      (!isPartial || Object.prototype.hasOwnProperty.call(body, field)) &&
      (typeof body[field] !== 'string' || body[field].trim().length === 0)
    ) {
      return `Field ${field} wajib diisi`;
    }
  }

  if (
    body.schedule_date !== undefined &&
    !/^\d{4}-\d{2}-\d{2}$/.test(body.schedule_date)
  ) {
    return 'Field schedule_date harus berformat YYYY-MM-DD';
  }

  return null;
};

const buildUpdate = (body) =>
  EDITABLE_FIELDS.reduce((result, field) => {
    if (Object.prototype.hasOwnProperty.call(body, field)) {
      result[field] =
        typeof body[field] === 'string' ? body[field].trim() : body[field];
    }
    return result;
  }, {});

const getSchedules = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const snapshot = await db.collection(COLLECTION_NAME).get();
    const { date, module_id: moduleId, status } = req.query;
    const schedules = snapshot.docs
      .map(mapSchedule)
      .filter(
        (schedule) =>
          (!date || schedule.schedule_date === date) &&
          (!moduleId || schedule.module_id === moduleId) &&
          (!status || schedule.status === status),
      )
      .sort((first, second) =>
        `${first.schedule_date}T${first.schedule_time || '00:00'}`.localeCompare(
          `${second.schedule_date}T${second.schedule_time || '00:00'}`,
        ),
      );

    return successResponse(
      res,
      'Data kalender operasional berhasil diambil',
      schedules,
    );
  } catch (error) {
    error.message = 'Gagal mengambil kalender operasional';
    return next(error);
  }
};

const getScheduleById = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const document = await db
      .collection(COLLECTION_NAME)
      .doc(req.params.id)
      .get();

    if (!document.exists) {
      return errorResponse(res, 'Jadwal tidak ditemukan', null, 404);
    }

    return successResponse(
      res,
      'Detail jadwal berhasil diambil',
      mapSchedule(document),
    );
  } catch (error) {
    error.message = 'Gagal mengambil detail jadwal';
    return next(error);
  }
};

const createSchedule = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  const body = req.body || {};
  const validationMessage = validateSchedule(body);
  if (validationMessage) {
    return errorResponse(res, validationMessage, null, 400);
  }

  try {
    const document = db.collection(COLLECTION_NAME).doc();
    const timestamp = admin.firestore.Timestamp.now();
    const schedule = {
      schedule_id: document.id,
      title: body.title.trim(),
      module_id: body.module_id.trim(),
      activity_type: body.activity_type.trim(),
      schedule_date: body.schedule_date.trim(),
      schedule_time:
        typeof body.schedule_time === 'string'
          ? body.schedule_time.trim()
          : '',
      notes: typeof body.notes === 'string' ? body.notes.trim() : '',
      status:
        typeof body.status === 'string' && body.status.trim()
          ? body.status.trim()
          : 'pending',
      created_by: body.created_by.trim(),
      created_at: timestamp,
      updated_at: timestamp,
    };

    await document.set(schedule);
    return successResponse(
      res,
      'Jadwal berhasil ditambahkan',
      {
        ...schedule,
        created_at: serializeTimestamp(timestamp),
        updated_at: serializeTimestamp(timestamp),
      },
      201,
    );
  } catch (error) {
    error.message = 'Gagal menambahkan jadwal';
    return next(error);
  }
};

const updateSchedule = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  const body = req.body || {};
  const validationMessage = validateSchedule(body, true);
  if (validationMessage) {
    return errorResponse(res, validationMessage, null, 400);
  }

  const updates = buildUpdate(body);
  if (Object.keys(updates).length === 0) {
    return errorResponse(res, 'Tidak ada field yang dapat diubah', null, 400);
  }

  try {
    const document = db.collection(COLLECTION_NAME).doc(req.params.id);
    const snapshot = await document.get();

    if (!snapshot.exists) {
      return errorResponse(res, 'Jadwal tidak ditemukan', null, 404);
    }

    updates.updated_at = admin.firestore.Timestamp.now();
    await document.update(updates);
    const updatedDocument = await document.get();

    return successResponse(
      res,
      'Jadwal berhasil diperbarui',
      mapSchedule(updatedDocument),
    );
  } catch (error) {
    error.message = 'Gagal memperbarui jadwal';
    return next(error);
  }
};

const deleteSchedule = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const document = db.collection(COLLECTION_NAME).doc(req.params.id);
    const snapshot = await document.get();

    if (!snapshot.exists) {
      return errorResponse(res, 'Jadwal tidak ditemukan', null, 404);
    }

    await document.delete();
    return successResponse(res, 'Jadwal berhasil dihapus', {
      schedule_id: req.params.id,
    });
  } catch (error) {
    error.message = 'Gagal menghapus jadwal';
    return next(error);
  }
};

module.exports = {
  createSchedule,
  deleteSchedule,
  getScheduleById,
  getSchedules,
  updateSchedule,
};
