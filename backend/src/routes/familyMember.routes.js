const express = require("express");
const {
  getFamilyMembers,
  addFamilyMember,
  updateFamilyMember,
  deleteFamilyMember,
} = require("../controllers/familyMember.controller");
const { authenticateUser } = require("../middlewares/auth.middleware");

const router = express.Router();

router.use(authenticateUser);

router.get("/", getFamilyMembers);
router.post("/", addFamilyMember);
router.put("/:id", updateFamilyMember);
router.delete("/:id", deleteFamilyMember);

module.exports = router;