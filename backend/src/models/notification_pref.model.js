const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const NotificationPref = sequelize.define(
  "NotificationPref",
  {
    id: {
      type: DataTypes.BIGINT.UNSIGNED,
      autoIncrement: true,
      primaryKey: true,
    },
    userId: {
      type: DataTypes.BIGINT.UNSIGNED,
      allowNull: false,
      unique: true,
      references: {
        model: "users",
        key: "id",
      },
    },
    soundEnabled: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    vibrationEnabled: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    snoozeMinutes: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 10,
      validate: {
        min: { args: [1], msg: "Snooze minutes must be at least 1." },
        max: { args: [60], msg: "Snooze minutes cannot exceed 60." },
      },
    },
    missedDoseAlerts: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    soundName: {
      type: DataTypes.STRING(50),
      allowNull: false,
      defaultValue: "Chime",
    },
  },
  {
    tableName: "notification_prefs",
    timestamps: true,
    createdAt: "createdAt",
    updatedAt: "updatedAt",
  }
);

module.exports = NotificationPref;