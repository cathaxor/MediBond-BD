import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../data/models/family_member.dart';
import '../../../state/app_state_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _personalFormKey = GlobalKey<FormState>();

  int _currentPage = 0;

  // Step 2: Personal Information
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  int _selectedColorValue = 0xFF087F79;

  // Step 3: Health Information
  String _selectedBloodGroup = 'Not Set';
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _notesController = TextEditingController();

  // Step 4: Emergency Contact
  final _emergencyNameController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  final List<int> _colorOptions = const [
    0xFF087F79, // Teal
    0xFF1E40AF, // Blue
    0xFF9D174D, // Maroon
    0xFF047857, // Emerald
    0xFFD97706, // Amber
    0xFF7C3AED, // Purple
  ];

  final List<String> _bloodGroups = const [
    'Not Set',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _notesController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeAndSaveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.substring(0, 1).toUpperCase();

    final ageVal = int.tryParse(_ageController.text.trim()) ?? 30;
    final heightVal = double.tryParse(_heightController.text.trim());
    final weightVal = double.tryParse(_weightController.text.trim());

    final emName = _emergencyNameController.text.trim();
    final emRel = _emergencyRelationController.text.trim();
    final emPhone = _emergencyPhoneController.text.trim();

    final primaryProfile = FamilyMember(
      id: 'primary_self',
      name: name,
      relationship: 'Self',
      relationshipBn: 'আমি',
      age: ageVal,
      dateOfBirth: _selectedDateOfBirth,
      birthYear: _selectedDateOfBirth?.year,
      gender: _selectedGender,
      bloodGroup: _selectedBloodGroup,
      heightCm: heightVal,
      weightKg: weightVal,
      allergies: _allergiesController.text.trim(),
      emergencyContact: emPhone,
      emergencyName: emName,
      emergencyRelationship: emRel,
      medicalNotes: _notesController.text.trim(),
      avatarInitials: initials,
      avatarColorValue: _selectedColorValue,
    );

    await ref
        .read(appStateProvider.notifier)
        .savePrimaryProfile(primaryProfile);

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final isBn = locale.languageCode == 'bn';

    return Scaffold(
      appBar: AppBar(
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _prevPage,
              )
            : null,
        title: Text(
          loc?.translate('appName') ?? 'MediBond BD',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton.filledTonal(
            onPressed: () {
              ref.read(localeProvider.notifier).toggleLocale();
            },
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language_rounded, size: 16),
                const SizedBox(width: 4),
                Text(
                  isBn ? 'EN' : 'বাং',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator (Steps 1 to 6)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: List.generate(6, (index) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? AppColors.primary
                            : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) {
                  setState(() => _currentPage = idx);
                },
                children: [
                  _buildStep1Welcome(context, loc, isBn),
                  _buildStep2PersonalInfo(context, loc, isBn),
                  _buildStep3HealthInfo(context, loc, isBn),
                  _buildStep4EmergencyContact(context, loc, isBn),
                  _buildStep5Reminders(context, loc, isBn),
                  _buildStep6SummaryReview(context, loc, isBn),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: WELCOME
  Widget _buildStep1Welcome(
    BuildContext context,
    AppLocalizations? loc,
    bool isBn,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 40 : 15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 110,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            loc?.translate('welcomeHeading') ?? 'Welcome to MediBond BD',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isBn
                ? 'আপনার ওষুধ। আপনার রুটিন। আপনার পরিবার।'
                : 'Your Medicine. Your Schedule. Your Family.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            loc?.translate('welcomeBody') ?? 'Your offline-first medicine reminder and family health organizer tailored for Bangladesh.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isBn
                          ? '১০০% অফলাইন এবং এনক্রিপ্টেড। আপনার স্বাস্থ্য ডাটা শুধু আপনার ফোনেই থাকবে।'
                          : '100% Offline & Encrypted. Your health records stay on your device.',
                      style: const TextStyle(fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _nextPage,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(loc?.translate('next') ?? 'Get Started'),
          ),
        ],
      ),
    );
  }

  // STEP 2: PERSONAL INFORMATION
  Widget _buildStep2PersonalInfo(
    BuildContext context,
    AppLocalizations? loc,
    bool isBn,
  ) {
    return Form(
      key: _personalFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Only your full name is required. All other fields are optional.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 24),

            // Full Name (Required)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                hintText: 'e.g. Tanvir Ahmed',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date of Birth & Age
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(
                          const Duration(days: 365 * 30),
                        ),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDateOfBirth = picked;
                          final calculatedAge =
                              DateTime.now().year - picked.year;
                          _ageController.text = calculatedAge.toString();
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_month_rounded, size: 20),
                    label: Text(
                      _selectedDateOfBirth != null
                          ? DateFormat('dd MMM yyyy')
                                .format(_selectedDateOfBirth!)
                          : 'Date of Birth',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age (Years)',
                      hintText: 'e.g. 32',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender (Optional)',
                prefixIcon: Icon(Icons.people_outline_rounded),
              ),
              hint: const Text('Select Gender'),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
                DropdownMenuItem(
                  value: 'Prefer not to say',
                  child: Text('Prefer not to say'),
                ),
              ],
              onChanged: (val) {
                setState(() => _selectedGender = val);
              },
            ),
            const SizedBox(height: 20),

            // Avatar Color Theme
            const Text(
              'Avatar Color Theme',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _colorOptions.map((c) {
                final isSelected = _selectedColorValue == c;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColorValue = c);
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(c),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                if (_personalFormKey.currentState!.validate()) {
                  _nextPage();
                }
              },
              child: const Text('Continue to Health Details'),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 3: HEALTH INFORMATION
  Widget _buildStep3HealthInfo(
    BuildContext context,
    AppLocalizations? loc,
    bool isBn,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Health Information',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _nextPage,
                child: const Text('Skip This Step'),
              ),
            ],
          ),
          Text(
            'All fields are optional. You can add or update health details later.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 24),

          // Blood Group Dropdown
          DropdownButtonFormField<String>(
            value: _selectedBloodGroup,
            decoration: const InputDecoration(
              labelText: 'Blood Group (Optional)',
              prefixIcon: Icon(
                Icons.bloodtype_outlined,
                color: AppColors.error,
              ),
            ),
            items: _bloodGroups.map((bg) {
              return DropdownMenuItem(value: bg, child: Text(bg));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedBloodGroup = val);
            },
          ),
          const SizedBox(height: 16),

          // Height & Weight
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    hintText: 'e.g. 175',
                    prefixIcon: Icon(Icons.height_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'e.g. 70',
                    prefixIcon: Icon(Icons.scale_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Known Allergies
          TextFormField(
            controller: _allergiesController,
            decoration: const InputDecoration(
              labelText: 'Known Allergies (Optional)',
              hintText: 'e.g. Penicillin, Dust, Peanuts',
              prefixIcon: Icon(Icons.warning_amber_rounded),
            ),
          ),
          const SizedBox(height: 16),

          // Medical Notes
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Medical Notes / History (Optional)',
              hintText: 'e.g. Mild Hypertension, Diabetes',
              prefixIcon: Icon(Icons.note_alt_outlined),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _nextPage,
            child: const Text('Continue to Emergency Contact'),
          ),
        ],
      ),
    );
  }

  // STEP 4: EMERGENCY CONTACT
  Widget _buildStep4EmergencyContact(
    BuildContext context,
    AppLocalizations? loc,
    bool isBn,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Emergency Contact',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _nextPage,
                child: const Text('Skip Contact'),
              ),
            ],
          ),
          Text(
            'Optionally add a relative or primary caregiver for urgent alerts.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _emergencyNameController,
            decoration: const InputDecoration(
              labelText: 'Contact Name (Optional)',
              hintText: 'e.g. Rahim Uddin',
              prefixIcon: Icon(Icons.person_pin_rounded),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emergencyRelationController,
            decoration: const InputDecoration(
              labelText: 'Relationship (Optional)',
              hintText: 'e.g. Brother / Spouse / Parent',
              prefixIcon: Icon(Icons.family_restroom_rounded),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number (Optional)',
              hintText: 'e.g. +880 1700 000000',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _nextPage,
            child: const Text('Continue to Reminders'),
          ),
        ],
      ),
    );
  }

  // STEP 5: REMINDERS SETUP
  Widget _buildStep5Reminders(
    BuildContext context,
    AppLocalizations? loc,
    bool isBn,
  ) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              size: 72,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Medication Reminders',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Enable local notifications so MediBond BD can alert you on time for scheduled doses, even when offline.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildFeatureBullet(
                    Icons.alarm_on_rounded,
                    'Timely alerts for morning, afternoon, & night doses.',
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureBullet(
                    Icons.snooze_rounded,
                    'Quick Take, Skip, and Snooze action buttons.',
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () async {
              await NotificationService().requestPermissions();
              _nextPage();
            },
            icon: const Icon(Icons.notifications_outlined),
            label: const Text('Enable Reminders & Review'),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: _nextPage, child: const Text('Skip for Now')),
        ],
      ),
    );
  }

  // STEP 6: SUMMARY REVIEW & COMPLETE SETUP
  Widget _buildStep6SummaryReview(
    BuildContext context,
    AppLocalizations? loc,
    bool isBn,
  ) {
    final name = _nameController.text.trim();
    final ageStr = _ageController.text.trim();
    final heightStr = _heightController.text.trim();
    final weightStr = _weightController.text.trim();
    final allergiesStr = _allergiesController.text.trim();
    final notesStr = _notesController.text.trim();
    final emName = _emergencyNameController.text.trim();
    final emPhone = _emergencyPhoneController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Summary Review',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Please review your details. You can edit optional details anytime in My Profile.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(_selectedColorValue),
                        child: Text(
                          name.length >= 2
                              ? name.substring(0, 2).toUpperCase()
                              : (name.isNotEmpty ? name[0].toUpperCase() : 'U'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isNotEmpty ? name : 'Full Name Required',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Primary Profile (Self)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Age / DOB',
                    _selectedDateOfBirth != null
                        ? DateFormat('dd MMM yyyy')
                              .format(_selectedDateOfBirth!)
                        : (ageStr.isNotEmpty ? '$ageStr Years' : 'Not Set'),
                  ),
                  _buildSummaryRow('Gender', _selectedGender ?? 'Not Set'),
                  _buildSummaryRow('Blood Group', _selectedBloodGroup),
                  _buildSummaryRow(
                    'Height',
                    heightStr.isNotEmpty ? '$heightStr cm' : 'Not Set',
                  ),
                  _buildSummaryRow(
                    'Weight',
                    weightStr.isNotEmpty ? '$weightStr kg' : 'Not Set',
                  ),
                  _buildSummaryRow(
                    'Allergies',
                    allergiesStr.isNotEmpty ? allergiesStr : 'Not Set',
                  ),
                  _buildSummaryRow(
                    'Medical Notes',
                    notesStr.isNotEmpty ? notesStr : 'Not Set',
                  ),
                  _buildSummaryRow(
                    'Emergency Contact',
                    emPhone.isNotEmpty
                        ? '$emName ($emPhone)'
                        : (emName.isNotEmpty ? emName : 'Not Set'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _completeAndSaveProfile,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Save Profile & Start'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              _pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: const Text('Edit Information'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
