import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('bn', ''),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'MediBond BD',
      'appTagline': 'Offline-first Family Medicine Companion',
      'skip': 'Skip',
      'next': 'Next',
      'getStarted': 'Get Started',

      // Onboarding
      'onboard1Title': 'Smart Medicine Reminders',
      'onboard1Desc': 'Never miss a dose. Get accurate offline alerts tailored for your daily schedule.',
      'onboard2Title': 'Family Health Care',
      'onboard2Desc': 'Organize medication schedules, dosages, and history for your entire family in one place.',
      'onboard3Title': 'Digital Prescription Vault',
      'onboard3Desc': 'Securely store and search doctor prescriptions and medical records anytime offline.',

      // Navigation
      'navHome': 'Home',
      'navMedicines': 'Medicines',
      'navFamily': 'Family',
      'navHistory': 'History',
      'navVault': 'Vault',
      'navSettings': 'Settings',

      // Home Dashboard
      'goodMorning': 'Good Morning,',
      'goodAfternoon': 'Good Afternoon,',
      'goodEvening': 'Good Evening,',
      'nextReminder': 'Next Medicine Reminder',
      'takeNow': 'Take Now',
      'snooze': 'Snooze 10m',
      'markedTaken': 'Marked as Taken',
      'todayTimeline': "Today's Medication Timeline",
      'takenSummary': 'Taken',
      'pendingSummary': 'Pending',
      'missedSummary': 'Missed',
      'totalSummary': 'Total Doses',
      'quickAddMed': 'Quick Add Medicine',
      'allProfiles': 'All Members',
      'noMedsToday': 'No pending medicines remaining for today!',
      'lowStockAlert': 'Low Stock Warning',

      // Medicines
      'medicinesList': 'Medicines List',
      'searchMedicines': 'Search medicine name...',
      'activeMeds': 'Active',
      'completedMeds': 'Completed',
      'addMedicine': 'Add Medicine',
      'editMedicine': 'Edit Medicine',
      'medNameLabel': 'Medicine Name',
      'medNameHint': 'e.g. Napa Extra 500mg',
      'medFormLabel': 'Form / Type',
      'medDoseLabel': 'Dosage',
      'medDoseHint': 'e.g. 1 Tablet / 5 ml',
      'instructionsLabel': 'Instructions',
      'beforeFood': 'Before Food',
      'afterFood': 'After Food',
      'withFood': 'With Food',
      'anytime': 'Any Time',
      'frequencyLabel': 'Times per day',
      'stockQuantity': 'Stock Count',
      'reorderAlertAt': 'Alert when stock reaches',
      'assignToMember': 'Family Member',
      'saveMedicine': 'Save Medicine',
      'updateMedicine': 'Update Medicine',
      'deleteMedicine': 'Delete Medicine',
      'deleteConfirm': 'Are you sure you want to delete this medicine?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'stockLeft': 'left',

      // Family
      'familyProfiles': 'Family Profiles',
      'addMember': 'Add Family Member',
      'memberName': 'Member Name',
      'relationship': 'Relationship',
      'age': 'Age',
      'bloodGroup': 'Blood Group',
      'emergencyContact': 'Emergency Contact',
      'activeMedicinesCount': 'Active Meds',
      'saveMember': 'Save Member',
      'noMembers': 'No family profiles added yet.',

      // History
      'medicationHistory': 'Medication History',
      'adherenceRate': 'Weekly Compliance Rate',
      'filterAll': 'All',
      'filterTaken': 'Taken',
      'filterMissed': 'Missed',
      'noHistoryLogs': 'No medication history logs found.',

      // Prescription Vault
      'prescriptionVault': 'Prescription Vault',
      'uploadPrescription': 'Upload Prescription',
      'searchVault': 'Search doctor, hospital, diagnosis...',
      'doctorName': 'Doctor Name',
      'hospitalClinic': 'Hospital / Clinic',
      'date': 'Date',
      'notes': 'Notes / Diagnosis',
      'viewPrescription': 'View Record',
      'noPrescriptions': 'No prescriptions uploaded yet.',

      // Settings
      'settings': 'Settings',
      'appearance': 'Appearance & Display',
      'themeMode': 'Theme Mode',
      'themeLight': 'Light Mode',
      'themeDark': 'Dark Mode',
      'themeSystem': 'System Default',
      'language': 'Language',
      'bangla': 'বাংলা (Bangla)',
      'english': 'English',
      'notifications': 'Notifications & Reminders',
      'soundAlerts': 'Reminder Alert Sound',
      'vibration': 'Vibration Alert',
      'notificationPrivacy': 'Lock Screen Privacy',
      'hideMedNamesLockScreen': 'Hide medicine names on lock screen',
      'snoozeDuration': 'Snooze Duration',
      'firstDayOfWeek': 'First Day of Week',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
      'monday': 'Monday',
      'demoDataNotice': 'Demo Data Mode',
      'demoDataDesc':
          'Running in UI preview mode. Data changes persist during session.',
      'resetDemoData': 'Reset Demo Data',
      'aboutApp': 'About MediBond BD',
      'aboutNethivo': 'About Nethivo',
      'version': 'Version 1.0.0',
      'developerNotice': 'Developed by Nethivo',
      'privacyPolicy': 'Privacy Policy',
      'supportContact': 'Support & Contact',
      'supportEmail': 'support@nethivo.com',

      // Forms & Types
      'tablet': 'Tablet',
      'syrup': 'Syrup',
      'capsule': 'Capsule',
      'injection': 'Injection',
      'drops': 'Drops',
      'ointment': 'Ointment',
      'other': 'Other',
    },
    'bn': {
      'appName': 'মেডিবন্ড বিডি',
      'appTagline':
          'বাংলাদেশীদের জন্য অফলাইন-ফার্স্ট ফ্যামিলি মেডিসিন ট্র্যাকার',
      'skip': 'এড়িয়ে যান',
      'next': 'পরবর্তী',
      'getStarted': 'শুরু করুন',

      // Onboarding
      'onboard1Title': 'স্মার্ট ওষুধ রিমাইন্ডার',
      'onboard1Desc': 'সময়মতো নির্ভুল অফলাইন অ্যালার্ট পান আপনার এবং পরিবারের ওষুধ সেবনের জন্য।',
      'onboard2Title': 'পরিবারের সমন্বিত স্বাস্থ্যসেবা',
      'onboard2Desc': 'একটি অ্যাপেই পরিবারের সকলের ওষুধের সিডিউল ও হিস্ট্রি ট্র্যাকিং করুন।',
      'onboard3Title': 'ডিজিটাল প্রেসক্রিপশন ভল্ট',
      'onboard3Desc': 'ডাক্তারের প্রেসক্রিপশন ও মেডিকেল রেকর্ড সহজে ও অফলাইনে সুরক্ষিত রাখুন।',

      // Navigation
      'navHome': 'হোম',
      'navMedicines': 'ওষুধের তালিকা',
      'navFamily': 'পরিবার',
      'navHistory': 'ইতিহাস',
      'navVault': 'প্রেসক্রিপশন',
      'navSettings': 'সেটিংস',

      // Home Dashboard
      'goodMorning': 'শুভ সকাল,',
      'goodAfternoon': 'শুভ দুপুর,',
      'goodEvening': 'শুভ সন্ধ্যা,',
      'nextReminder': 'পরবর্তী ওষুধের রিমাইন্ডার',
      'takeNow': 'এখনই গ্রহণ করুন',
      'snooze': '১০ মিনিট পর',
      'markedTaken': 'ওষুধ সেবন সম্পন্ন হয়েছে',
      'todayTimeline': 'আজকের ওষুধের সময়সূচী',
      'takenSummary': 'সেবিত',
      'pendingSummary': 'বাকি',
      'missedSummary': 'মিসড',
      'totalSummary': 'মোট ডোজ',
      'quickAddMed': 'নতুন ওষুধ যোগ করুন',
      'allProfiles': 'সব সদস্য',
      'noMedsToday': 'আজকের জন্য কোনো বাকি ওষুধ নেই!',
      'lowStockAlert': 'স্টক সতর্কতা',

      // Medicines
      'medicinesList': 'ওষুধের তালিকা',
      'searchMedicines': 'ওষুধের নাম খুঁজুন...',
      'activeMeds': 'চলতি ওষুধ',
      'completedMeds': 'সম্পন্ন ওষুধ',
      'addMedicine': 'নতুন ওষুধ যোগ করুন',
      'editMedicine': 'ওষুধ এডিট করুন',
      'medNameLabel': 'ওষুধের নাম',
      'medNameHint': 'যেমন: নাপা এক্সট্রা ৫০০ মি.গ্রা.',
      'medFormLabel': 'প্রকার',
      'medDoseLabel': 'ডোজের পরিমাণ',
      'medDoseHint': 'যেমন: ১টি ট্যাবলেট / ৫ মি.লি.',
      'instructionsLabel': 'পরামর্শ',
      'beforeFood': 'খাবারের আগে',
      'afterFood': 'খাবারের পরে',
      'withFood': 'খাবারের সাথে',
      'anytime': 'যেকোনো সময়',
      'frequencyLabel': 'দৈনিক কতবার',
      'stockQuantity': 'মোট স্টক সংখ্যা',
      'reorderAlertAt': 'স্টক সতর্কতার সীমা',
      'assignToMember': 'পরিবারের সদস্য',
      'saveMedicine': 'ওষুধ সংরক্ষণ করুন',
      'updateMedicine': 'আপডেট করুন',
      'deleteMedicine': 'মুছে ফেলুন',
      'deleteConfirm': 'আপনি কি নিশ্চিত যে এই ওষুধটি মুছে ফেলতে চান?',
      'cancel': 'বাতিল',
      'delete': 'ডিলিট',
      'stockLeft': 'টি বাকি',

      // Family
      'familyProfiles': 'পরিবারের সদস্যগণ',
      'addMember': 'নতুন সদস্য যোগ করুন',
      'memberName': 'সদস্যের নাম',
      'relationship': 'সম্পর্ক',
      'age': 'বয়স',
      'bloodGroup': 'রক্তের গ্রুপ',
      'emergencyContact': 'জরুরী যোগাযোগ',
      'activeMedicinesCount': 'চলতি ওষুধ',
      'saveMember': 'সদস্য সংরক্ষণ করুন',
      'noMembers': 'কোনো সদস্য যুক্ত করা হয়নি।',

      // History
      'medicationHistory': 'ওষুধ সেবনের ইতিহাস',
      'adherenceRate': 'সাপ্তাহিক রুটিন অনুসরণের হার',
      'filterAll': 'সবগুলো',
      'filterTaken': 'সেবিত',
      'filterMissed': 'মিসড',
      'noHistoryLogs': 'কোনো হিস্ট্রি রেকর্ড পাওয়া যায়নি।',

      // Prescription Vault
      'prescriptionVault': 'ডিজিটাল প্রেসক্রিপশন ভল্ট',
      'uploadPrescription': 'প্রেসক্রিপশন আপলোড',
      'searchVault': 'ডাক্তার, হাসপাতাল বা রোগের নাম দিয়ে খুঁজুন...',
      'doctorName': 'ডাক্তারের নাম',
      'hospitalClinic': 'হাসপাতাল / ক্লিনিক',
      'date': 'তারিখ',
      'notes': 'নোট / ডায়াগনোসিস',
      'viewPrescription': 'রেকর্ড দেখুন',
      'noPrescriptions': 'কোনো প্রেসক্রিপশন পাওয়া যায়নি।',

      // Settings
      'settings': 'অ্যাপ সেটিংস',
      'appearance': 'থিম ও ডিসপ্লে',
      'themeMode': 'থিম মোড',
      'themeLight': 'লাইট মোড',
      'themeDark': 'ডার্ক মোড',
      'themeSystem': 'সিস্টেম ডিফল্ট',
      'language': 'ভাষা পরিবর্তন',
      'bangla': 'বাংলা (Bangla)',
      'english': 'English',
      'notifications': 'নোটিফিকেশন ও অ্যালার্ট',
      'soundAlerts': 'রিমাইন্ডার সাউন্ড',
      'vibration': 'ভাইব্রেশন',
      'notificationPrivacy': 'লক স্ক্রিন প্রাইভেসি',
      'hideMedNamesLockScreen': 'লক স্ক্রিনে ওষুধের নাম গোপন রাখুন',
      'snoozeDuration': 'স্নূজ করার সময়',
      'firstDayOfWeek': 'সপ্তাহের প্রথম দিন',
      'saturday': 'শনিবার (Saturday)',
      'sunday': 'রবিবার (Sunday)',
      'monday': 'সোমবার (Monday)',
      'demoDataNotice': 'ডেমো ডাটা মোড',
      'demoDataDesc':
          'অ্যাপটি ইউআই ডেমো মোডে চলছে। ডাটা পরিবর্তন চলতি সেশনে স্থায়ী থাকবে।',
      'resetDemoData': 'ডেমো ডাটা রিসেট করুন',
      'aboutApp': 'মেডিবন্ড বিডি সম্পর্কে',
      'aboutNethivo': 'নেথিভো সম্পর্কে',
      'version': 'ভার্সন ১.০.০',
      'developerNotice': 'ডেভেলপমেন্টে: নেথিভো (Nethivo)',
      'privacyPolicy': 'প্রাইভেসি পলিসি',
      'supportContact': 'সাপোর্ট ও যোগাযোগ',
      'supportEmail': 'support@nethivo.com',

      // Forms & Types
      'tablet': 'ট্যাবলেট',
      'syrup': 'সিরাপ',
      'capsule': 'ক্যাপসুল',
      'injection': 'ইনজেকশন',
      'drops': 'ড্রপস',
      'ointment': 'মলম',
      'other': 'অন্যান্য',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  bool get isBn => locale.languageCode == 'bn';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'bn'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
