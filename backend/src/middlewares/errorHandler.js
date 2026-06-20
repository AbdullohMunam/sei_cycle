const { errorResponse } = require('../utils/response');

const notFoundHandler = (req, res) =>
  errorResponse(res, 'Endpoint tidak ditemukan', null, 404);

const errorHandler = (error, req, res, next) => {
  console.error(error);

  if (res.headersSent) {
    return next(error);
  }

  const statusCode = error.statusCode || error.status || 500;

  return errorResponse(
    res,
    error.message || 'Terjadi kesalahan pada server',
    null,
    statusCode,
  );
};

module.exports = { errorHandler, notFoundHandler };
