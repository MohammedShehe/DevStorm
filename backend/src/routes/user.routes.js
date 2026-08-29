// src/routes/user.routes.js
const express = require("express");
const {
  getProfile,
  updateProfile,
  getCaregivers,
  inviteCaregiver
} = require("../controllers/user.controller");
const { authenticateUser } = require("../middlewares/auth.middleware");

const router = express.Router();

// All routes require authentication
router.use(authenticateUser);

router.get("/profile", getProfile);
router.put("/profile", updateProfile);
router.get("/caregivers", getCaregivers);
router.post("/caregivers/invite", inviteCaregiver);

module.exports = router;