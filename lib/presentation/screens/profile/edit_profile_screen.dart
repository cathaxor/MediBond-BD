import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/family_member.dart';
import '../../../state/app_state_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  late String _selectedBloodGroup;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _allergiesController;
  late TextEditingController _notesController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyRelationController;
  late TextEditingController _emergencyPhoneController;
  late int _selectedColorValue;

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
  void initState() {
    super.initState();
    final profile = ref.read(appStateProvider).primaryProfile;

    _nameController = TextEditingController(text: profile?.name ?? '');
    _ageController = TextEditingController(
      text: (profile?.calculatedAge ?? 30).toString(),
    );
    _selectedDateOfBirth = profile?.dateOfBirth;
    _selectedGender = profile?.gender;
    _selectedBloodGroup = _bloodGroups.contains(profile?.bloodGroup)
        ? profile!.bloodGroup
        : 'Not Set';
    _heightController = TextEditingController(
      text: profile?.heightCm != null ? profile!.heightCm.toString() : '',
    );
    _weightController = TextEditingController(
      text: profile?.weightKg != null ? profile!.weightKg.toString() : '',
    );
    _allergiesController = TextEditingController(
      text: profile?.allergies ?? '',
    );
    _notesController = TextEditingController(text: profile?.medicalNotes ?? '');
    _emergencyNameController = TextEditingController(
      text: profile?.emergencyName ?? '',
    );
    _emergencyRelationController = TextEditingController(
      text: profile?.emergencyRelationship ?? '',
    );
    _emergencyPhoneController = TextEditingController(
      text: profile?.emergencyContact ?? '',
    );
    _selectedColorValue = profile?.avatarColorValue ?? 0xFF087F79;
  }

  @override
  void dispose() {
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.substring(0, 1).toUpperCase();

    final ageVal = int.tryParse(_ageController.text.trim()) ?? 30;
    final heightVal = double.tryParse(_heightController.text.trim());
    final weightVal = double.tryParse(_weightController.text.trim());

    final currentProfile = ref.read(appStateProvider).primaryProfile;

    final updatedProfile = FamilyMember(
      id: currentProfile?.id ?? 'primary_self',
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
      emergencyContact: _emergencyPhoneController.text.trim(),
      emergencyName: _emergencyNameController.text.trim(),
      emergencyRelationship: _emergencyRelationController.text.trim(),
      medicalNotes: _notesController.text.trim(),
      avatarInitials: initials,
      avatarColorValue: _selectedColorValue,
    );

    await ref
        .read(appStateProvider.notifier)
        .savePrimaryProfile(updatedProfile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('editProfile') ?? 'Edit Profile'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full Name (Required)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Full name is required';
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
                            initialDate:
                                _selectedDateOfBirth ??
                                DateTime.now().subtract(
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
                        icon: const Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                        ),
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
                const SizedBox(height: 16),

                // Blood Group
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
                    prefixIcon: Icon(Icons.warning_amber_rounded),
                  ),
                ),
                const SizedBox(height: 16),

                // Medical Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Medical Notes (Optional)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // Emergency Contact Section
                const Text(
                  'Emergency Contact',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emergencyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Name',
                    prefixIcon: Icon(Icons.person_pin_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emergencyRelationController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    prefixIcon: Icon(Icons.family_restroom_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emergencyPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // Avatar Color Theme
                const Text(
                  'Avatar Theme Color',
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
                  onPressed: _saveProfile,
                  child: const Text('Save Profile Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
