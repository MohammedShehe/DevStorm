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
          gender: updatedUser.gender
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
    const { caregiverName, email } = req.body;

    // Validate
    if (!caregiverName || !caregiverName.trim()) {
      return errorResponse(
        res,
        400,
        "Caregiver name is required."
      );
    }

    if (!email || !email.trim()) {
      return errorResponse(
        res,
        400,
        "Caregiver email is required."
      );
    }

    // Check if already invited
    const existingInvite = await Caregiver.findOne({
      where: {
        userId,
        email: email.toLowerCase()
      }
    });

    if (existingInvite) {
      return errorResponse(
        res,
        409,
        "This caregiver has already been invited."
      );
    }

    // Create invitation
    const caregiver = await Caregiver.create({
      userId,
      caregiverName: caregiverName.trim(),
      email: email.toLowerCase(),
      status: "Pending"
    });

    // TODO: Send invitation email (optional)

    return successResponse(
      res,
      201,
      "Caregiver invited successfully.",
      {
        caregiver: {
          id: caregiver.id,
          caregiverName: caregiver.caregiverName,
          email: caregiver.email,
          status: caregiver.status
        }
      }
    );
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getProfile,
  updateProfile,
  getCaregivers,
  inviteCaregiver
};