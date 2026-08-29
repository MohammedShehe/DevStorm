// src/controllers/user.controller.js
const User = require("../models/user.model");
const Caregiver = require("../models/caregiver.model");
const { Op } = require("sequelize");

const {
  successResponse,
  errorResponse
} = require("../utils/response");

const getProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const user = await User.findByPk(userId, {
      attributes: { exclude: ['password'] }
    });

    if (!user) {
      return errorResponse(
        res,
        404,
        "User not found."
      );
    }

    return successResponse(
      res,
      200,
      "Profile fetched successfully.",
      { user }
    );
  } catch (error) {
    next(error);
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { fullName, email, phoneNumber } = req.body;

    // Check if user exists
    const user = await User.findByPk(userId);

    if (!user) {
      return errorResponse(
        res,
        404,
        "User not found."
      );
    }

    // Check if email is being changed and already exists
    if (email && email.toLowerCase() !== user.email) {
      const existingEmail = await User.findOne({
        where: {
          email: email.toLowerCase(),
          id: { [Op.ne]: userId }
        }
      });

      if (existingEmail) {
        return errorResponse(
          res,
          409,
          "Email already in use by another account."
        );
      }
    }

    // Check if phone is being changed and already exists
    if (phoneNumber && phoneNumber !== user.phoneNumber) {
      const existingPhone = await User.findOne({
        where: {
          phoneNumber: phoneNumber,
          id: { [Op.ne]: userId }
        }
      });

      if (existingPhone) {
        return errorResponse(
          res,
          409,
          "Phone number already in use by another account."
        );
      }
    }

    // Update user
    const updatedUser = await user.update({
      fullName: fullName || user.fullName,
      email: email ? email.toLowerCase() : user.email,
      phoneNumber: phoneNumber || user.phoneNumber
    });

    return successResponse(
      res,
      200,
      "Profile updated successfully.",
      {
        user: {
          id: updatedUser.id,
          fullName: updatedUser.fullName,
          email: updatedUser.email,
          phoneNumber: updatedUser.phoneNumber,
          dateOfBirth: updatedUser.dateOfBirth,
          gender: updatedUser.gender,
          role: updatedUser.role
        }
      }
    );
  } catch (error) {
    next(error);
  }
};

const getCaregivers = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const caregivers = await Caregiver.findAll({
      where: { userId },
      attributes: ['id', 'caregiverName', 'email', 'status'],
      order: [['createdAt', 'DESC']]
    });

    return successResponse(
      res,
      200,
      "Caregivers fetched successfully.",
      { caregivers }
    );
  } catch (error) {
    next(error);
  }
};

const inviteCaregiver = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const me = await User.findByPk(userId);
    if (!me) return errorResponse(res, 404, "User not found.");
    if (me.role !== "patient") {
      return errorResponse(res, 403, "Only patients can link a caregiver.");
    }
    const { email } = req.body;
    if (!email || !email.trim()) {
      return errorResponse(res, 400, "Caregiver email is required.");
    }
    const normalizedEmail = email.trim().toLowerCase();
    const caregiverUser = await User.findOne({
      where: { email: normalizedEmail, role: "caregiver" },
    });
    if (!caregiverUser) {
      return errorResponse(
        res,
        404,
        "No caregiver account found with this email. Please enter a valid caregiver email."
      );
    }
    if (caregiverUser.id === userId) {
      return errorResponse(res, 400, "You cannot link yourself as caregiver.");
    }
    const existingInvite = await Caregiver.findOne({
      where: { userId, email: normalizedEmail },
    });
    if (existingInvite) {
      return errorResponse(res, 409, "This caregiver is already linked.");
    }
    const caregiver = await Caregiver.create({
      userId,
      caregiverName: caregiverUser.fullName,
      email: normalizedEmail,
      status: "Accepted",
    });
    return successResponse(res, 201, "Caregiver linked successfully.", {
      caregiver: {
        id: caregiver.id,
        caregiverName: caregiver.caregiverName,
        email: caregiver.email,
        status: caregiver.status,
        caregiverUserId: caregiverUser.id,
      },
    });
  } catch (error) {
    next(error);
  }
};

const getMyPatients = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const me = await User.findByPk(userId);
    if (!me) return errorResponse(res, 404, "User not found.");
    if (me.role !== "caregiver") {
      return errorResponse(res, 403, "Only caregivers can view patients.");
    }
    const links = await Caregiver.findAll({
      where: { email: me.email },
      order: [["createdAt", "DESC"]],
    });
    const patients = [];
    for (const link of links) {
      const patient = await User.findByPk(link.userId, {
        attributes: { exclude: ["password"] },
      });
      if (patient) {
        patients.push({
          linkId: link.id,
          status: link.status,
          linkedAt: link.createdAt,
          patient: {
            id: patient.id,
            fullName: patient.fullName,
            email: patient.email,
            phoneNumber: patient.phoneNumber,
            dateOfBirth: patient.dateOfBirth,
            gender: patient.gender,
            role: patient.role,
          },
        });
      }
    }
    return successResponse(res, 200, "Patients fetched.", { patients });
  } catch (error) {
    next(error);
  }
};

const getPatientDetail = async (req, res, next) => {
  try {
    const caregiverId = req.user.id;
    const me = await User.findByPk(caregiverId);
    if (!me || me.role !== "caregiver") {
      return errorResponse(res, 403, "Only caregivers can view patient details.");
    }
    const patientId = parseInt(req.params.patientId, 10);
    const link = await Caregiver.findOne({
      where: { userId: patientId, email: me.email },
    });
    if (!link) {
      return errorResponse(res, 403, "This patient is not linked to you.");
    }
    const Medicine = require("../models/medicine.model");
    const DoseLog = require("../models/dose_log.model");
    const patient = await User.findByPk(patientId, {
      attributes: { exclude: ["password"] },
    });
    const medicines = await Medicine.findAll({
      where: { userId: patientId },
      order: [["createdAt", "DESC"]],
    });
    const doses = await DoseLog.findAll({
      where: { userId: patientId },
      order: [["scheduledTime", "DESC"]],
      limit: 100,
    });
    const taken = doses.filter((d) => d.status === "taken").length;
    const missed = doses.filter((d) => d.status === "missed").length;
    const skipped = doses.filter((d) => d.status === "skipped").length;
    const upcoming = doses.filter((d) => d.status === "upcoming").length;
    return successResponse(res, 200, "Patient detail fetched.", {
      patient,
      medicines,
      doses,
      stats: { taken, missed, skipped, upcoming },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getProfile,
  updateProfile,
  getCaregivers,
  inviteCaregiver,
  getMyPatients,
  getPatientDetail
};