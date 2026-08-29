const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const FamilyMember = sequelize.define(
  "FamilyMember",
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
    familyMemberId: {
      type: DataTypes.BIGINT.UNSIGNED,
      allowNull: false,
      references: {
        model: "users",
        key: "id",
      },
    },
    relation: {
      type: DataTypes.STRING(50),
      allowNull: false,
      validate: {
        notEmpty: { msg: "Relation is required." },
      },
    },
    status: {
      type: DataTypes.ENUM("Pending", "Accepted", "Rejected"),
      allowNull: false,
      defaultValue: "Pending",
    },
  },
  {
    tableName: "family_members",
    timestamps: true,
    createdAt: "createdAt",
    updatedAt: "updatedAt",
  }
);

module.exports = FamilyMember;