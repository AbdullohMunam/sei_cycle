const { admin, db } = require('../config/firebase');
const {
  FIRESTORE_CONNECTION_MESSAGE,
  serializeTimestamp,
  sortByCreatedAtDescending,
} = require('../utils/firestore');
const { errorResponse, successResponse } = require('../utils/response');

const COLLECTION_NAME = 'logbooks';
const REQUIRED_FIELDS = [
  'module_id',
  'activity_type',
  'description',
  'created_by',
];
const EDITABLE_FIELDS = [
  'module_id',
  'activity_type',
  'description',
  'quantity',
  'unit',
  'notes',
];
const EDITABLE_REQUIRED_STRING_FIELDS = [
  'module_id',
  'activity_type',
  'description',
];

const mapLogbook = (document) => {
  const data = document.data();

  return {
    logbook_id: data.logbook_id || document.id,
    module_id: data.module_id || '',
    activity_type: data.activity_type || '',
    description: data.description || '',
    quantity: data.quantity ?? null,
    unit: data.unit || '',
    notes: data.notes || '',
    created_by: data.created_by || '',
    created_at: serializeTimestamp(data.created_at),
    updated_at: serializeTimestamp(data.updated_at),
  };
};

const getLogbookDate = (document) => {
  const data = document.data();
  const createdAt = serializeTimestamp(data.created_at);

  return data.date || data.activity_date || createdAt?.slice(0, 10) || '';
};

const getMissingField = (body) =>
  REQUIRED_FIELDS.find(
    (field) =>
      typeof body[field] !== 'string' || body[field].trim().length === 0,
  );

const validateEditableValues = (body) => {
  const emptyRequiredField = EDITABLE_REQUIRED_STRING_FIELDS.find(
    (field) =>
      Object.prototype.hasOwnProperty.call(body, field) &&
      (typeof body[field] !== 'string' || body[field].trim().length === 0),
  );

  if (emptyRequiredField) {
    return `Field ${emptyRequiredField} wajib diisi`;
  }

  if (
    body.quantity !== undefined &&
    body.quantity !== null &&
    (typeof body.quantity !== 'number' || !Number.isFinite(body.quantity))
  ) {
    return 'Field quantity harus berupa angka';
  }

  return null;
};

const buildUpdate = (body) =>
  EDITABLE_FIELDS.reduce((result, field) => {
    if (!Object.prototype.hasOwnProperty.call(body, field)) {
      return result;
    }

    const value = body[field];
    result[field] = typeof value === 'string' ? value.trim() : value;
    return result;
  }, {});

const getLogbooks = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const snapshot = await db.collection(COLLECTION_NAME).get();
    const {
      activity_type: activityType,
      date,
      module_id: moduleId,
    } = req.query;
    const logbooks = snapshot.docs
      .filter(
        (document) => {
          const data = document.data();

          return (
            (!moduleId || data.module_id === moduleId) &&
            (!activityType || data.activity_type === activityType) &&
            (!date || getLogbookDate(document) === date)
          );
        },
      )
      .map(mapLogbook)
      .sort(sortByCreatedAtDescending);

    return successResponse(res, 'Data logbook berhasil diambil', logbooks);
  } catch (error) {
    error.message = 'Gagal mengambil data logbook';
    return next(error);
  }
};

const getLogbookById = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const document = await db
      .collection(COLLECTION_NAME)
      .doc(req.params.id)
      .get();

    if (!document.exists) {
      return errorResponse(res, 'Logbook tidak ditemukan', null, 404);
    }

    return successResponse(
      res,
      'Detail logbook berhasil diambil',
      mapLogbook(document),
    );
  } catch (error) {
    error.message = 'Gagal mengambil detail logbook';
    return next(error);
  }
};

const createLogbook = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  const body = req.body || {};
  const missingField = getMissingField(body);

  if (missingField) {
    return errorResponse(
      res,
      `Field ${missingField} wajib diisi`,
      null,
      400,
    );
  }

  const validationMessage = validateEditableValues(body);
  if (validationMessage) {
    return errorResponse(res, validationMessage, null, 400);
  }

  try {
    const document = db.collection(COLLECTION_NAME).doc();
    const timestamp = admin.firestore.Timestamp.now();
    const logbook = {
      logbook_id: document.id,
      module_id: body.module_id.trim(),
      activity_type: body.activity_type.trim(),
      description: body.description.trim(),
      quantity: body.quantity ?? null,
      unit: typeof body.unit === 'string' ? body.unit.trim() : '',
      notes: typeof body.notes === 'string' ? body.notes.trim() : '',
      created_by: body.created_by.trim(),
      created_at: timestamp,
      updated_at: timestamp,
    };

    await document.set(logbook);

    return successResponse(
      res,
      'Logbook berhasil ditambahkan',
      {
        ...logbook,
        created_at: serializeTimestamp(timestamp),
        updated_at: serializeTimestamp(timestamp),
      },
      201,
    );
  } catch (error) {
    error.message = 'Gagal menambahkan logbook';
    return next(error);
  }
};

const updateLogbook = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  const body = req.body || {};
  const validationMessage = validateEditableValues(body);
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
      return errorResponse(res, 'Logbook tidak ditemukan', null, 404);
    }

    updates.updated_at = admin.firestore.Timestamp.now();
    await document.update(updates);
    const updatedDocument = await document.get();

    return successResponse(
      res,
      'Logbook berhasil diperbarui',
      mapLogbook(updatedDocument),
    );
  } catch (error) {
    error.message = 'Gagal memperbarui logbook';
    return next(error);
  }
};

const deleteLogbook = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const document = db.collection(COLLECTION_NAME).doc(req.params.id);
    const snapshot = await document.get();

    if (!snapshot.exists) {
      return errorResponse(res, 'Logbook tidak ditemukan', null, 404);
    }

    await document.delete();
    return successResponse(res, 'Logbook berhasil dihapus', {
      logbook_id: req.params.id,
    });
  } catch (error) {
    error.message = 'Gagal menghapus logbook';
    return next(error);
  }
};

module.exports = {
  createLogbook,
  deleteLogbook,
  getLogbookById,
  getLogbooks,
  updateLogbook,
};
