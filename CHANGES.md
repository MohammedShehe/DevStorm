# MediTrack changes

1. Removed Google and Apple login buttons from login screen.
2. Reports & History export now exports patient medicine history (start dates, age, adherence, dose stats) as PDF data dialog. Back button added to Reports header.
3. Notification Settings "Save Preferences" fixed (optimistic local save + robust API update).
4. Removed Multi-user & Family Members from Profile and UI.
5. Role-based onboarding: first-time users choose Patient or Caregiver, then enter name, age/DOB, email, password, etc.
6. Patient dashboard unchanged; Profile → Caregiver Linking adds caregiver by email only (must be a registered caregiver account).
7. Caregiver dashboard lists linked patients; tap patient for medicines + dose history (taken/missed/etc).
8. Chat between patient and linked caregiver via additional FAB menu → Messages.
9. Backend: users.role (patient|caregiver), chat_messages table, /api/chat, /api/users/patients APIs.
10. Run backend/migrate_role_chat.sql on existing databases.
## Latest update — Reports, PDF, caregiver patient view and password reset

- Removed the Caregiver Notes section from Reports & History.
- PDF export now returns a real `application/pdf` file from the backend and the Flutter app opens the system/browser save/print flow so the report can actually be saved.
- Caregiver patient medicine records and dose history are ordered newest/recent first; medicine start/end dates are displayed.
- Added safer spacing around caregiver patient charts.
- Forgot Password now surfaces OTP-send errors, confirms successful OTP delivery, reports verification errors from the server, and continues through OTP verification to the new-password form.
- OTP email delivery no longer silently succeeds when the email service is not configured.
