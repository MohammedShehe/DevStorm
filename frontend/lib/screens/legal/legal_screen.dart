import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

enum LegalDocType { privacy, terms, about, faqs, support }

class LegalScreen extends StatelessWidget {
  final LegalDocType type;
  const LegalScreen({super.key, required this.type});

  String get _title {
    switch (type) {
      case LegalDocType.privacy:
        return 'Privacy Policy';
      case LegalDocType.terms:
        return 'Terms of Service';
      case LegalDocType.about:
        return 'About MediTrack';
      case LegalDocType.faqs:
        return 'FAQs';
      case LegalDocType.support:
        return 'Contact Support';
    }
  }

  String get _body {
    switch (type) {
      case LegalDocType.privacy:
        return '''
MediTrack respects your privacy.

Information we collect
• Account details (name, email, phone, date of birth, gender)
• Medicine schedules and dose logs you enter
• App preferences (theme, accessibility)

How we use data
• To provide reminders and adherence reports
• To enable caregiver linking when you invite someone
• We do not sell your personal health data

Storage & security
• Data is stored on servers you configure
• Passwords are hashed; sessions use JWT tokens
• You can request deletion of your account data

Third parties
• Email delivery may use an SMTP provider you configure
• No advertising SDKs are included in this app

Contact
For privacy requests, use Contact Support in the app.
''';
      case LegalDocType.terms:
        return '''
By using MediTrack you agree to these terms.

MediTrack is a personal medicine reminder tool. It is not a medical device and does not provide clinical advice. Always follow guidance from your healthcare professional.

You are responsible for the accuracy of medicines and schedules you enter. Missed-dose automation is best-effort and may depend on the device being online.

Accounts must use accurate contact information. Do not share login credentials.

We may update these terms; continued use after changes constitutes acceptance.
''';
      case LegalDocType.about:
        return '''
MediTrack
Version 1.0.0

Your medicine, on time, every time.

Features
• Medicine inventory & schedules
• Daily dose tracking (taken / skipped / missed)
• Adherence reports and streaks
• Caregiver invitations
• Accessibility options (text scale, high contrast, themes)

Built as a full-stack Flutter + Node.js / MySQL application.
''';
      case LegalDocType.faqs:
        return '''
How do I add a medicine?
Open the center + button or Medicines tab → Add Medicine. Fill name, dosage, times, and start date.

Why did I get logged out?
Sessions expire after the JWT lifetime (default 7 days). Log in again; the app will restore your session while the token is valid.

Do barcode / voice work?
They currently return sample medicine details for demo purposes. You can still edit fields before saving.

How do caregivers work?
Profile → Caregiver Linking → Invite with name and email. The invite is stored; email is sent when SMTP is configured on the server.

Is data synced offline?
The app requires network access to the backend API for medicines and doses.
''';
      case LegalDocType.support:
        return '''
We're here to help.

Email
support@meditrack.app

What to include
- Your registered email address
- A short description of the problem
- Screenshots if something looks wrong
- App version: 1.0.0

Common fixes
- Pull down on lists to refresh medicines and doses
- Check that reminders are enabled in Notification Settings
- Make sure you are connected to the internet

Hours
Monday-Friday, 9:00 AM - 6:00 PM (local time)

We aim to respond within 1-2 business days.
''';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          _body.trim(),
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.55,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}
