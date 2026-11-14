import 'package:flutter/material.dart';

enum MedicineForm {
  tablet,
  syrup,
  capsule,
  liquid,
  injection,
  drops,
  ointment,
  other,
}

enum MealInstruction { beforeFood, afterFood, withFood, anytime }

class Medicine {
  final String id;
  final String name;
  final String strength;
  final MedicineForm form;
  final String dosage;
  final MealInstruction instructions;
  final int timesPerDay;
  final List<TimeOfDay> scheduledTimes;
  final String familyMemberId;
  final int stockCount;
  final int reorderThreshold;
  final bool isActive;
  final bool isPaused;
  final int colorHex;
  final DateTime startDate;
  final DateTime? endDate;
  final List<int> weekdays;
  final String notes;

  const Medicine({
    required this.id,
    required this.name,
    this.strength = '',
    required this.form,
    required this.dosage,
    required this.instructions,
    required this.timesPerDay,
    required this.scheduledTimes,
    required this.familyMemberId,
    required this.stockCount,
    this.reorderThreshold = 5,
    this.isActive = true,
    this.isPaused = false,
    this.colorHex = 0xFF087F79,
    required this.startDate,
    this.endDate,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.notes = '',
  });

  bool get isLowStock => stockCount <= reorderThreshold;

  Medicine copyWith({
    String? id,
    String? name,
    String? strength,
    MedicineForm? form,
    String? dosage,
    MealInstruction? instructions,
    int? timesPerDay,
    List<TimeOfDay>? scheduledTimes,
    String? familyMemberId,
    int? stockCount,
    int? reorderThreshold,
    bool? isActive,
    bool? isPaused,
    int? colorHex,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? weekdays,
    String? notes,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      strength: strength ?? this.strength,
      form: form ?? this.form,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      stockCount: stockCount ?? this.stockCount,
      reorderThreshold: reorderThreshold ?? this.reorderThreshold,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      colorHex: colorHex ?? this.colorHex,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      weekdays: weekdays ?? this.weekdays,
      notes: notes ?? this.notes,
    );
  }
}
