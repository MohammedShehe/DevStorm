const express = require("express");
const {
  getNotes,
  addNote,
  deleteNote,
} = require("../controllers/caregiverNote.controller");
const { authenticateUser } = require("../middlewares/auth.middleware");

const router = express.Router();

router.use(authenticateUser);

router.get("/notes", getNotes);
router.post("/notes", addNote);
router.delete("/notes/:id", deleteNote);

module.exports = router;