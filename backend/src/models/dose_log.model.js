const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const DoseLog = sequelize.define(
  "DoseLog",
  {
    id: {
      type: DataTypes.BIGINT.UNSIGNED,
      autoIncrement: true,
      primaryKey: true,
    },
    userId: {
      type: DataTypes.BIGINT.UNSIGNED,
      allowNull: false,
      references: {
        model: "users",
        key: "id",
      },
    },
    medicineId: {
      type: DataTypes.BIGINT.UNSIGNED,
      allowNull: false,
      references: {
        model: "medicines",
        key: "id",
      },
    },
    medicineName: {
      type: DataTypes.STRING(150),
      allowNull: false,
    },
    dosage: {
      type: DataTypes.STRING(50),
      allowNull: false,
    },
    scheduledTime: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    status: {
      type: DataTypes.ENUM("upcoming", "taken", "missed", "skipped"),
      allowNull: false,
      defaultValue: "upcoming",
    },
    actionTime: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    color: {
      type: DataTypes.STRING(7),
      allowNull: false,
      defaultValue: "#0EA5A0",
    },
  },
  {
    tableName: "dose_logs",
    timestamps: true,
    createdAt: "createdAt",
    updatedAt: "updatedAt",
  }
);

module.exports = DoseLog;