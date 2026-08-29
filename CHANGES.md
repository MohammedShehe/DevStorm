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
