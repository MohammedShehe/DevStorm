const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const CaregiverNote = sequelize.define(
  "CaregiverNote",
  {
    id: {
      type: DataTypes.BIGINT.UNSIGNED,
      autoIncrement: true,
      primaryKey: true,
    },
    caregiverId: {
      type: DataTypes.BIGINT.UNSIGNED,
      allowNull: false,
      references: {
        model: "caregivers",
        key: "id",
      },
    },
    userId: {
      type: DataTypes.BIGINT.UNSIGNED,
      allowNull: false,
      references: {
        model: "users",
        key: "id",
      },
    },
    note: {
      type: DataTypes.TEXT,
      allowNull: false,
      validate: {
        notEmpty: { msg: "Note content is required." },
      },
    },
  },
  {
    tableName: "caregiver_notes",
    timestamps: true,
    createdAt: "createdAt",
    updatedAt: "updatedAt",
  }
);

module.exports = CaregiverNote;
