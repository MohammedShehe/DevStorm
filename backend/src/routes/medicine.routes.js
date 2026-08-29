const express = require("express");
const {
  addMedicine,
  getMedicines,
  getLowStockMedicines,
  getMedicineById,
  updateMedicine,
  deleteMedicine,
  suggestMedicines,
  getMedicineInfo,
} = require("../controllers/medicine.controller");
const { authenticateUser } = require("../middlewares/auth.middleware");

const router = express.Router();

router.use(authenticateUser);

router.post("/", addMedicine);
router.get("/", getMedicines);
router.get("/low-stock", getLowStockMedicines);
router.get("/suggest", suggestMedicines);
router.get("/info", getMedicineInfo);
router.post("/info", getMedicineInfo);
router.get("/:id", getMedicineById);
router.put("/:id", updateMedicine);
router.delete("/:id", deleteMedicine);

module.exports = router;
