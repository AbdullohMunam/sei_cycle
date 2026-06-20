const successResponse = (res, message, data, statusCode = 200) =>
  res.status(statusCode).json({
    success: true,
    message,
    data,
  });

const errorResponse = (res, message, data = null, statusCode = 500) =>
  res.status(statusCode).json({
    success: false,
    message,
    data,
  });

module.exports = { errorResponse, successResponse };
