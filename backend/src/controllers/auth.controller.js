// src/controllers/auth.controller.js
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const { Op } = require("sequelize"); // Add this line

const User = require("../models/user.model");
const Otp = require("../models/otp.model");
const Caregiver = require("../models/caregiver.model");

const {
  validateRegistration,
  validateLogin,
  validateForgotPassword,
  validateOtpVerification,
  validateResetPassword
} = require("../validators/auth.validator");

const {
  sendWelcomeEmail,
  sendOtpEmail,
  sendPasswordResetConfirmationEmail
} = require("../services/email.service");

const {
  successResponse,
  errorResponse
} = require("../utils/response");

const registerUser = async (req, res, next) => {
  try {
    const {
      fullName,
      email,
      phoneNumber,
      dateOfBirth,
      gender,
      password,
      confirmPassword,
      role
    } = req.body;

    // 1. Validate request
    const validationErrors = validateRegistration(req.body);

    if (validationErrors.length > 0) {
      return errorResponse(
        res,
        400,
        "Validation failed.",
        validationErrors
      );
    }

    // 2. Normalize data
    const normalizedEmail = email.trim().toLowerCase();
    const normalizedPhone = phoneNumber.trim();

    // 3. Check existing email
    const existingEmail = await User.findOne({
      where: { email: normalizedEmail }
    });

    if (existingEmail) {
      return errorResponse(
        res,
        409,
        "An account with this email already exists."
      );
    }

    // 4. Check existing phone
    const existingPhone = await User.findOne({
      where: { phoneNumber: normalizedPhone }
    });

    if (existingPhone) {
      return errorResponse(
        res,
        409,
        "An account with this phone number already exists."
      );
    }

    // 5. Hash password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // 6. Create user
    const userRole = (role === "caregiver") ? "caregiver" : "patient";
    const user = await User.create({
      fullName: fullName.trim(),
      email: normalizedEmail,
      phoneNumber: normalizedPhone,
      dateOfBirth,
      gender,
      password: hashedPassword,
      role: userRole
    });

    // 7. Send welcome email
    try {
      await sendWelcomeEmail(user);
    } catch (emailError) {
      console.error("Welcome email could not be sent:", emailError.message);
    }

    // 8. Return response
    return successResponse(
      res,
      201,
      "Registration successful. Welcome to MediTrack!",
      {
        user: {
          id: user.id,
          fullName: user.fullName,
          email: user.email,
          phoneNumber: user.phoneNumber,
          dateOfBirth: user.dateOfBirth,
          gender: user.gender,
          role: user.role,
          createdAt: user.createdAt
        }
      }
    );
  } catch (error) {
    next(error);
  }
};

const loginUser = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // 1. Validate request
    const validationErrors = validateLogin(req.body);

    if (validationErrors.length > 0) {
      return errorResponse(
        res,
        400,
        "Validation failed.",
        validationErrors
      );
    }

    // 2. Normalize email
    const normalizedEmail = email.trim().toLowerCase();

    // 3. Find user
    const user = await User.findOne({
      where: { email: normalizedEmail }
    });

    if (!user) {
      return errorResponse(
        res,
        401,
        "Invalid email or password."
      );
    }

    // 4. Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return errorResponse(
        res,
        401,
        "Invalid email or password."
      );
    }

    // 5. Generate JWT token
    const token = jwt.sign(
      { 
        id: user.id, 
        email: user.email,
        fullName: user.fullName 
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || "7d" }
    );

    // 6. Return response
    return successResponse(
      res,
      200,
      "Login successful.",
      {
        token,
        user: {
          id: user.id,
          fullName: user.fullName,
          email: user.email,
          phoneNumber: user.phoneNumber,
          dateOfBirth: user.dateOfBirth,
          gender: user.gender,
          role: user.role
        }
      }
    );
  } catch (error) {
    next(error);
  }
};

const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;

    // 1. Validate request
    const validationErrors = validateForgotPassword(req.body);

    if (validationErrors.length > 0) {
      return errorResponse(
        res,
        400,
        "Validation failed.",
        validationErrors
      );
    }

    // 2. Normalize email
    const normalizedEmail = email.trim().toLowerCase();

    // 3. Check if user exists
    const user = await User.findOne({
      where: { email: normalizedEmail }
    });

    if (!user) {
      return errorResponse(
        res,
        404,
        "No account found with this email address."
      );
    }

    // 4. Generate OTP
    const otpCode = crypto.randomInt(100000, 999999).toString();
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 10);

    // 5. Save OTP
    await Otp.create({
      email: normalizedEmail,
      otp: otpCode,
      expiresAt: expiresAt,
      isUsed: false
    });

    // 6. Send OTP email
    try {
      await sendOtpEmail(user, otpCode);
    } catch (emailError) {
      console.error("OTP email could not be sent:", emailError.message);
      return errorResponse(
        res,
        500,
        "Could not send OTP email. Please try again."
      );
    }

    // 7. Return response
    return successResponse(
      res,
      200,
      "OTP sent successfully to your email.",
      {
        email: normalizedEmail
      }
    );
  } catch (error) {
    next(error);
  }
};

const verifyOtp = async (req, res, next) => {
  try {
    const { email, otp } = req.body;

    // 1. Validate request
    const validationErrors = validateOtpVerification(req.body);

    if (validationErrors.length > 0) {
      return errorResponse(
        res,
        400,
        "Validation failed.",
        validationErrors
      );
    }

    // 2. Normalize email
    const normalizedEmail = email.trim().toLowerCase();

    // 3. Find OTP
    const otpRecord = await Otp.findOne({
      where: {
        email: normalizedEmail,
        otp: otp,
        isUsed: false,
        expiresAt: {
          [Op.gt]: new Date()
        }
      },
      order: [['createdAt', 'DESC']]
    });

    if (!otpRecord) {
      return errorResponse(
        res,
        400,
        "Invalid or expired OTP. Please request a new one."
      );
    }

    // 4. Mark OTP as used
    await otpRecord.update({ isUsed: true });

    // 5. Generate temporary token for password reset
    const resetToken = jwt.sign(
      { email: normalizedEmail },
      process.env.JWT_SECRET,
      { expiresIn: "10m" }
    );

    // 6. Return response
    return successResponse(
      res,
      200,
      "OTP verified successfully.",
      {
        resetToken
      }
    );
  } catch (error) {
    next(error);
  }
};

const resendOtp = async (req, res, next) => {
  try {
    const { email } = req.body;

    // 1. Normalize email
    const normalizedEmail = email.trim().toLowerCase();

    // 2. Check if user exists
    const user = await User.findOne({
      where: { email: normalizedEmail }
    });

    if (!user) {
      return errorResponse(
        res,
        404,
        "No account found with this email address."
      );
    }

    // 3. Check if there's a recent OTP (within 1 minute)
    const recentOtp = await Otp.findOne({
      where: {
        email: normalizedEmail,
        createdAt: {
          [Op.gt]: new Date(Date.now() - 60000) // 1 minute
        }
      }
    });

    if (recentOtp) {
      return errorResponse(
        res,
        429,
        "Please wait 1 minute before requesting a new OTP."
      );
    }

    // 4. Generate new OTP
    const otpCode = crypto.randomInt(100000, 999999).toString();
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 10);

    // 5. Save OTP
    await Otp.create({
      email: normalizedEmail,
      otp: otpCode,
      expiresAt: expiresAt,
      isUsed: false
    });

    // 6. Send OTP email
    try {
      await sendOtpEmail(user, otpCode);
    } catch (emailError) {
      console.error("OTP email could not be sent:", emailError.message);
      return errorResponse(
        res,
        500,
        "Could not send OTP email. Please try again."
      );
    }

    // 7. Return response
    return successResponse(
      res,
      200,
      "New OTP sent successfully."
    );
  } catch (error) {
    next(error);
  }
};

const resetPassword = async (req, res, next) => {
  try {
    const { resetToken, newPassword, confirmPassword } = req.body;

    // 1. Validate request
    const validationErrors = validateResetPassword(req.body);

    if (validationErrors.length > 0) {
      return errorResponse(
        res,
        400,
        "Validation failed.",
        validationErrors
      );
    }

    // 2. Verify reset token
    let decodedToken;
    try {
      decodedToken = jwt.verify(resetToken, process.env.JWT_SECRET);
    } catch (error) {
      return errorResponse(
        res,
        401,
        "Invalid or expired reset token. Please request a new OTP."
      );
    }

    // 3. Find user
    const user = await User.findOne({
      where: { email: decodedToken.email }
    });

    if (!user) {
      return errorResponse(
        res,
        404,
        "User not found."
      );
    }

    // 4. Hash new password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

    // 5. Update password
    await user.update({ password: hashedPassword });

    // 6. Send confirmation email
    try {
      await sendPasswordResetConfirmationEmail(user);
    } catch (emailError) {
      console.error("Reset confirmation email could not be sent:", emailError.message);
    }

    // 7. Return response
    return successResponse(
      res,
      200,
      "Password reset successfully. You can now login with your new password."
    );
  } catch (error) {
    next(error);
  }
};

// Logout (client-side token discard, but we can blacklist if needed)
const logout = async (req, res, next) => {
  try {
    // In a stateless JWT system, logout is handled client-side.
    // Optionally implement token blacklist with Redis.
    return successResponse(res, 200, "Logged out successfully.");
  } catch (error) {
    next(error);
  }
};

// Refresh token (optional)
const refreshToken = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const user = await User.findByPk(userId);
    if (!user) {
      return errorResponse(res, 404, "User not found.");
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, fullName: user.fullName },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || "7d" }
    );

    return successResponse(res, 200, "Token refreshed.", { token });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  registerUser,
  loginUser,
  forgotPassword,
  verifyOtp,
  resendOtp,
  resetPassword,
  logout,
  refreshToken
};