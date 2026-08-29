const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const UserPreference = sequelize.define(
  "UserPreference",
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
    themeMode: {
      type: DataTypes.ENUM("light", "dark"),
      allowNull: false,
      defaultValue: "light",
    },
    textScale: {
      type: DataTypes.DECIMAL(3, 2),
      allowNull: false,
      defaultValue: 1.0,
      validate: {
        min: { args: [0.85], msg: "Text scale must be at least 0.85." },
        max: { args: [1.4], msg: "Text scale cannot exceed 1.4." },
      },
    },
    highContrast: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    voiceAnnouncements: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
  },
  {
    tableName: "user_preferences",
    timestamps: true,
    createdAt: "createdAt",
    updatedAt: "updatedAt",
  }
);

module.exports = UserPreference;