const express = require("express");
const {
  getSettings,
  updateSettings,
} = require("../controllers/notification.controller");
const { authenticateUser } = require("../middlewares/auth.middleware");

const router = express.Router();

router.use(authenticateUser);

router.get("/settings", getSettings);
router.put("/settings", updateSettings);

module.exports = router;