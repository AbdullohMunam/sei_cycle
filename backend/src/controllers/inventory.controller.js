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

const validateInventory = (body) => {
  const invalidFields = REQUIRED_STRING_FIELDS.filter(
    (field) =>
      typeof body[field] !== 'string' || body[field].trim().length === 0,
  );

  REQUIRED_NUMBER_FIELDS.forEach((field) => {
    if (typeof body[field] !== 'number' || !Number.isFinite(body[field])) {
      invalidFields.push(field);
    }
  });

  return invalidFields;
};

const getInventory = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const snapshot = await db.collection(COLLECTION_NAME).get();
    const inventory = snapshot.docs
      .map(mapInventoryItem)
      .sort(sortByCreatedAtDescending);

    return successResponse(
      res,
      'Data inventory berhasil diambil',
      inventory,
    );
  } catch (error) {
    error.message = 'Gagal mengambil data inventory';
    return next(error);
  }
};

const createInventoryItem = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, null, 503);
  }

  const body = req.body || {};
  const invalidFields = validateInventory(body);

  if (invalidFields.length > 0) {
    return errorResponse(
      res,
      `Field wajib tidak valid: ${invalidFields.join(', ')}`,
      { invalid_fields: invalidFields },
      400,
    );
  }

  if (body.stock < 0 || body.minimum_stock < 0) {
    return errorResponse(
      res,
      'stock dan minimum_stock tidak boleh negatif',
      null,
      400,
    );
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

module.exports = { createInventoryItem, getInventory };
