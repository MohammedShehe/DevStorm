const { Sequelize } = require("sequelize");
require("dotenv").config();

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    dialect: "mysql",
    logging: false,
    pool: {
      max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000,
    },
    timezone: "+00:00",
    dialectOptions: {
      dateStrings: true,
      typeCast: true,
    },
  }
);

const connectDatabase = async () => {
  try {
    await sequelize.authenticate();
    console.log("MySQL database connected successfully.");

    // Import all models
    const User = require("../models/user.model");
    const Otp = require("../models/otp.model");
    const Caregiver = require("../models/caregiver.model");
    const Medicine = require("../models/medicine.model");
    const DoseLog = require("../models/dose_log.model");
    const NotificationPref = require("../models/notification_pref.model");
    const UserPreference = require("../models/user_preference.model");
    const CaregiverNote = require("../models/caregiver_note.model");
    const FamilyMember = require("../models/family_member.model");

    // ---- Associations ----

    // User -> Caregiver
    User.hasMany(Caregiver, {
      foreignKey: "userId",
      as: "caregivers",
      onDelete: "CASCADE",
      onUpdate: "CASCADE",
    });
    Caregiver.belongsTo(User, { foreignKey: "userId", as: "user" });

    // User -> Medicine
    User.hasMany(Medicine, {
      foreignKey: "userId",
      as: "medicines",
      onDelete: "CASCADE",
      onUpdate: "CASCADE",
    });
    Medicine.belongsTo(User, { foreignKey: "userId", as: "user" });

    // User -> DoseLog
    User.hasMany(DoseLog, {
      foreignKey: "userId",
      as: "doseLogs",
      onDelete: "CASCADE",
      onUpdate: "CASCADE",
    });
    DoseLog.belongsTo(User, { foreignKey: "userId", as: "user" });

    // Medicine -> DoseLog
    Medicine.hasMany(DoseLog, {
      foreignKey: "medicineId",
      as: "doseLogs",
      onDelete: "CASCADE",
      onUpdate: "CASCADE",
    });
    DoseLog.belongsTo(Medicine, { foreignKey: "medicineId", as: "medicine" });

    // User -> NotificationPref (one-to-one)
    User.hasOne(NotificationPref, {
      foreignKey: "userId",
      as: "notificationPref",
      onDelete: "CASCADE",
      onUpdate: "CASCADE",
    });
    NotificationPref.belongsTo(User, { foreignKey: "userId", as: "user" });

    // User -> UserPreference (one-to-one)
    User.hasOne(UserPreference, {
      foreignKey: "userId",
      as: "preferences",
      onDelete: "CASCADE",
      onUpdate: "CASCADE",
    });
    UserPreference.belongsTo(User, { foreignKey: "userId", as: "user" });

    // Caregiver -> CaregiverNote
    Caregiver.hasMany(CaregiverNote, {
      foreignKey: "caregiverId",
      as: "notes",
      onDelete: "CASCADE",
      onUpdate: "CASCADE",
    });
    CaregiverNote.belongsTo(Caregiver, { foreignKey: "caregiverId", as: "caregiver" });

    // User -> CaregiverNote (as patient)
    User.hasMany(CaregiverNote, {
      foreignKey: "userId",
      as: "patientNotes",
      onDelete: "CASCADE",
      onUpdate: "CASCADE",
    });
    CaregiverNote.belongsTo(User, { foreignKey: "userId", as: "patient" });

    // User -> FamilyMember (as main user)
    User.hasMany(FamilyMember, {
      foreignKey: "userId",
      as: "familyMembers",
      onDelete: "CASCADE",
      onUpdate: "CASCADE",
    });
    FamilyMember.belongsTo(User, { foreignKey: "userId", as: "user" });

    // User -> FamilyMember (as linked member)
    User.hasMany(FamilyMember, {
      foreignKey: "familyMemberId",
      as: "linkedFrom",
      onDelete: "CASCADE",
      onUpdate: "CASCADE",
    });
    FamilyMember.belongsTo(User, { foreignKey: "familyMemberId", as: "familyMember" });

    await sequelize.sync();
    console.log("Database tables synchronized successfully.");
  } catch (error) {
    console.error("Unable to connect to MySQL:");
    console.error(error.message);
    process.exit(1);
  }
};

module.exports = {
  sequelize,
  connectDatabase,
};