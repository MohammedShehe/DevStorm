const express = require("express");
const { getMessages, sendMessage, getConversations } = require("../controllers/chat.controller");
const { authenticateUser } = require("../middlewares/auth.middleware");

const router = express.Router();
router.use(authenticateUser);
router.get("/conversations", getConversations);
router.get("/:userId", getMessages);
router.post("/", sendMessage);
module.exports = router;
