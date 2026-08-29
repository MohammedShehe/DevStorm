const express = require("express");
const {
  getTodayDoses,
  getUpcomingDoses,
  getDosesByDay,
  getDoseById,
  markTaken,
  markSkipped,
  markMissed,
  getStatusSummary,
} = require("../controllers/dose.controller");
const { authenticateUser } = require("../middlewares/auth.middleware");

const router = express.Router();

router.use(authenticateUser);

router.get("/today", getTodayDoses);
router.get("/upcoming", getUpcomingDoses);
router.get("/day/:date", getDosesByDay);
router.get("/status-summary", getStatusSummary);
router.get("/:id", getDoseById);
router.put("/:id/taken", markTaken);
router.put("/:id/skipped", markSkipped);
router.put("/:id/missed", markMissed);

module.exports = router;