const { admin, db } = require('../config/firebase');
const {
  FIRESTORE_CONNECTION_MESSAGE,
  serializeTimestamp,
  sortByCreatedAtDescending,
} = require('../utils/firestore');
const { errorResponse, successResponse } = require('../utils/response');

const COLLECTION_NAME = 'inventory_items';
const REQUIRED_STRING_FIELDS = ['item_name', 'category', 'unit'];
const REQUIRED_NUMBER_FIELDS = ['stock', 'minimum_stock'];
const EDITABLE_FIELDS = [
  ...REQUIRED_STRING_FIELDS,
  ...REQUIRED_NUMBER_FIELDS,
];

const mapInventoryItem = (document) => {
  const data = document.data();

  return {
    item_id: data.item_id || document.id,
    item_name: data.item_name || '',
    category: data.category || '',
    stock: data.stock ?? 0,
    unit: data.unit || '',
    minimum_stock: data.minimum_stock ?? 0,
    is_low_stock: data.is_low_stock ?? false,
    created_at: serializeTimestamp(data.created_at),
    updated_at: serializeTimestamp(data.updated_at),
  };
};

const validateInventory = (body, isPartial = false) => {
  for (const field of REQUIRED_STRING_FIELDS) {
    if (
      (!isPartial || Object.prototype.hasOwnProperty.call(body, field)) &&
      (typeof body[field] !== 'string' || body[field].trim().length === 0)
    ) {
      return `Field ${field} wajib diisi`;
    }
  }

  for (const field of REQUIRED_NUMBER_FIELDS) {
    if (
      (!isPartial || Object.prototype.hasOwnProperty.call(body, field)) &&
      (typeof body[field] !== 'number' ||
        !Number.isFinite(body[field]) ||
        body[field] < 0)
    ) {
      return `Field ${field} harus berupa angka nol atau lebih`;
    }
  }

  return null;
};

const buildUpdate = (body) =>
  EDITABLE_FIELDS.reduce((result, field) => {
    if (!Object.prototype.hasOwnProperty.call(body, field)) {
      return result;
    }

    result[field] =
      typeof body[field] === 'string' ? body[field].trim() : body[field];
    return result;
  }, {});

const getInventory = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const snapshot = await db.collection(COLLECTION_NAME).get();
    const inventory = snapshot.docs
      .map(mapInventoryItem)
      .sort(sortByCreatedAtDescending);

    return successResponse(res, 'Data inventory berhasil diambil', inventory);
  } catch (error) {
    error.message = 'Gagal mengambil data inventory';
    return next(error);
  }
};

const getInventoryItemById = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const document = await db
      .collection(COLLECTION_NAME)
      .doc(req.params.id)
      .get();

    if (!document.exists) {
      return errorResponse(res, 'Item inventory tidak ditemukan', null, 404);
    }

    return successResponse(
      res,
      'Detail item inventory berhasil diambil',
      mapInventoryItem(document),
    );
  } catch (error) {
    error.message = 'Gagal mengambil detail item inventory';
    return next(error);
  }
};

const createInventoryItem = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  const body = req.body || {};
  const validationMessage = validateInventory(body);
  if (validationMessage) {
    return errorResponse(res, validationMessage, null, 400);
  }

  try {
    const document = db.collection(COLLECTION_NAME).doc();
    const timestamp = admin.firestore.Timestamp.now();
    const inventoryItem = {
      item_id: document.id,
      item_name: body.item_name.trim(),
      category: body.category.trim(),
      stock: body.stock,
      unit: body.unit.trim(),
      minimum_stock: body.minimum_stock,
      is_low_stock: body.stock <= body.minimum_stock,
      created_at: timestamp,
      updated_at: timestamp,
    };

    await document.set(inventoryItem);

    return successResponse(
      res,
      'Item inventory berhasil ditambahkan',
      {
        ...inventoryItem,
        created_at: serializeTimestamp(timestamp),
        updated_at: serializeTimestamp(timestamp),
      },
      201,
    );
  } catch (error) {
    error.message = 'Gagal menambahkan item inventory';
    return next(error);
  }
};

const updateInventoryItem = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  const body = req.body || {};
  const validationMessage = validateInventory(body, true);
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
      return errorResponse(res, 'Item inventory tidak ditemukan', null, 404);
    }

    const current = snapshot.data();
    const stock = updates.stock ?? current.stock ?? 0;
    const minimumStock =
      updates.minimum_stock ?? current.minimum_stock ?? 0;

    updates.is_low_stock = stock <= minimumStock;
    updates.updated_at = admin.firestore.Timestamp.now();
    await document.update(updates);
    const updatedDocument = await document.get();

    return successResponse(
      res,
      'Item inventory berhasil diperbarui',
      mapInventoryItem(updatedDocument),
    );
  } catch (error) {
    error.message = 'Gagal memperbarui item inventory';
    return next(error);
  }
};

const deleteInventoryItem = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const document = db.collection(COLLECTION_NAME).doc(req.params.id);
    const snapshot = await document.get();

    if (!snapshot.exists) {
      return errorResponse(res, 'Item inventory tidak ditemukan', null, 404);
    }

    await document.delete();
    return successResponse(res, 'Item inventory berhasil dihapus', {
      item_id: req.params.id,
    });
  } catch (error) {
    error.message = 'Gagal menghapus item inventory';
    return next(error);
  }
};

module.exports = {
  createInventoryItem,
  deleteInventoryItem,
  getInventory,
  getInventoryItemById,
  updateInventoryItem,
};
