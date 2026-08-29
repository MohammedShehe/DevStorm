const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const Caregiver = sequelize.define(
  "Caregiver",
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
    caregiverName: {
      type: DataTypes.STRING(100),
      allowNull: false,
      validate: {
        notEmpty: { msg: "Caregiver name is required." },
        len: { args: [2, 100], msg: "Caregiver name must be between 2 and 100 characters." },
      },
    },
    email: {
      type: DataTypes.STRING(150),
      allowNull: false,
      validate: {
        isEmail: { msg: "Please provide a valid email address." },
      },
    },
    status: {
      type: DataTypes.ENUM("Pending", "Accepted", "Rejected"),
      allowNull: false,
      defaultValue: "Pending",
    },
  },
  {
    tableName: "caregivers",
    timestamps: true,
    createdAt: "createdAt",
    updatedAt: "updatedAt",
  }
);

module.exports = Caregiver;
