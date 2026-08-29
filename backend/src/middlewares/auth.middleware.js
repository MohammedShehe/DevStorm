// src/middlewares/auth.middleware.js
const jwt = require("jsonwebtoken");
const { errorResponse } = require("../utils/response");
const User = require("../models/user.model");

const authenticateUser = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return errorResponse(
        res,
        401,
        "Authentication required. Please provide a valid token."
      );
    }

    const token = authHeader.split(" ")[1];

    // Verify token
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      return errorResponse(
        res,
        401,
        "Invalid or expired token. Please login again."
      );
    }

    // Find user
    const user = await User.findByPk(decoded.id, {
      attributes: { exclude: ['password'] }
    });

    if (!user) {
      return errorResponse(
        res,
        401,
        "User not found. Please login again."
      );
    }

    // Attach user to request
    req.user = user;

    next();
  } catch (error) {
    next(error);
  }
};

module.exports = {
  authenticateUser
};