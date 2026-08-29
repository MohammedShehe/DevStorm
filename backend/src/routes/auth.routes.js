const express = require("express");
const {
  registerUser,
  loginUser,
  forgotPassword,
  verifyOtp,
  resendOtp,
  resetPassword,
  logout,
  refreshToken,
} = require("../controllers/auth.controller");
const { authenticateUser } = require("../middlewares/auth.middleware");

const router = express.Router();

router.post("/register", registerUser);
router.post("/login", loginUser);
router.post("/forgot-password", forgotPassword);
router.post("/verify-otp", verifyOtp);
router.post("/resend-otp", resendOtp);
router.post("/reset-password", resetPassword);
router.post("/logout", authenticateUser, logout);
router.post("/refresh-token", authenticateUser, refreshToken);

module.exports = router;