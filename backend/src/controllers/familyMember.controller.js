const FamilyMember = require("../models/family_member.model");
const User = require("../models/user.model");
const { successResponse, errorResponse } = require("../utils/response");

// Get family members (no fragile includes — avoid association 500s)
exports.getFamilyMembers = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const rows = await FamilyMember.findAll({
      where: { userId },
      order: [["createdAt", "DESC"]],
    });

    // Enrich with linked user email/name when possible
    const members = [];
    for (const row of rows) {
      let email = null;
      let fullName = null;
      try {
        if (row.familyMemberId) {
          const u = await User.findByPk(row.familyMemberId, {
            attributes: ["id", "fullName", "email", "phoneNumber"],
          });
          if (u) {
            email = u.email;
            fullName = u.fullName;
          }
        }
      } catch (_) {}
      members.push({
        id: row.id,
        userId: row.userId,
        familyMemberId: row.familyMemberId,
        relation: row.relation,
        status: row.status,
        email,
        fullName,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      });
    }

    return successResponse(res, 200, "Family members fetched.", { members });
  } catch (error) {
    console.error("getFamilyMembers error:", error);
    next(error);
  }
};

// Add family member
exports.addFamilyMember = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { email, relation } = req.body;

    if (!email || !relation) {
      return errorResponse(res, 400, "Email and relation are required.");
    }

    const familyUser = await User.findOne({
      where: { email: email.toLowerCase().trim() },
    });
    if (!familyUser) {
      return errorResponse(
        res,
        404,
        "No MediTrack account found with this email. They must register first."
      );
    }

    if (familyUser.id === userId) {
      return errorResponse(res, 400, "You cannot add yourself as a family member.");
    }

    const existing = await FamilyMember.findOne({
      where: { userId, familyMemberId: familyUser.id },
    });
    if (existing) {
      return errorResponse(res, 409, "This user is already linked.");
    }

    const member = await FamilyMember.create({
      userId,
      familyMemberId: familyUser.id,
      relation: relation.trim(),
      status: "Pending",
    });

    return successResponse(res, 201, "Family member added (pending acceptance).", {
      member: {
        id: member.id,
        familyMemberId: member.familyMemberId,
        relation: member.relation,
        status: member.status,
        email: familyUser.email,
        fullName: familyUser.fullName,
      },
    });
  } catch (error) {
    console.error("addFamilyMember error:", error);
    next(error);
  }
};

exports.updateFamilyMember = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { relation, status } = req.body;

    const member = await FamilyMember.findOne({ where: { id, userId } });
    if (!member) {
      return errorResponse(res, 404, "Family member not found.");
    }

    await member.update({
      relation: relation || member.relation,
      status: status || member.status,
    });

    return successResponse(res, 200, "Family member updated.", { member });
  } catch (error) {
    next(error);
  }
};

exports.deleteFamilyMember = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const member = await FamilyMember.findOne({ where: { id, userId } });
    if (!member) {
      return errorResponse(res, 404, "Family member not found.");
    }

    await member.destroy();
    return successResponse(res, 200, "Family member removed.");
  } catch (error) {
    next(error);
  }
};
