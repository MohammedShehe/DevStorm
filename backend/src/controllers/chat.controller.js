const { Op } = require("sequelize");
const ChatMessage = require("../models/chat_message.model");
const User = require("../models/user.model");
const Caregiver = require("../models/caregiver.model");
const { successResponse, errorResponse } = require("../utils/response");

async function areLinked(userAId, userBId) {
  const userA = await User.findByPk(userAId);
  const userB = await User.findByPk(userBId);
  if (!userA || !userB) return false;
  const link = await Caregiver.findOne({
    where: {
      [Op.or]: [
        { userId: userAId, email: userB.email },
        { userId: userBId, email: userA.email },
      ],
      status: { [Op.in]: ["Pending", "Accepted"] },
    },
  });
  return !!link;
}

exports.getMessages = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const otherId = parseInt(req.params.userId, 10);
    if (!otherId) return errorResponse(res, 400, "Invalid user id.");
    const linked = await areLinked(userId, otherId);
    if (!linked) return errorResponse(res, 403, "You can only chat with linked caregivers or patients.");
    const messages = await ChatMessage.findAll({
      where: {
        [Op.or]: [
          { senderId: userId, receiverId: otherId },
          { senderId: otherId, receiverId: userId },
        ],
      },
      order: [["createdAt", "ASC"]],
      limit: 200,
    });
    await ChatMessage.update(
      { isRead: true },
      { where: { senderId: otherId, receiverId: userId, isRead: false } }
    );
    return successResponse(res, 200, "Messages fetched.", { messages });
  } catch (error) {
    next(error);
  }
};

exports.sendMessage = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { receiverId, message } = req.body;
    if (!receiverId || !message || !String(message).trim()) {
      return errorResponse(res, 400, "receiverId and message are required.");
    }
    const linked = await areLinked(userId, parseInt(receiverId, 10));
    if (!linked) return errorResponse(res, 403, "You can only chat with linked caregivers or patients.");
    const msg = await ChatMessage.create({
      senderId: userId,
      receiverId: parseInt(receiverId, 10),
      message: String(message).trim(),
    });
    return successResponse(res, 201, "Message sent.", { message: msg });
  } catch (error) {
    next(error);
  }
};

exports.getConversations = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const me = await User.findByPk(userId);
    if (!me) return errorResponse(res, 404, "User not found.");
    let partners = [];
    if (me.role === "patient") {
      const links = await Caregiver.findAll({ where: { userId } });
      for (const link of links) {
        const cg = await User.findOne({ where: { email: link.email, role: "caregiver" } });
        if (cg) {
          partners.push({
            id: cg.id,
            fullName: cg.fullName,
            email: cg.email,
            role: cg.role,
            linkStatus: link.status,
          });
        }
      }
    } else {
      const links = await Caregiver.findAll({ where: { email: me.email } });
      for (const link of links) {
        const patient = await User.findByPk(link.userId, { attributes: { exclude: ["password"] } });
        if (patient) {
          partners.push({
            id: patient.id,
            fullName: patient.fullName,
            email: patient.email,
            role: patient.role,
            linkStatus: link.status,
          });
        }
      }
    }
    return successResponse(res, 200, "Conversations fetched.", { partners });
  } catch (error) {
    next(error);
  }
};
