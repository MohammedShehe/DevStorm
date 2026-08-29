const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/auth.routes");
const userRoutes = require("./routes/user.routes");
const medicineRoutes = require("./routes/medicine.routes");
const doseRoutes = require("./routes/dose.routes");
const notificationRoutes = require("./routes/notification.routes");
const reportRoutes = require("./routes/report.routes");
const preferenceRoutes = require("./routes/preference.routes");
const caregiverNoteRoutes = require("./routes/caregiverNote.routes");
const familyMemberRoutes = require("./routes/familyMember.routes");
const aiRoutes = require("./routes/ai.routes");

const errorMiddleware = require("./middlewares/error.middleware");

const app = express();

// Global middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "MediTrack API is running.",
  });
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/medicines", medicineRoutes);
app.use("/api/doses", doseRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/preferences", preferenceRoutes);
app.use("/api/caregivers", caregiverNoteRoutes);
app.use("/api/family-members", familyMemberRoutes);
app.use("/api/ai", aiRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found.",
  });
});

// Global error handler
app.use(errorMiddleware);

module.exports = app;