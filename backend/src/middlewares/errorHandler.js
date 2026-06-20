const { errorResponse } = require('../utils/response');

const notFoundHandler = (req, res) =>
  errorResponse(res, 'Endpoint tidak ditemukan', null, 404);

const errorHandler = (error, req, res, next) => {
  console.error(error);

  if (res.headersSent) {
    return next(error);
  }

  return errorResponse(
    res,
    error.message || 'Terjadi kesalahan pada server',
    null,
    error.statusCode || 500,
  );
};

module.exports = { errorHandler, notFoundHandler };
