const { Op } = require("sequelize");
const Medicine = require("../models/medicine.model");
const DoseLog = require("../models/dose_log.model");
const { successResponse, errorResponse } = require("../utils/response");
const medicineLookup = require("../services/medicineLookup.service");

// Helper: generate dose logs for a medicine
const generateDoseLogs = async (medicine, userId) => {
  const logs = [];
  const pad = (n) => String(n).padStart(2, "0");

  // Parse start date as calendar date (no timezone)
  const startRaw = String(medicine.startDate).split("T")[0];
  const [sy, sm, sd] = startRaw.split("-").map(Number);
  let y = sy, m = sm, d = sd;

  let endY, endM, endD;
  if (medicine.endDate) {
    const endRaw = String(medicine.endDate).split("T")[0];
    [endY, endM, endD] = endRaw.split("-").map(Number);
  } else {
    // Cap at 30 days from start
    const endDate = new Date(Date.UTC(sy, sm - 1, sd + 30));
    endY = endDate.getUTCFullYear();
    endM = endDate.getUTCMonth() + 1;
    endD = endDate.getUTCDate();
  }

  const times = Array.isArray(medicine.times) ? medicine.times : [];
  const dayCountLimit = 31;
  let days = 0;

  const isBeforeOrSameEnd = () => {
    if (y < endY) return true;
    if (y > endY) return false;
    if (m < endM) return true;
    if (m > endM) return false;
    return d <= endD;
  };

  while (isBeforeOrSameEnd() && days < dayCountLimit) {
    for (const time of times) {
      const hour = typeof time.hour === "number" ? time.hour : parseInt(time.hour, 10) || 0;
      const minute = typeof time.minute === "number" ? time.minute : parseInt(time.minute, 10) || 0;
      // Store as plain local datetime string — avoids UTC conversion on serialize
      const scheduledTime = `${y}-${pad(m)}-${pad(d)} ${pad(hour)}:${pad(minute)}:00`;
      logs.push({
        userId,
        medicineId: medicine.id,
        medicineName: medicine.name,
        dosage: medicine.dosage,
        scheduledTime,
        status: "upcoming",
        color: medicine.color || "#0EA5A0",
      });
    }
    // next calendar day
    const next = new Date(Date.UTC(y, m - 1, d + 1));
    y = next.getUTCFullYear();
    m = next.getUTCMonth() + 1;
    d = next.getUTCDate();
    days++;
  }

  if (logs.length > 0) {
    const chunkSize = 500;
    for (let i = 0; i < logs.length; i += chunkSize) {
      await DoseLog.bulkCreate(logs.slice(i, i + chunkSize));
    }
  }
};

// Add medicine
exports.addMedicine = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { name, dosage, form, frequency, times, startDate, endDate, instructions, color, stockCount, lowStockThreshold } = req.body;

    // Basic validation
    if (!name || !dosage || !form || !frequency || !times || !startDate) {
      return errorResponse(res, 400, "Missing required fields: name, dosage, form, frequency, times, startDate");
    }

    const medicine = await Medicine.create({
      userId,
      name,
      dosage,
      form,
      frequency,
      times,
      startDate,
      endDate: endDate || null,
      instructions: instructions || "",
      color: color || "#0EA5A0",
      stockCount: stockCount || 30,
      lowStockThreshold: lowStockThreshold || 5,
    });

    // Generate dose logs
    await generateDoseLogs(medicine, userId);

    return successResponse(res, 201, "Medicine added successfully.", { medicine });
  } catch (error) {
    next(error);
  }
};

// Get all medicines (with search)
exports.getMedicines = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { search } = req.query;

    const where = { userId };
    if (search) {
      where.name = { [Op.like]: `%${search}%` };
    }

    const medicines = await Medicine.findAll({
      where,
      order: [["name", "ASC"]],
    });

    return successResponse(res, 200, "Medicines fetched successfully.", { medicines });
  } catch (error) {
    next(error);
  }
};

// Get low stock medicines
exports.getLowStockMedicines = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const medicines = await Medicine.findAll({
      where: {
        userId,
        [Op.and]: [
          { stockCount: { [Op.lte]: sequelize.col("lowStockThreshold") } },
        ],
      },
      order: [["stockCount", "ASC"]],
    });

    return successResponse(res, 200, "Low stock medicines fetched.", { medicines });
  } catch (error) {
    next(error);
  }
};

// Get medicine by ID
exports.getMedicineById = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const medicine = await Medicine.findOne({
      where: { id, userId },
    });

    if (!medicine) {
      return errorResponse(res, 404, "Medicine not found.");
    }

    return successResponse(res, 200, "Medicine details fetched.", { medicine });
  } catch (error) {
    next(error);
  }
};

// Update medicine
exports.updateMedicine = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { name, dosage, form, frequency, times, startDate, endDate, instructions, color, stockCount, lowStockThreshold } = req.body;

    const medicine = await Medicine.findOne({ where: { id, userId } });
    if (!medicine) {
      return errorResponse(res, 404, "Medicine not found.");
    }

    await medicine.update({
      name: name || medicine.name,
      dosage: dosage || medicine.dosage,
      form: form || medicine.form,
      frequency: frequency || medicine.frequency,
      times: times || medicine.times,
      startDate: startDate || medicine.startDate,
      endDate: endDate !== undefined ? endDate : medicine.endDate,
      instructions: instructions !== undefined ? instructions : medicine.instructions,
      color: color || medicine.color,
      stockCount: stockCount !== undefined ? stockCount : medicine.stockCount,
      lowStockThreshold: lowStockThreshold !== undefined ? lowStockThreshold : medicine.lowStockThreshold,
    });

    // Regenerate dose logs if times or dates changed
    if (times || startDate || endDate !== undefined) {
      await DoseLog.destroy({ where: { medicineId: medicine.id, userId } });
      await generateDoseLogs(medicine, userId);
    }

    return successResponse(res, 200, "Medicine updated successfully.", { medicine });
  } catch (error) {
    next(error);
  }
};

// Delete medicine
exports.deleteMedicine = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const medicine = await Medicine.findOne({ where: { id, userId } });
    if (!medicine) {
      return errorResponse(res, 404, "Medicine not found.");
    }

    await DoseLog.destroy({ where: { medicineId: id, userId } });
    await medicine.destroy();

    return successResponse(res, 200, "Medicine deleted successfully.");
  } catch (error) {
    next(error);
  }
};

// Mock: Scan barcode

exports.suggestMedicines = async (req, res, next) => {
  try {
    const q = (req.query.q || req.query.query || "").toString().trim();
    if (q.length < 1) {
      return successResponse(res, 200, "Suggestions", { suggestions: [] });
    }
    const suggestions = await medicineLookup.suggestMedicines(q);
    return successResponse(res, 200, "Medicine suggestions", { suggestions });
  } catch (error) {
    next(error);
  }
};

exports.getMedicineInfo = async (req, res, next) => {
  try {
    const name = (req.query.name || req.body?.name || "").toString().trim();
    if (!name) {
      return errorResponse(res, 400, "Medicine name is required.");
    }
    const info = await medicineLookup.getMedicineInfo(name);
    return successResponse(res, 200, "Medicine information loaded.", { info });
  } catch (error) {
    next(error);
  }
};
