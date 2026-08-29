// src/server.js
const path = require("path");
// Always load backend/.env regardless of process cwd
require("dotenv").config({ path: path.join(__dirname, "..", ".env") });


const app = require("./app");
const { connectDatabase } = require("./config/db");
const { verifyMailConnection } = require("./config/mail");

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    // Connect database
    await connectDatabase();

    // Verify email configuration
    await verifyMailConnection();

    // Start Express server
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`MediTrack server running on port ${PORT}`);
    });
  } catch (error) {
    console.error("Failed to start server:");
    console.error(error);
    process.exit(1);
  }
};

startServer();