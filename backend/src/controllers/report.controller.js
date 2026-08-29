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

// Export PDF — returns a real application/pdf document.
exports.exportPdf = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const User = require("../models/user.model");
    const user = await User.findByPk(userId, { attributes: { exclude: ["password"] } });
    if (!user) return errorResponse(res, 404, "Patient not found.");

    const medicines = await Medicine.findAll({
      where: { userId },
      order: [["startDate", "DESC"], ["createdAt", "DESC"]],
    });
    const doses = await DoseLog.findAll({
      where: { userId },
      order: [["scheduledTime", "DESC"]],
      limit: 500,
    });

    const age = user.dateOfBirth ? (() => {
      const dob = new Date(user.dateOfBirth);
      const now = new Date();
      let value = now.getFullYear() - dob.getFullYear();
      if (now.getMonth() < dob.getMonth() || (now.getMonth() === dob.getMonth() && now.getDate() < dob.getDate())) value--;
      return value;
    })() : null;

    const lines = [
      "MEDITrack - PATIENT MEDICINE HISTORY",
      "=====================================",
      `Patient: ${user.fullName || ""}`,
      `Email: ${user.email || ""}`,
      `Date of birth: ${user.dateOfBirth ? new Date(user.dateOfBirth).toLocaleDateString() : "N/A"}`,
      `Age: ${age ?? "N/A"}`,
      `Gender: ${user.gender || "N/A"}`,
      `Generated: ${new Date().toLocaleString()}`,
      "",
      `Totals: ${doses.length} doses | Taken: ${doses.filter(d => d.status === "taken").length} | Missed: ${doses.filter(d => d.status === "missed").length} | Skipped: ${doses.filter(d => d.status === "skipped").length}`,
      "",
      "CURRENT MEDICINES (NEWEST FIRST)",
      "--------------------------------",
    ];

    for (const med of medicines) {
      const medDoses = doses.filter(d => String(d.medicineId) === String(med.id) || d.medicineName === med.name);
      const taken = medDoses.filter(d => d.status === "taken").length;
      const missed = medDoses.filter(d => d.status === "missed").length;
      const total = medDoses.length;
      const adherence = total ? Math.round((taken / total) * 100) : null;
      const start = med.startDate || med.createdAt;
      const end = med.endDate;
      lines.push(`${med.name || "Medicine"} | ${med.dosage || ""} | ${med.frequency || ""}`);
      lines.push(`  Start: ${start ? new Date(start).toLocaleDateString() : "N/A"}${end ? ` | End: ${new Date(end).toLocaleDateString()}` : ""}`);
      lines.push(`  Adherence: ${adherence == null ? "N/A" : adherence + "%"} | Taken: ${taken} | Missed: ${missed}`);
      if (med.instructions || med.notes) lines.push(`  Instructions: ${med.instructions || med.notes}`);
      lines.push("");
    }

    lines.push("DOSE HISTORY (NEWEST FIRST)");
    lines.push("---------------------------");
    for (const dose of doses) {
      const when = dose.scheduledTime ? new Date(dose.scheduledTime).toLocaleString() : "Unknown date";
      lines.push(`${when} | ${dose.medicineName || "Medicine"} | ${dose.dosage || ""} | ${(dose.status || "").toUpperCase()}`);
    }

    const pdf = buildSimplePdf(lines);
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", `attachment; filename="meditrack_medicine_history_${Date.now()}.pdf"`);
    res.setHeader("Content-Length", pdf.length);
    return res.status(200).send(pdf);
  } catch (error) {
    next(error);
  }
};

function pdfEscape(text) {
  return String(text ?? "").replace(/\\/g, "\\\\").replace(/\(/g, "\\(").replace(/\)/g, "\\)");
}

function buildSimplePdf(lines) {
  const pageWidth = 595;
  const pageHeight = 842;
  const margin = 42;
  const fontSize = 9;
  const lineHeight = 13;
  const linesPerPage = 56;
  const pages = [];
  for (let i = 0; i < lines.length; i += linesPerPage) pages.push(lines.slice(i, i + linesPerPage));
  if (!pages.length) pages.push([""]);

  const objects = [];
  const add = body => { objects.push(body); return objects.length; };
  const catalogId = add("");
  const pagesId = add("");
  const fontId = add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>");
  const pageIds = [];
  const contentIds = [];

  pages.forEach(pageLines => {
    const commands = ["BT", `/F1 ${fontSize} Tf`, `${margin} ${pageHeight - margin - fontSize} Td`];
    pageLines.forEach((line, index) => {
      if (index > 0) commands.push(`0 -${lineHeight} Td`);
      commands.push(`(${pdfEscape(line).slice(0, 180)}) Tj`);
    });
    commands.push("ET");
    const content = commands.join("\n");
    const contentId = add(`<< /Length ${Buffer.byteLength(content, "utf8")} >>\nstream\n${content}\nendstream`);
    const pageId = add(`<< /Type /Page /Parent ${pagesId} 0 R /MediaBox [0 0 ${pageWidth} ${pageHeight}] /Resources << /Font << /F1 ${fontId} 0 R >> >> /Contents ${contentId} 0 R >>`);
    contentIds.push(contentId);
    pageIds.push(pageId);
  });

  objects[catalogId - 1] = `<< /Type /Catalog /Pages ${pagesId} 0 R >>`;
  objects[pagesId - 1] = `<< /Type /Pages /Kids [${pageIds.map(id => `${id} 0 R`).join(" ")}] /Count ${pageIds.length} >>`;

  let pdf = "%PDF-1.4\n%\xE2\xE3\xCF\xD3\n";
  const offsets = [0];
  objects.forEach((obj, idx) => {
    offsets.push(Buffer.byteLength(pdf, "binary"));
    pdf += `${idx + 1} 0 obj\n${obj}\nendobj\n`;
  });
  const xref = Buffer.byteLength(pdf, "binary");
  pdf += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
  for (let i = 1; i < offsets.length; i++) pdf += `${String(offsets[i]).padStart(10, "0")} 00000 n \n`;
  pdf += `trailer\n<< /Size ${objects.length + 1} /Root ${catalogId} 0 R >>\nstartxref\n${xref}\n%%EOF`;
  return Buffer.from(pdf, "binary");
}


// Export CSV
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