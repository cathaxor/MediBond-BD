import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/medicine.dart';
import '../../../state/app_state_provider.dart';

class AddEditMedicineScreen extends ConsumerStatefulWidget {
  final Medicine? initialMedicine;

  const AddEditMedicineScreen({super.key, this.initialMedicine});

  @override
  ConsumerState<AddEditMedicineScreen> createState() =>
      _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends ConsumerState<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _strengthController;
  late TextEditingController _dosageController;
  late TextEditingController _stockController;
  late TextEditingController _reorderController;
  late TextEditingController _notesController;

  late MedicineForm _selectedForm;
  late MealInstruction _selectedInstruction;
  late List<TimeOfDay> _scheduledTimes;
  late DateTime _startDate;
  DateTime? _endDate;
  late List<int> _selectedWeekdays;
  late String _selectedMemberId;
  late int _selectedColorHex;

  @override
  void initState() {
    super.initState();
    final med = widget.initialMedicine;
    final appState = ref.read(appStateProvider);
    _nameController = TextEditingController(text: med?.name ?? '');
    _strengthController = TextEditingController(text: med?.strength ?? '');
    _dosageController = TextEditingController(text: med?.dosage ?? '1 Tablet');
    _stockController = TextEditingController(
      text: (med?.stockCount ?? 20).toString(),
    );
    _reorderController = TextEditingController(
      text: (med?.reorderThreshold ?? 5).toString(),
    );
    _notesController = TextEditingController(text: med?.notes ?? '');

    _selectedForm = med?.form ?? MedicineForm.tablet;
    _selectedInstruction = med?.instructions ?? MealInstruction.afterFood;
    _scheduledTimes = med != null
        ? List.from(med.scheduledTimes)
        : [
            const TimeOfDay(hour: 8, minute: 30),
            const TimeOfDay(hour: 20, minute: 30),
          ];
    _startDate = med?.startDate ?? DateTime.now();
    _endDate = med?.endDate;
    _selectedWeekdays = med?.weekdays != null
        ? List.from(med!.weekdays)
        : [1, 2, 3, 4, 5, 6, 7];
    _selectedMemberId =
        med?.familyMemberId ??
        (appState.activeProfile?.id ??
            (appState.members.isNotEmpty
                ? appState.members.first.id
                : 'primary_self'));
    _selectedColorHex = med?.colorHex ?? 0xFF087F79;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    _reorderController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveMedicine() {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be before start date'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final med = Medicine(
      id: widget.initialMedicine?.id ?? '',
      name: _nameController.text.trim(),
      strength: _strengthController.text.trim(),
      form: _selectedForm,
      dosage: _dosageController.text.trim(),
      instructions: _selectedInstruction,
      timesPerDay: _scheduledTimes.length,
      scheduledTimes: _scheduledTimes,
      familyMemberId: _selectedMemberId,
      stockCount: int.tryParse(_stockController.text.trim()) ?? 20,
      reorderThreshold: int.tryParse(_reorderController.text.trim()) ?? 5,
      colorHex: _selectedColorHex,
      startDate: _startDate,
      endDate: _endDate,
      weekdays: _selectedWeekdays,
      notes: _notesController.text.trim(),
    );

    ref.read(appStateProvider.notifier).saveMedicine(med);

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = ref.watch(appStateProvider);
    final isEditing = widget.initialMedicine != null;

    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? (loc?.translate('editMedicine') ?? 'Edit Medicine')
              : (loc?.translate('addMedicine') ?? 'Add Medicine'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText:
                        '${loc?.translate('medNameLabel') ?? "Medicine Name"} *',
                    hintText:
                        loc?.translate('medNameHint') ?? 'e.g. Napa Extra',
                    prefixIcon: const Icon(Icons.medication_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Medicine name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _strengthController,
                  decoration: const InputDecoration(
                    labelText: 'Strength (Optional)',
                    hintText: 'e.g. 500 mg / 10 ml',
                    prefixIcon: Icon(Icons.fitness_center_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  loc?.translate('medFormLabel') ?? 'Form / Type',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MedicineForm.values.map((form) {
                    final isSelected = _selectedForm == form;
                    return ChoiceChip(
                      avatar: Icon(
                        _getFormIcon(form),
                        size: 18,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      label: Text(_getFormText(form, loc)),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      onSelected: (_) => setState(() => _selectedForm = form),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _dosageController,
                  decoration: InputDecoration(
                    labelText:
                        loc?.translate('medDoseLabel') ?? 'Dosage Instructions',
                    hintText: loc?.translate('medDoseHint') ?? 'e.g. 1 Tablet',
                    prefixIcon: const Icon(Icons.medical_information_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter dosage instructions';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  loc?.translate('instructionsLabel') ?? 'Meal Instructions',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MealInstruction.values.map((inst) {
                    final isSelected = _selectedInstruction == inst;
                    return ChoiceChip(
                      label: Text(_getInstructionText(inst, loc)),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      onSelected: (_) =>
                          setState(() => _selectedInstruction = inst),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Start Date',
                          style: TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy').format(_startDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.calendar_month_rounded),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'End Date (Optional)',
                          style: TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          _endDate != null
                              ? DateFormat('dd MMM yyyy').format(_endDate!)
                              : 'Ongoing',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.event_busy_rounded),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                _endDate ??
                                _startDate.add(const Duration(days: 7)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _endDate = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Reminder Times',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 12, minute: 0),
                        );
                        if (time != null) {
                          setState(() {
                            _scheduledTimes.add(time);
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.access_time_filled_rounded,
                        size: 18,
                      ),
                      label: const Text('Add Time'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _scheduledTimes.map((time) {
                    return Chip(
                      label: Text(time.format(context)),
                      onDeleted: _scheduledTimes.length > 1
                          ? () {
                              setState(() {
                                _scheduledTimes.remove(time);
                              });
                            }
                          : null,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Schedule Days',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: List.generate(7, (idx) {
                    final dayNum = idx + 1;
                    final isSelected = _selectedWeekdays.contains(dayNum);
                    return FilterChip(
                      label: Text(weekdayNames[idx]),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedWeekdays.add(dayNum);
                          } else if (_selectedWeekdays.length > 1) {
                            _selectedWeekdays.remove(dayNum);
                          }
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 20),
                if (appState.members.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value:
                        appState.members.any((m) => m.id == _selectedMemberId)
                        ? _selectedMemberId
                        : appState.members.first.id,
                    decoration: InputDecoration(
                      labelText:
                          loc?.translate('assignToMember') ?? 'Family Member',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                    items: appState.members.map((m) {
                      return DropdownMenuItem(value: m.id, child: Text(m.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMemberId = val);
                    },
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText:
                              loc?.translate('stockQuantity') ?? 'Stock Count',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _reorderController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText:
                              loc?.translate('reorderAlertAt') ??
                              'Alert Threshold',
                          prefixIcon: const Icon(Icons.warning_amber_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Special Instructions (Optional)',
                    hintText: 'e.g. Take with warm water after meals',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveMedicine,
                  child: Text(
                    isEditing
                        ? (loc?.translate('updateMedicine') ??
                              'Update Medicine')
                        : (loc?.translate('saveMedicine') ?? 'Save Medicine'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFormIcon(MedicineForm form) {
    switch (form) {
      case MedicineForm.tablet:
        return Icons.medication_rounded;
      case MedicineForm.capsule:
        return Icons.medical_services_rounded;
      case MedicineForm.liquid:
      case MedicineForm.syrup:
        return Icons.water_drop_rounded;
      case MedicineForm.injection:
        return Icons.vaccines_rounded;
      case MedicineForm.drops:
        return Icons.opacity_rounded;
      case MedicineForm.ointment:
        return Icons.sanitizer_rounded;
      default:
        return Icons.healing_rounded;
    }
  }

  String _getFormText(MedicineForm form, AppLocalizations? loc) {
    switch (form) {
      case MedicineForm.tablet:
        return loc?.translate('tablet') ?? 'Tablet';
      case MedicineForm.capsule:
        return loc?.translate('capsule') ?? 'Capsule';
      case MedicineForm.liquid:
      case MedicineForm.syrup:
        return loc?.translate('syrup') ?? 'Liquid / Syrup';
      case MedicineForm.injection:
        return loc?.translate('injection') ?? 'Injection';
      case MedicineForm.drops:
        return loc?.translate('drops') ?? 'Drops';
      case MedicineForm.ointment:
        return loc?.translate('ointment') ?? 'Ointment';
      default:
        return loc?.translate('other') ?? 'Other';
    }
  }

  String _getInstructionText(MealInstruction inst, AppLocalizations? loc) {
    switch (inst) {
      case MealInstruction.beforeFood:
        return loc?.translate('beforeFood') ?? 'Before Food';
      case MealInstruction.afterFood:
        return loc?.translate('afterFood') ?? 'After Food';
      case MealInstruction.withFood:
        return loc?.translate('withFood') ?? 'With Food';
      case MealInstruction.anytime:
        return loc?.translate('anytime') ?? 'Any Time';
    }
  }
}
