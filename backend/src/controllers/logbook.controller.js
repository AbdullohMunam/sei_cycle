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

const getMissingFields = (body) =>
  REQUIRED_FIELDS.filter(
    (field) =>
      typeof body[field] !== 'string' || body[field].trim().length === 0,
  );

const getLogbooks = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const snapshot = await db.collection(COLLECTION_NAME).get();
    const logbooks = snapshot.docs
      .map(mapLogbook)
      .sort(sortByCreatedAtDescending);

    return successResponse(res, 'Data logbook berhasil diambil', logbooks);
  } catch (error) {
    error.message = 'Gagal mengambil data logbook';
    return next(error);
  }
};

const createLogbook = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, null, 503);
  }

  const body = req.body || {};
  const missingFields = getMissingFields(body);

  if (missingFields.length > 0) {
    return errorResponse(
      res,
      `Field wajib belum lengkap: ${missingFields.join(', ')}`,
      { missing_fields: missingFields },
      400,
    );
  }

  if (
    body.quantity !== undefined &&
    (typeof body.quantity !== 'number' || !Number.isFinite(body.quantity))
  ) {
    return errorResponse(res, 'quantity harus berupa angka', null, 400);
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

module.exports = { createLogbook, getLogbooks };
