// src/validators/auth.validator.js
const validateRegistration = (data) => {
  const errors = [];

  const {
    fullName,
    email,
    phoneNumber,
    dateOfBirth,
    gender,
    password,
    confirmPassword
  } = data;

  // Full name
  if (!fullName || typeof fullName !== "string") {
    errors.push("Full name is required.");
  } else if (fullName.trim().length < 2) {
    errors.push("Full name must contain at least 2 characters.");
  } else if (fullName.trim().length > 100) {
    errors.push("Full name cannot exceed 100 characters.");
  }

  // Email
  if (!email || typeof email !== "string") {
    errors.push("Email is required.");
  } else {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(email.trim())) {
      errors.push("Please provide a valid email address.");
    }
  }

  // Phone number
  if (!phoneNumber || typeof phoneNumber !== "string") {
    errors.push("Phone number is required.");
  } else {
    const phoneRegex = /^\+?[0-9]{10,15}$/;

    if (!phoneRegex.test(phoneNumber.trim())) {
      errors.push("Phone number must contain 10 to 15 digits.");
    }
  }

  // Date of birth
  if (!dateOfBirth) {
    errors.push("Date of birth is required.");
  } else {
    const dob = new Date(dateOfBirth);

    if (Number.isNaN(dob.getTime())) {
      errors.push("Please provide a valid date of birth.");
    } else if (dob > new Date()) {
      errors.push("Date of birth cannot be in the future.");
    }
  }

  // Gender
  const allowedGenders = ["MALE", "FEMALE", "OTHERS"];

  if (!gender) {
    errors.push("Gender is required.");
  } else if (!allowedGenders.includes(gender)) {
    errors.push("Gender must be MALE, FEMALE, or OTHERS.");
  }

  // Password
  if (!password || typeof password !== "string") {
    errors.push("Password is required.");
  } else {
    if (password.length < 8) {
      errors.push("Password must contain at least 8 characters.");
    }

    if (password.length > 72) {
      errors.push("Password cannot exceed 72 characters.");
    }
  }

  // Confirm password
  if (!confirmPassword) {
    errors.push("Confirm password is required.");
  } else if (password !== confirmPassword) {
    errors.push("Passwords do not match.");
  }

  return errors;
};

const validateLogin = (data) => {
  const errors = [];
  const { email, password } = data;

  if (!email || typeof email !== "string") {
    errors.push("Email is required.");
  } else {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.trim())) {
      errors.push("Please provide a valid email address.");
    }
  }

  if (!password || typeof password !== "string") {
    errors.push("Password is required.");
  } else if (password.length < 8) {
    errors.push("Password must contain at least 8 characters.");
  }

  return errors;
};

const validateForgotPassword = (data) => {
  const errors = [];
  const { email } = data;

  if (!email || typeof email !== "string") {
    errors.push("Email is required.");
  } else {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.trim())) {
      errors.push("Please provide a valid email address.");
    }
  }

  return errors;
};

const validateOtpVerification = (data) => {
  const errors = [];
  const { email, otp } = data;

  if (!email || typeof email !== "string") {
    errors.push("Email is required.");
  } else {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.trim())) {
      errors.push("Please provide a valid email address.");
    }
  }

  if (!otp || typeof otp !== "string") {
    errors.push("OTP is required.");
  } else if (!/^\d{6}$/.test(otp.trim())) {
    errors.push("OTP must be a 6-digit number.");
  }

  return errors;
};

const validateResetPassword = (data) => {
  const errors = [];
  const { resetToken, newPassword, confirmPassword } = data;

  if (!resetToken || typeof resetToken !== "string") {
    errors.push("Reset token is required.");
  }

  if (!newPassword || typeof newPassword !== "string") {
    errors.push("New password is required.");
  } else {
    if (newPassword.length < 8) {
      errors.push("Password must contain at least 8 characters.");
    }
    if (newPassword.length > 72) {
      errors.push("Password cannot exceed 72 characters.");
    }
  }

  if (!confirmPassword || typeof confirmPassword !== "string") {
    errors.push("Confirm password is required.");
  } else if (newPassword !== confirmPassword) {
    errors.push("Passwords do not match.");
  }

  return errors;
};

module.exports = {
  validateRegistration,
  validateLogin,
  validateForgotPassword,
  validateOtpVerification,
  validateResetPassword
};