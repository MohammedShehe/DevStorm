const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const Medicine = sequelize.define(
  "Medicine",
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
    name: {
      type: DataTypes.STRING(150),
      allowNull: false,
      validate: {
        notEmpty: { msg: "Medicine name is required." },
        len: { args: [1, 150], msg: "Name must be between 1 and 150 characters." },
      },
    },
    dosage: {
      type: DataTypes.STRING(50),
      allowNull: false,
      validate: {
        notEmpty: { msg: "Dosage is required." },
      },
    },
    form: {
      type: DataTypes.ENUM("tablet", "capsule", "syrup", "injection", "drops", "inhaler", "other"),
      allowNull: false,
    },
    frequency: {
      type: DataTypes.STRING(50),
      allowNull: false,
    },
    times: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
      validate: {
        isValidTimes(value) {
          if (!Array.isArray(value) || value.length === 0) {
            throw new Error("At least one reminder time is required.");
          }
        },
      },
    },
    startDate: {
      type: DataTypes.DATEONLY,
      allowNull: false,
    },
    endDate: {
      type: DataTypes.DATEONLY,
      allowNull: true,
    },
    instructions: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    color: {
      type: DataTypes.STRING(7),
      allowNull: false,
      defaultValue: "#0EA5A0",
      validate: {
        is: {
          args: /^#[0-9A-Fa-f]{6}$/,
          msg: "Color must be a valid hex code (e.g., #0EA5A0).",
        },
      },
    },
    stockCount: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 30,
      validate: {
        min: { args: [0], msg: "Stock count cannot be negative." },
      },
    },
    lowStockThreshold: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 5,
      validate: {
        min: { args: [0], msg: "Threshold cannot be negative." },
      },
    },
  },
  {
    tableName: "medicines",
    timestamps: true,
    createdAt: "createdAt",
    updatedAt: "updatedAt",
  }
);

module.exports = Medicine;