const CaregiverNote = require("../models/caregiver_note.model");
const Caregiver = require("../models/caregiver.model");
const { successResponse, errorResponse } = require("../utils/response");

exports.getNotes = async (req, res, next) => {
  try {
    const userId = req.user.id;

    let notes;
    try {
      notes = await CaregiverNote.findAll({
        where: { userId },
        include: [
          {
            model: Caregiver,
            as: "caregiver",
            attributes: ["id", "caregiverName", "email"],
            required: false,
          },
        ],
        order: [["createdAt", "DESC"]],
      });
    } catch (assocErr) {
      // Fallback without include if association fails
      console.warn("caregiver notes include failed:", assocErr.message);
      notes = await CaregiverNote.findAll({
        where: { userId },
        order: [["createdAt", "DESC"]],
      });
    }

    const mapped = notes.map((n) => {
      const plain = n.toJSON ? n.toJSON() : n;
      const caregiverName =
        plain.caregiver?.caregiverName ||
        plain.caregiverName ||
        "Caregiver";
      return {
        id: plain.id,
        note: plain.note,
        createdAt: plain.createdAt,
        caregiverName,
        caregiverEmail: plain.caregiver?.email || null,
      };
    });

    return successResponse(res, 200, "Caregiver notes fetched.", { notes: mapped });
  } catch (error) {
    console.error("getNotes error:", error);
    next(error);
  }
};

exports.addNote = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { note, caregiverId } = req.body;

    if (!note || !note.trim()) {
      return errorResponse(res, 400, "Note content is required.");
    }

    // Prefer provided caregiver, else any caregiver for this user, else create orphan note if model allows
    let caregiver = null;
    if (caregiverId) {
      caregiver = await Caregiver.findOne({ where: { id: caregiverId, userId } });
    }
    if (!caregiver) {
      caregiver = await Caregiver.findOne({
        where: { userId },
        order: [["createdAt", "DESC"]],
      });
    }

    // If still no caregiver, allow note with caregiverId null only if column allows — else create a placeholder system caregiver
    let cgId = caregiver?.id;
    if (!cgId) {
      caregiver = await Caregiver.create({
        userId,
        caregiverName: "Self / System",
        email: req.user.email || `user${userId}@meditrack.local`,
        status: "Accepted",
      });
      cgId = caregiver.id;
    }

    const newNote = await CaregiverNote.create({
      caregiverId: cgId,
      userId,
      note: note.trim(),
    });

    return successResponse(res, 201, "Note added successfully.", {
      note: {
        id: newNote.id,
        note: newNote.note,
        createdAt: newNote.createdAt,
        caregiverName: caregiver.caregiverName,
      },
    });
  } catch (error) {
    console.error("addNote error:", error);
    next(error);
  }
};

exports.deleteNote = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const note = await CaregiverNote.findOne({ where: { id, userId } });
    if (!note) {
      return errorResponse(res, 404, "Note not found.");
    }

    await note.destroy();
    return successResponse(res, 200, "Note deleted successfully.");
  } catch (error) {
    next(error);
  }
};
