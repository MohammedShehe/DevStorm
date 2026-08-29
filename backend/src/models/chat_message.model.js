const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const ChatMessage = sequelize.define(
  "ChatMessage",
  {
    id: {
      type: DataTypes.BIGINT.UNSIGNED,
      autoIncrement: true,
      primaryKey: true,
    },
    senderId: {
      type: DataTypes.BIGINT.UNSIGNED,
      allowNull: false,
      references: { model: "users", key: "id" },
    },
    receiverId: {
      type: DataTypes.BIGINT.UNSIGNED,
      allowNull: false,
      references: { model: "users", key: "id" },
    },
    message: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    isRead: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
  },
  {
    tableName: "chat_messages",
    timestamps: true,
    createdAt: "createdAt",
    updatedAt: "updatedAt",
  }
);

module.exports = ChatMessage;
