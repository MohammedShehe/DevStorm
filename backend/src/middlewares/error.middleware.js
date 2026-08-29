// src/middlewares/error.middleware.js
const { errorResponse } = require("../utils/response");

const errorMiddleware = (error, req, res, next) => {
  console.error(error);

  // Sequelize validation error
  if (error.name === "SequelizeValidationError") {
    const errors = error.errors.map((item) => item.message);
    return errorResponse(
      res,
      400,
      "Database validation failed.",
      errors
    );
  }

  // Duplicate unique field
  if (error.name === "SequelizeUniqueConstraintError") {
    return errorResponse(
      res,
      409,
      "A user with this information already exists."
    );
  }

  // JWT errors
  if (error.name === "JsonWebTokenError") {
    return errorResponse(
      res,
      401,
      "Invalid token. Please login again."
    );
  }

  if (error.name === "TokenExpiredError") {
    return errorResponse(
      res,
      401,
      "Token expired. Please login again."
    );
  }

  return errorResponse(
    res,
    500,
    "Internal server error."
  );
};

module.exports = errorMiddleware;