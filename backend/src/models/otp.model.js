// src/models/otp.model.js
const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const Otp = sequelize.define(
  "Otp",
  {
    id: {
      type: DataTypes.BIGINT.UNSIGNED,
      autoIncrement: true,
      primaryKey: true
    },
    email: {
      type: DataTypes.STRING(150),
      allowNull: false,
      validate: {
        isEmail: {
          msg: "Please provide a valid email address."
        }
      }
    },
    otp: {
      type: DataTypes.STRING(6),
      allowNull: false,
      validate: {
        isNumeric: true,
        len: {
          args: [6, 6],
          msg: "OTP must be 6 digits."
        }
      }
    },
    expiresAt: {
      type: DataTypes.DATE,
      allowNull: false
    },
    isUsed: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false
    }
  },
  {
    tableName: "otps",
    timestamps: true,
    createdAt: "createdAt",
    updatedAt: "updatedAt"
  }
);

module.exports = Otp;