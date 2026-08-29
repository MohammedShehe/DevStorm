const UserPreference = require("../models/user_preference.model");
const { successResponse, errorResponse } = require("../utils/response");

// Get user preferences
exports.getPreferences = async (req, res, next) => {
  try {
    const userId = req.user.id;

    let prefs = await UserPreference.findOne({ where: { userId } });
    if (!prefs) {
      prefs = await UserPreference.create({ userId });
    }

    return successResponse(res, 200, "Preferences fetched.", { preferences: prefs });
  } catch (error) {
    next(error);
  }
};

// Update user preferences
exports.updatePreferences = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { themeMode, textScale, highContrast, voiceAnnouncements } = req.body;

    let prefs = await UserPreference.findOne({ where: { userId } });
    if (!prefs) {
      prefs = await UserPreference.create({ userId });
    }

    await prefs.update({
      themeMode: themeMode || prefs.themeMode,
      textScale: textScale !== undefined ? textScale : prefs.textScale,
      highContrast: highContrast !== undefined ? highContrast : prefs.highContrast,
      voiceAnnouncements: voiceAnnouncements !== undefined ? voiceAnnouncements : prefs.voiceAnnouncements,
    });

    return successResponse(res, 200, "Preferences updated.", { preferences: prefs });
  } catch (error) {
    next(error);
  }
};