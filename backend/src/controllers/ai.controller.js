const { successResponse, errorResponse } = require("../utils/response");
const { chat, TEMPLATES, getAiStatus } = require("../services/aiChat.service");

exports.getTemplates = async (req, res, next) => {
  try {
    const status = getAiStatus();
    return successResponse(res, 200, "Chat templates", {
      templates: TEMPLATES,
      aiEnabled: status.aiEnabled,
      providers: status.providers,
    });
  } catch (e) {
    next(e);
  }
};

exports.chat = async (req, res, next) => {
  try {
    const { message, history } = req.body || {};
    if (!message || !String(message).trim()) {
      return errorResponse(res, 400, "Message is required.");
    }
    const result = await chat({ message, history: history || [] });
    return successResponse(res, 200, "OK", result);
  } catch (e) {
    next(e);
  }
};

exports.status = async (req, res, next) => {
  try {
    return successResponse(res, 200, "AI status", getAiStatus());
  } catch (e) {
    next(e);
  }
};
