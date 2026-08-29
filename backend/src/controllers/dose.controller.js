const { Op } = require("sequelize");
const DoseLog = require("../models/dose_log.model");
const Medicine = require("../models/medicine.model");
const { successResponse, errorResponse } = require("../utils/response");

/** Calendar day bounds as MySQL-friendly local strings (no TZ shift). */

/** Ensure scheduledTime is returned as local wall-clock string (no Z). */
const formatDose = (dose) => {
  const plain = dose.toJSON ? dose.toJSON() : { ...dose };
  if (plain.scheduledTime) {
    let s = String(plain.scheduledTime);
    s = s.replace("T", " ").replace(/\.\d{3}Z?$/, "").replace(/Z$/, "");
    // If ISO with offset, strip offset
    s = s.replace(/[+-]\d{2}:\d{2}$/, "").trim();
    plain.scheduledTime = s;
  }
  if (plain.actionTime) {
    let s = String(plain.actionTime);
    s = s.replace("T", " ").replace(/\.\d{3}Z?$/, "").replace(/Z$/, "");
    s = s.replace(/[+-]\d{2}:\d{2}$/, "").trim();
    plain.actionTime = s;
  }
  return plain;
};

const formatDoses = (doses) => doses.map(formatDose);

const localDayBounds = (dateInput) => {
  const d = dateInput ? new Date(dateInput) : new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return {
    start: `${y}-${m}-${day} 00:00:00`,
    end: `${y}-${m}-${day} 23:59:59`,
  };
};

/** Mark past "upcoming" doses as missed for this user (called on read endpoints). */
const autoMarkMissed = async (userId) => {
  const now = new Date();
  await DoseLog.update(
    { status: "missed", actionTime: now },
    {
      where: {
        userId,
        status: "upcoming",
        scheduledTime: { [Op.lt]: now },
      },
    }
  );
};

// Get today's doses
exports.getTodayDoses = async (req, res, next) => {
  try {
    const userId = req.user.id;
    await autoMarkMissed(userId);

    const { start, end } = localDayBounds();

    const doses = await DoseLog.findAll({
      where: {
        userId,
        scheduledTime: { [Op.between]: [start, end] },
      },
      order: [["scheduledTime", "ASC"]],
    });

    return successResponse(res, 200, "Today's doses fetched.", { doses: formatDoses(doses) });
  } catch (error) {
    next(error);
  }
};

// Get upcoming doses
exports.getUpcomingDoses = async (req, res, next) => {
  try {
    const userId = req.user.id;
    await autoMarkMissed(userId);

    const now = new Date();

    const doses = await DoseLog.findAll({
      where: {
        userId,
        status: "upcoming",
        scheduledTime: { [Op.gt]: now },
      },
      order: [["scheduledTime", "ASC"]],
      limit: 20,
    });

    return successResponse(res, 200, "Upcoming doses fetched.", { doses: formatDoses(doses) });
  } catch (error) {
    next(error);
  }
};

// Get doses for a specific day
exports.getDosesByDay = async (req, res, next) => {
  try {
    const userId = req.user.id;
    await autoMarkMissed(userId);

    const { date } = req.params;
    if (!/^\d{4}-\d{2}-\d{2}$/.test(String(date))) {
      return errorResponse(res, 400, "Invalid date. Use YYYY-MM-DD.");
    }
    const start = `${date} 00:00:00`;
    const end = `${date} 23:59:59`;

    const doses = await DoseLog.findAll({
      where: {
        userId,
        scheduledTime: { [Op.between]: [start, end] },
      },
      order: [["scheduledTime", "ASC"]],
    });

    return successResponse(res, 200, "Doses for day fetched.", { doses: formatDoses(doses) });
  } catch (error) {
    next(error);
  }
};

// Get single dose
exports.getDoseById = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const dose = await DoseLog.findOne({ where: { id, userId } });
    if (!dose) {
      return errorResponse(res, 404, "Dose not found.");
    }

    return successResponse(res, 200, "Dose details fetched.", { dose: formatDose(dose) });
  } catch (error) {
    next(error);
  }
};

// Mark dose as taken — also decrement medicine stock
exports.markTaken = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const dose = await DoseLog.findOne({ where: { id, userId } });
    if (!dose) {
      return errorResponse(res, 404, "Dose not found.");
    }

    if (dose.status !== "upcoming") {
      return errorResponse(res, 400, "This dose has already been acted upon.");
    }

    await dose.update({
      status: "taken",
      actionTime: new Date(),
    });

    // Decrement stock when a dose is taken
    if (dose.medicineId) {
      const medicine = await Medicine.findOne({
        where: { id: dose.medicineId, userId },
      });
      if (medicine && medicine.stockCount > 0) {
        await medicine.update({
          stockCount: medicine.stockCount - 1,
        });
      }
    }

    return successResponse(res, 200, "Dose marked as taken.", { dose: formatDose(dose) });
  } catch (error) {
    next(error);
  }
};

// Mark dose as skipped
exports.markSkipped = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const dose = await DoseLog.findOne({ where: { id, userId } });
    if (!dose) {
      return errorResponse(res, 404, "Dose not found.");
    }

    if (dose.status !== "upcoming") {
      return errorResponse(res, 400, "This dose has already been acted upon.");
    }

    await dose.update({
      status: "skipped",
      actionTime: new Date(),
    });

    return successResponse(res, 200, "Dose marked as skipped.", { dose: formatDose(dose) });
  } catch (error) {
    next(error);
  }
};

// Mark dose as missed (manual)
exports.markMissed = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const dose = await DoseLog.findOne({ where: { id, userId } });
    if (!dose) {
      return errorResponse(res, 404, "Dose not found.");
    }

    if (dose.status !== "upcoming") {
      return errorResponse(res, 400, "This dose has already been acted upon.");
    }

    await dose.update({
      status: "missed",
      actionTime: new Date(),
    });

    return successResponse(res, 200, "Dose marked as missed.", { dose: formatDose(dose) });
  } catch (error) {
    next(error);
  }
};

// Get status summary for today
exports.getStatusSummary = async (req, res, next) => {
  try {
    const userId = req.user.id;
    await autoMarkMissed(userId);

    const { start, end } = localDayBounds();

    const doses = await DoseLog.findAll({
      where: {
        userId,
        scheduledTime: { [Op.between]: [start, end] },
      },
    });

    const taken = doses.filter((d) => d.status === "taken").length;
    const missed = doses.filter((d) => d.status === "missed").length;
    const skipped = doses.filter((d) => d.status === "skipped").length;
    const upcoming = doses.filter((d) => d.status === "upcoming").length;
    const total = doses.length;

    return successResponse(res, 200, "Summary fetched.", {
      summary: {
        taken,
        missed,
        skipped,
        upcoming,
        total,
        adherence: total > 0 ? taken / total : 1.0,
      },
    });
  } catch (error) {
    next(error);
  }
};
