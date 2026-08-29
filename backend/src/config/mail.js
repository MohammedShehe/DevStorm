const nodemailer = require("nodemailer");
require("dotenv").config();

const transporter = nodemailer.createTransport({
  host: process.env.MAIL_HOST,
  port: Number(process.env.MAIL_PORT),
  secure: process.env.MAIL_SECURE === "true",

  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASSWORD
  }
});

const verifyMailConnection = async () => {
  try {
    await transporter.verify();

    console.log("Email service connected successfully.");
  } catch (error) {
    console.error("Email service connection failed:");
    console.error(error.message);
  }
};

module.exports = {
  transporter,
  verifyMailConnection
};
