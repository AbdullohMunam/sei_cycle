const { admin, db } = require('../config/firebase');
const {
  FIRESTORE_CONNECTION_MESSAGE,
  serializeTimestamp,
  sortByCreatedAtDescending,
} = require('../utils/firestore');
const { errorResponse, successResponse } = require('../utils/response');

const COLLECTION_NAME = 'education_contents';
const ALLOWED_TYPES = ['article', 'video', 'sop'];
const REQUIRED_FIELDS = ['title', 'type', 'category', 'description'];
const EDITABLE_FIELDS = [
  ...REQUIRED_FIELDS,
  'content_url',
  'module_id',
  'is_published',
];

const mapContent = (document) => {
  const data = document.data();

  return {
    content_id: data.content_id || document.id,
    title: data.title || '',
    type: data.type || '',
    category: data.category || '',
    description: data.description || '',
    content_url: data.content_url || '',
    module_id: data.module_id || '',
    is_published: data.is_published ?? false,
    created_at: serializeTimestamp(data.created_at),
    updated_at: serializeTimestamp(data.updated_at),
  };
};

const validateContent = (body, isPartial = false) => {
  for (const field of REQUIRED_FIELDS) {
    if (
      (!isPartial || Object.prototype.hasOwnProperty.call(body, field)) &&
      (typeof body[field] !== 'string' || body[field].trim().length === 0)
    ) {
      return `Field ${field} wajib diisi`;
    }
  }

  if (body.type !== undefined && !ALLOWED_TYPES.includes(body.type)) {
    return 'Field type hanya boleh article, video, atau sop';
  }

  if (
    body.is_published !== undefined &&
    typeof body.is_published !== 'boolean'
  ) {
    return 'Field is_published harus berupa boolean';
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

const getContents = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const snapshot = await db.collection(COLLECTION_NAME).get();
    const {
      category,
      is_published: publishedQuery,
      module_id: moduleId,
      type,
    } = req.query;
    const published =
      publishedQuery === undefined ? null : publishedQuery === 'true';
    const contents = snapshot.docs
      .map(mapContent)
      .filter(
        (content) =>
          (!type || content.type === type) &&
          (!category || content.category === category) &&
          (!moduleId || content.module_id === moduleId) &&
          (published === null || content.is_published === published),
      )
      .sort(sortByCreatedAtDescending);

    return successResponse(
      res,
      'Data edukasi berhasil diambil',
      contents,
    );
  } catch (error) {
    error.message = 'Gagal mengambil data edukasi';
    return next(error);
  }
};

const getContentById = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const document = await db
      .collection(COLLECTION_NAME)
      .doc(req.params.id)
      .get();

    if (!document.exists) {
      return errorResponse(res, 'Konten edukasi tidak ditemukan', null, 404);
    }

    return successResponse(
      res,
      'Detail edukasi berhasil diambil',
      mapContent(document),
    );
  } catch (error) {
    error.message = 'Gagal mengambil detail edukasi';
    return next(error);
  }
};

const createContent = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  const body = req.body || {};
  const validationMessage = validateContent(body);
  if (validationMessage) {
    return errorResponse(res, validationMessage, null, 400);
  }

  try {
    const document = db.collection(COLLECTION_NAME).doc();
    const timestamp = admin.firestore.Timestamp.now();
    const content = {
      content_id: document.id,
      title: body.title.trim(),
      type: body.type.trim(),
      category: body.category.trim(),
      description: body.description.trim(),
      content_url:
        typeof body.content_url === 'string' ? body.content_url.trim() : '',
      module_id:
        typeof body.module_id === 'string' ? body.module_id.trim() : '',
      is_published: body.is_published ?? false,
      created_at: timestamp,
      updated_at: timestamp,
    };

    await document.set(content);
    return successResponse(
      res,
      'Konten edukasi berhasil ditambahkan',
      {
        ...content,
        created_at: serializeTimestamp(timestamp),
        updated_at: serializeTimestamp(timestamp),
      },
      201,
    );
  } catch (error) {
    error.message = 'Gagal menambahkan konten edukasi';
    return next(error);
  }
};

const updateContent = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  const body = req.body || {};
  const validationMessage = validateContent(body, true);
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
      return errorResponse(res, 'Konten edukasi tidak ditemukan', null, 404);
    }

    updates.updated_at = admin.firestore.Timestamp.now();
    await document.update(updates);
    const updatedDocument = await document.get();

    return successResponse(
      res,
      'Konten edukasi berhasil diperbarui',
      mapContent(updatedDocument),
    );
  } catch (error) {
    error.message = 'Gagal memperbarui konten edukasi';
    return next(error);
  }
};

const deleteContent = async (req, res, next) => {
  if (!db) {
    return errorResponse(res, FIRESTORE_CONNECTION_MESSAGE, [], 503);
  }

  try {
    const document = db.collection(COLLECTION_NAME).doc(req.params.id);
    const snapshot = await document.get();

    if (!snapshot.exists) {
      return errorResponse(res, 'Konten edukasi tidak ditemukan', null, 404);
    }

    await document.delete();
    return successResponse(res, 'Konten edukasi berhasil dihapus', {
      content_id: req.params.id,
    });
  } catch (error) {
    error.message = 'Gagal menghapus konten edukasi';
    return next(error);
  }
};

module.exports = {
  createContent,
  deleteContent,
  getContentById,
  getContents,
  updateContent,
};
