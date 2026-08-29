const NotificationPref = require("../models/notification_pref.model");
const { successResponse, errorResponse } = require("../utils/response");

// Get notification settings
exports.getSettings = async (req, res, next) => {
  try {
    const userId = req.user.id;

    let prefs = await NotificationPref.findOne({ where: { userId } });
    if (!prefs) {
      // Create default settings
      prefs = await NotificationPref.create({ userId });
    }

    return successResponse(res, 200, "Notification settings fetched.", { settings: prefs });
  } catch (error) {
    next(error);
  }
};

// Update notification settings
exports.updateSettings = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { soundEnabled, vibrationEnabled, snoozeMinutes, missedDoseAlerts, soundName } = req.body;

    let prefs = await NotificationPref.findOne({ where: { userId } });
    if (!prefs) {
      prefs = await NotificationPref.create({ userId });
    }

    await prefs.update({
      soundEnabled: soundEnabled !== undefined ? soundEnabled : prefs.soundEnabled,
      vibrationEnabled: vibrationEnabled !== undefined ? vibrationEnabled : prefs.vibrationEnabled,
      snoozeMinutes: snoozeMinutes !== undefined ? snoozeMinutes : prefs.snoozeMinutes,
      missedDoseAlerts: missedDoseAlerts !== undefined ? missedDoseAlerts : prefs.missedDoseAlerts,
      soundName: soundName || prefs.soundName,
    });

    return successResponse(res, 200, "Notification settings updated.", { settings: prefs });
  } catch (error) {
    next(error);
  }
};