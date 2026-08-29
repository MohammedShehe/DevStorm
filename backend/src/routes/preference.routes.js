const express = require("express");
const {
  getPreferences,
  updatePreferences,
} = require("../controllers/preference.controller");
const { authenticateUser } = require("../middlewares/auth.middleware");

const router = express.Router();

router.use(authenticateUser);

router.get("/", getPreferences);
router.put("/", updatePreferences);

module.exports = router;