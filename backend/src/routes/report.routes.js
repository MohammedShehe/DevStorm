const express = require("express");
const {
  getWeeklyAdherence,
  getMonthlyAdherence,
  getSummary,
  exportPdf,
  exportCsv,
} = require("../controllers/report.controller");
const { authenticateUser } = require("../middlewares/auth.middleware");

const router = express.Router();

router.use(authenticateUser);

router.get("/adherence/weekly", getWeeklyAdherence);
router.get("/adherence/monthly", getMonthlyAdherence);
router.get("/adherence/summary", getSummary);
router.get("/export/pdf", exportPdf);
router.get("/export/csv", exportCsv);

module.exports = router;