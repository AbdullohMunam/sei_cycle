const { admin, db } = require('../config/firebase');
const {
  FIRESTORE_CONNECTION_MESSAGE,
  serializeTimestamp,
  sortByCreatedAtDescending,
} = require('../utils/firestore');
const { errorResponse, successResponse } = require('../utils/response');

const COLLECTION_NAME = 'finance_transactions';
const ALLOWED_TYPES = ['income', 'expense'];
const REQUIRED_FIELDS = [
  'type',
  'category',
  'amount',
  'description',
  'transaction_date',
  'created_by',
];
const EDITABLE_FIELDS = [...REQUIRED_FIELDS, 'module_id'];

const mapTransaction = (document) => {
  const data = document.data();

  return {
    transaction_id: data.transaction_id || document.id,
    type: data.type || '',
    category: data.category || '',
    amount: data.amount ?? 0,
    description: data.description || '',
    transaction_date: data.transaction_date || '',
    module_id: data.module_id || '',
    created_by: data.created_by || '',
    created_at: serializeTimestamp(data.created_at),
    updated_at: serializeTimestamp(data.updated_at),
  };
};

const validateTransaction = (body, isPartial = false) => {
  for (const field of REQUIRED_FIELDS) {
    if (isPartial && !Object.prototype.hasOwnProperty.call(body, field)) {
      continue;
    }

    if (field === 'amount') {
      if (
        typeof body.amount !== 'number' ||
        !Number.isFinite(body.amount) ||
        body.amount < 0
      ) {
        return 'Field amount harus berupa angka nol atau lebih';
      }
    } else if (
      typeof body[field] !== 'string' ||
      body[field].trim().length === 0
    ) {
      return `Field ${field} wajib diisi`;
    }
  }

  if (body.type !== undefined && !ALLOWED_TYPES.includes(body.type)) {
    return 'Field type hanya boleh income atau expense';
  }

  if (
    body.transaction_date !== undefined &&
    !/^\d{4}-\d{2}-\d{2}$/.test(body.transaction_date)
  ) {
    return 'Field transaction_date harus berformat YYYY-MM-DD';
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

const getTransactions = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const snapshot = await db.collection(COLLECTION_NAME).get();
    const {
      category,
      end_date: endDate,
      module_id: moduleId,
      start_date: startDate,
      type,
    } = req.query;
    const transactions = snapshot.docs
      .map(mapTransaction)
      .filter(
        (transaction) =>
          (!type || transaction.type === type) &&
          (!category || transaction.category === category) &&
          (!moduleId || transaction.module_id === moduleId) &&
          (!startDate || transaction.transaction_date >= startDate) &&
          (!endDate || transaction.transaction_date <= endDate),
      )
      .sort((first, second) => {
        const dateComparison = second.transaction_date.localeCompare(
          first.transaction_date,
        );
        return dateComparison || sortByCreatedAtDescending(first, second);
      });

    return successResponse(
      res,
      'Data transaksi keuangan berhasil diambil',
      transactions,
    );
  } catch (error) {
    error.message = 'Gagal mengambil transaksi keuangan';
    return next(error);
  }
};

const getTransactionById = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const document = await db
      .collection(COLLECTION_NAME)
      .doc(req.params.id)
      .get();

    if (!document.exists) {
      return errorResponse(res, 'Transaksi tidak ditemukan', null, 404);
    }

    return successResponse(
      res,
      'Detail transaksi berhasil diambil',
      mapTransaction(document),
    );
  } catch (error) {
    error.message = 'Gagal mengambil detail transaksi';
    return next(error);
  }
};

const createTransaction = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  const body = req.body || {};
  const validationMessage = validateTransaction(body);
  if (validationMessage) {
    return errorResponse(res, validationMessage, null, 400);
  }

  try {
    const document = db.collection(COLLECTION_NAME).doc();
    const timestamp = admin.firestore.Timestamp.now();
    const transaction = {
      transaction_id: document.id,
      type: body.type.trim(),
      category: body.category.trim(),
      amount: body.amount,
      description: body.description.trim(),
      transaction_date: body.transaction_date.trim(),
      module_id:
        typeof body.module_id === 'string' ? body.module_id.trim() : '',
      created_by: body.created_by.trim(),
      created_at: timestamp,
      updated_at: timestamp,
    };

    await document.set(transaction);
    return successResponse(
      res,
      'Transaksi berhasil ditambahkan',
      {
        ...transaction,
        created_at: serializeTimestamp(timestamp),
        updated_at: serializeTimestamp(timestamp),
      },
      201,
    );
  } catch (error) {
    error.message = 'Gagal menambahkan transaksi';
    return next(error);
  }
};

const updateTransaction = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  const body = req.body || {};
  const validationMessage = validateTransaction(body, true);
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
      return errorResponse(res, 'Transaksi tidak ditemukan', null, 404);
    }

    updates.updated_at = admin.firestore.Timestamp.now();
    await document.update(updates);
    const updatedDocument = await document.get();

    return successResponse(
      res,
      'Transaksi berhasil diperbarui',
      mapTransaction(updatedDocument),
    );
  } catch (error) {
    error.message = 'Gagal memperbarui transaksi';
    return next(error);
  }
};

const deleteTransaction = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const document = db.collection(COLLECTION_NAME).doc(req.params.id);
    const snapshot = await document.get();

    if (!snapshot.exists) {
      return errorResponse(res, 'Transaksi tidak ditemukan', null, 404);
    }

    await document.delete();
    return successResponse(res, 'Transaksi berhasil dihapus', {
      transaction_id: req.params.id,
    });
  } catch (error) {
    error.message = 'Gagal menghapus transaksi';
    return next(error);
  }
};

const getFinanceSummary = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const snapshot = await db.collection(COLLECTION_NAME).get();
    const { end_date: endDate, start_date: startDate } = req.query;
    const transactions = snapshot.docs
      .map(mapTransaction)
      .filter(
        (transaction) =>
          (!startDate || transaction.transaction_date >= startDate) &&
          (!endDate || transaction.transaction_date <= endDate),
      );
    const totalIncome = transactions
      .filter((transaction) => transaction.type === 'income')
      .reduce((total, transaction) => total + transaction.amount, 0);
    const totalExpense = transactions
      .filter((transaction) => transaction.type === 'expense')
      .reduce((total, transaction) => total + transaction.amount, 0);

    return successResponse(res, 'Ringkasan keuangan berhasil diambil', {
      total_income: totalIncome,
      total_expense: totalExpense,
      profit: totalIncome - totalExpense,
      transaction_count: transactions.length,
    });
  } catch (error) {
    error.message = 'Gagal mengambil ringkasan keuangan';
    return next(error);
  }
};

module.exports = {
  createTransaction,
  deleteTransaction,
  getFinanceSummary,
  getTransactionById,
  getTransactions,
  updateTransaction,
};
