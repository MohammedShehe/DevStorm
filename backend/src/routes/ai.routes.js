const express = require("express");
const { chat, getTemplates, status } = require("../controllers/ai.controller");
const { authenticateUser } = require("../middlewares/auth.middleware");

const router = express.Router();
router.use(authenticateUser);
router.get("/templates", getTemplates);
router.get("/status", status);
router.post("/chat", chat);

module.exports = router;
