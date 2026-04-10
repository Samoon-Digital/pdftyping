// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PDF Typing';

  @override
  String get splashTagline => 'Your Rural Application Assistant';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeWelcome => 'Welcome to PDF Typing';

  @override
  String get homeSubtitle =>
      'Create ready-made applications for rural & gram panchayat needs. Fill your details and generate PDF instantly.';

  @override
  String get language => 'Language';

  @override
  String get hindi => 'Hindi';

  @override
  String get english => 'English';

  @override
  String get templates => 'Templates';

  @override
  String get noTemplatesYet => 'Templates coming soon...';

  @override
  String get settings => 'Settings';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get template1Title =>
      'Application to remove insurance from savings account';

  @override
  String get template1Subtitle => 'Bank branch insurance removal application';

  @override
  String get editorTitle => 'Application Editor';

  @override
  String get branchName => 'Branch Name';

  @override
  String get branchAddress => 'Branch Address';

  @override
  String get accountNumber => 'Account Number';

  @override
  String get accountHolderName => 'Account Holder Name';

  @override
  String get date => 'Date';

  @override
  String get applicantName => 'Your Name';

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get generatePdf => 'Generate PDF';

  @override
  String get fillAllFields => 'Please fill all fields';

  @override
  String get pdfGenerated => 'PDF Generated Successfully!';
}
