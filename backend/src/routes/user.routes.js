const express = require("express");
const {
  getProfile,
  updateProfile,
  getCaregivers,
  inviteCaregiver,
  getMyPatients,
  getPatientDetail,
} = require("../controllers/user.controller");
const { authenticateUser } = require("../middlewares/auth.middleware");

const router = express.Router();
router.use(authenticateUser);
router.get("/profile", getProfile);
router.put("/profile", updateProfile);
router.get("/caregivers", getCaregivers);
router.post("/caregivers/invite", inviteCaregiver);
router.get("/patients", getMyPatients);
router.get("/patients/:patientId", getPatientDetail);
module.exports = router;
