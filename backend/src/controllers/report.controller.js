const { Op } = require("sequelize");
const DoseLog = require("../models/dose_log.model");
const Medicine = require("../models/medicine.model");
const { successResponse, errorResponse } = require("../utils/response");

// Get weekly adherence (last 7 days)
exports.getWeeklyAdherence = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const now = new Date();
    const days = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);
      const start = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0);
      const end = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59);
      const doses = await DoseLog.findAll({
        where: {
          userId,
          scheduledTime: { [Op.between]: [start, end] },
          status: { [Op.ne]: "upcoming" },
        },
      });
      const total = doses.length;
      const taken = doses.filter(d => d.status === "taken").length;
      const adherence = total > 0 ? taken / total : 0;
      days.push(adherence);
    }

    return successResponse(res, 200, "Weekly adherence fetched.", { weekly: days });
  } catch (error) {
    next(error);
  }
};

// Get monthly adherence (4 weeks)
exports.getMonthlyAdherence = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const now = new Date();
    const weeks = [];
    for (let i = 3; i >= 0; i--) {
      let total = 0;
      let taken = 0;
      for (let j = 0; j < 7; j++) {
        const d = new Date(now);
        d.setDate(d.getDate() - (i * 7 + j));
        const start = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0);
        const end = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59);
        const doses = await DoseLog.findAll({
          where: {
            userId,
            scheduledTime: { [Op.between]: [start, end] },
            status: { [Op.ne]: "upcoming" },
          },
        });
        total += doses.length;
        taken += doses.filter(d => d.status === "taken").length;
      }
      const adherence = total > 0 ? taken / total : 0;
      weeks.push(adherence);
    }

    return successResponse(res, 200, "Monthly adherence fetched.", { monthly: weeks });
  } catch (error) {
    next(error);
  }
};

// Get summary statistics
exports.getSummary = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const now = new Date();

    // Today's adherence
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const end = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
    const todayDoses = await DoseLog.findAll({
      where: {
        userId,
        scheduledTime: { [Op.between]: [start, end] },
        status: { [Op.ne]: "upcoming" },
      },
    });
    const todayTaken = todayDoses.filter(d => d.status === "taken").length;
    const todayTotal = todayDoses.length;
    const todayAdherence = todayTotal > 0 ? todayTaken / todayTotal : 1.0;

    // Current streak (consecutive days with 100% adherence)
    let streak = 0;
    let currentDate = new Date(now);
    while (true) {
      const s = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate(), 0, 0, 0);
      const e = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate(), 23, 59, 59);
      const doses = await DoseLog.findAll({
        where: {
          userId,
          scheduledTime: { [Op.between]: [s, e] },
          status: { [Op.ne]: "upcoming" },
        },
      });
      if (doses.length === 0) break;
      const allTaken = doses.every(d => d.status === "taken");
      if (!allTaken) break;
      streak++;
      currentDate.setDate(currentDate.getDate() - 1);
    }

    // Counts
    const totalMedicines = await Medicine.count({ where: { userId } });
    const missedCount = await DoseLog.count({ where: { userId, status: "missed" } });
    const skippedCount = await DoseLog.count({ where: { userId, status: "skipped" } });
    const takenCount = await DoseLog.count({ where: { userId, status: "taken" } });

    return successResponse(res, 200, "Summary fetched.", {
      summary: {
        currentStreak: streak,
        todayAdherence,
        takenCount,
        missedCount,
        skippedCount,
        totalMedicines,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Export PDF — returns summary JSON suitable for client-side PDF generation
exports.exportPdf = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const doses = await DoseLog.findAll({
      where: { userId },
      order: [["scheduledTime", "DESC"]],
      limit: 200,
    });
    const summary = {
      total: doses.length,
      taken: doses.filter((d) => d.status === "taken").length,
      missed: doses.filter((d) => d.status === "missed").length,
      skipped: doses.filter((d) => d.status === "skipped").length,
      generatedAt: new Date().toISOString(),
    };
    return successResponse(res, 200, "PDF report data ready. Generate PDF on client or connect a PDF library on the server.", {
      format: "pdf-data",
      summary,
      rows: doses,
    });
  } catch (error) {
    next(error);
  }
};

// Export CSV — returns CSV string in response body
exports.exportCsv = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const doses = await DoseLog.findAll({
      where: { userId },
      order: [["scheduledTime", "DESC"]],
      limit: 500,
    });
    const header = "id,medicineName,dosage,scheduledTime,status,actionTime\n";
    const lines = doses.map((d) => {
      const row = [
        d.id,
        `"${(d.medicineName || "").replace(/"/g, '""')}"`,
        `"${(d.dosage || "").replace(/"/g, '""')}"`,
        d.scheduledTime ? new Date(d.scheduledTime).toISOString() : "",
        d.status,
        d.actionTime ? new Date(d.actionTime).toISOString() : "",
      ];
      return row.join(",");
    });
    const csv = header + lines.join("\n");
    return successResponse(res, 200, "CSV report generated.", {
      format: "csv",
      csv,
      rowCount: doses.length,
    });
  } catch (error) {
    next(error);
  }
};