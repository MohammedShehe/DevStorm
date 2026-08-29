// src/services/email.service.js
const { transporter } = require("../config/mail");

const canSendMail = () =>
  Boolean(process.env.MAIL_USER && process.env.MAIL_PASSWORD);


const sendWelcomeEmail = async (user) => {

  if (!canSendMail()) {
    console.warn('Email skipped: MAIL_USER/MAIL_PASSWORD not configured');
    return;
  }
  const mailOptions = {
    from: process.env.MAIL_FROM,
    to: user.email,
    subject: "Welcome to MediTrack!",
    text: `
Hello ${user.fullName},

Welcome to MediTrack!

Your account has been successfully created.

We are happy to have you with us.

Thank you for choosing MediTrack.

Regards,
MediTrack Team
    `.trim(),
    html: `
      <div style="
        font-family: Arial, sans-serif;
        max-width: 600px;
        margin: auto;
        padding: 30px;
        color: #333;
      ">
        <h1 style="color: #2563eb;">
          Welcome to MediTrack!
        </h1>
        <p>
          Hello <strong>${user.fullName}</strong>,
        </p>
        <p>
          Welcome to MediTrack!
        </p>
        <p>
          Your account has been successfully created.
        </p>
        <p>
          We are happy to have you with us.
        </p>
        <p>
          Thank you for choosing MediTrack.
        </p>
        <br />
        <p>
          Regards,<br />
          <strong>MediTrack Team</strong>
        </p>
      </div>
    `
  };

  await transporter.sendMail(mailOptions);
};

const sendOtpEmail = async (user, otp) => {

  if (!canSendMail()) {
    console.warn('Email skipped: MAIL_USER/MAIL_PASSWORD not configured');
    return;
  }
  const mailOptions = {
    from: process.env.MAIL_FROM,
    to: user.email,
    subject: "Password Reset OTP - MediTrack",
    text: `
Hello ${user.fullName},

You requested to reset your password for MediTrack.

Your OTP for password reset is: ${otp}

This OTP is valid for 10 minutes.

If you didn't request this, please ignore this email.

Regards,
MediTrack Team
    `.trim(),
    html: `
      <div style="
        font-family: Arial, sans-serif;
        max-width: 600px;
        margin: auto;
        padding: 30px;
        color: #333;
      ">
        <h1 style="color: #2563eb;">
          Password Reset OTP
        </h1>
        <p>
          Hello <strong>${user.fullName}</strong>,
        </p>
        <p>
          You requested to reset your password for MediTrack.
        </p>
        <div style="
          background: #f3f4f6;
          padding: 20px;
          text-align: center;
          border-radius: 10px;
          margin: 20px 0;
        ">
          <h2 style="
            margin: 0;
            color: #2563eb;
            font-size: 36px;
            letter-spacing: 10px;
          ">
            ${otp}
          </h2>
        </div>
        <p>
          This OTP is valid for <strong>10 minutes</strong>.
        </p>
        <p>
          If you didn't request this, please ignore this email.
        </p>
        <br />
        <p>
          Regards,<br />
          <strong>MediTrack Team</strong>
        </p>
      </div>
    `
  };

  await transporter.sendMail(mailOptions);
};

const sendPasswordResetConfirmationEmail = async (user) => {

  if (!canSendMail()) {
    console.warn('Email skipped: MAIL_USER/MAIL_PASSWORD not configured');
    return;
  }
  const mailOptions = {
    from: process.env.MAIL_FROM,
    to: user.email,
    subject: "Password Reset Successful - MediTrack",
    text: `
Hello ${user.fullName},

Your password has been successfully reset.

If you didn't perform this action, please contact our support team immediately.

Regards,
MediTrack Team
    `.trim(),
    html: `
      <div style="
        font-family: Arial, sans-serif;
        max-width: 600px;
        margin: auto;
        padding: 30px;
        color: #333;
      ">
        <h1 style="color: #2563eb;">
          Password Reset Successful
        </h1>
        <p>
          Hello <strong>${user.fullName}</strong>,
        </p>
        <p>
          Your password has been successfully reset.
        </p>
        <p style="
          background: #f0fdf4;
          padding: 15px;
          border-radius: 10px;
          border-left: 4px solid #22c55e;
        ">
          ✅ You can now login with your new password.
        </p>
        <p>
          If you didn't perform this action, please contact our support team immediately.
        </p>
        <br />
        <p>
          Regards,<br />
          <strong>MediTrack Team</strong>
        </p>
      </div>
    `
  };

  await transporter.sendMail(mailOptions);
};

module.exports = {
  sendWelcomeEmail,
  sendOtpEmail,
  sendPasswordResetConfirmationEmail
};