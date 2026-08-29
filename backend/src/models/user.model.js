// src/models/user.model.js
const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const User = sequelize.define(
  "User",
  {
    id: {
      type: DataTypes.BIGINT.UNSIGNED,
      autoIncrement: true,
      primaryKey: true
    },

    fullName: {
      type: DataTypes.STRING(100),
      allowNull: false,

      validate: {
        notEmpty: {
          msg: "Full name is required."
        },

        len: {
          args: [2, 100],
          msg: "Full name must be between 2 and 100 characters."
        }
      }
    },

    email: {
      type: DataTypes.STRING(150),
      allowNull: false,
      unique: true,

      set(value) {
        this.setDataValue("email", value.toLowerCase().trim());
      },

      validate: {
        isEmail: {
          msg: "Please provide a valid email address."
        }
      }
    },

    phoneNumber: {
      type: DataTypes.STRING(20),
      allowNull: false,
      unique: true,

      validate: {
        notEmpty: {
          msg: "Phone number is required."
        }
      }
    },

    dateOfBirth: {
      type: DataTypes.DATEONLY,
      allowNull: false
    },

    gender: {
      type: DataTypes.ENUM(
        "MALE",
        "FEMALE",
        "OTHERS"
      ),
      allowNull: false
    },

    password: {
      type: DataTypes.STRING(255),
      allowNull: false
    }
  },

  {
    tableName: "users",

    timestamps: true,

    createdAt: "createdAt",
    updatedAt: "updatedAt"
  }
);

module.exports = User;