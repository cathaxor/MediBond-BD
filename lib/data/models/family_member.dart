import 'dart:convert';

import 'package:flutter/material.dart';

class FamilyMember {
  final String id;
  final String name;
  final String relationship;
  final String relationshipBn;
  final int age;
  final int? birthYear;
  final DateTime? dateOfBirth;
  final String? gender;
  final String bloodGroup;
  final double? heightCm;
  final double? weightKg;
  final String? allergies;
  final String emergencyContact;
  final String? emergencyName;
  final String? emergencyRelationship;
  final String medicalNotes;
  final String avatarInitials;
  final int avatarColorValue;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    required this.relationshipBn,
    required this.age,
    this.birthYear,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup = 'Not Set',
    this.heightCm,
    this.weightKg,
    this.allergies,
    required this.emergencyContact,
    this.emergencyName,
    this.emergencyRelationship,
    this.medicalNotes = '',
    required this.avatarInitials,
    required this.avatarColorValue,
  });

  Color get avatarColor => Color(avatarColorValue);

  int get calculatedAge {
    if (dateOfBirth != null) {
      final now = DateTime.now();
      int yrs = now.year - dateOfBirth!.year;
      if (now.month < dateOfBirth!.month ||
          (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
        yrs--;
      }
      return yrs >= 0 ? yrs : 0;
    }
    if (birthYear != null && birthYear! > 1900) {
      return DateTime.now().year - birthYear!;
    }
    return age;
  }

  String get displayBloodGroup =>
      bloodGroup.isEmpty || bloodGroup == 'Not Set' ? 'Not Set' : bloodGroup;

  String get displayGender =>
      gender == null || gender!.isEmpty ? 'Not Set' : gender!;

  String get displayHeight => heightCm == null || heightCm == 0
      ? 'Not Set'
      : '${heightCm!.toStringAsFixed(0)} cm';

  String get displayWeight => weightKg == null || weightKg == 0
      ? 'Not Set'
      : '${weightKg!.toStringAsFixed(1)} kg';

  String get displayAllergies =>
      allergies == null || allergies!.trim().isEmpty ? 'Not Set' : allergies!;

  String get displayMedicalNotes =>
      medicalNotes.trim().isEmpty ? 'Not Set' : medicalNotes;

  String get displayEmergencyContact {
    if (emergencyContact.trim().isEmpty &&
        (emergencyName == null || emergencyName!.trim().isEmpty)) {
      return 'Not Set';
    }
    final buffer = StringBuffer();
    if (emergencyName != null && emergencyName!.trim().isNotEmpty) {
      buffer.write(emergencyName!.trim());
      if (emergencyRelationship != null &&
          emergencyRelationship!.trim().isNotEmpty) {
        buffer.write(' (${emergencyRelationship!.trim()})');
      }
      if (emergencyContact.trim().isNotEmpty) {
        buffer.write(': ${emergencyContact.trim()}');
      }
    } else {
      buffer.write(emergencyContact.trim());
    }
    return buffer.toString();
  }

  String encodeMedicalNotesPayload() {
    final map = <String, dynamic>{
      'notes': medicalNotes,
      if (gender != null) 'gender': gender,
      if (heightCm != null) 'heightCm': heightCm,
      if (weightKg != null) 'weightKg': weightKg,
      if (allergies != null) 'allergies': allergies,
      if (emergencyName != null) 'emergencyName': emergencyName,
      if (emergencyRelationship != null)
        'emergencyRelationship': emergencyRelationship,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
    };
    return jsonEncode(map);
  }

  static FamilyMember fromParsedData({
    required String id,
    required String name,
    required String relationship,
    required String relationshipBn,
    required int age,
    int? birthYear,
    required String bloodGroup,
    required String avatarInitials,
    required int avatarColorValue,
    required String emergencyContact,
    required String decryptedPayload,
  }) {
    String notes = decryptedPayload;
    String? genderVal;
    double? heightVal;
    double? weightVal;
    String? allergiesVal;
    String? emNameVal;
    String? emRelVal;
    DateTime? dobVal;

    final trimmed = decryptedPayload.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final map = jsonDecode(trimmed) as Map<String, dynamic>;
        notes = map['notes']?.toString() ?? '';
        genderVal = map['gender']?.toString();
        heightVal = (map['heightCm'] as num?)?.toDouble();
        weightVal = (map['weightKg'] as num?)?.toDouble();
        allergiesVal = map['allergies']?.toString();
        emNameVal = map['emergencyName']?.toString();
        emRelVal = map['emergencyRelationship']?.toString();
        if (map['dateOfBirth'] != null) {
          dobVal = DateTime.tryParse(map['dateOfBirth'].toString());
        }
      } catch (_) {
        notes = decryptedPayload;
      }
    }

    return FamilyMember(
      id: id,
      name: name,
      relationship: relationship,
      relationshipBn: relationshipBn,
      age: age,
      birthYear: birthYear,
      dateOfBirth: dobVal,
      gender: genderVal,
      bloodGroup: bloodGroup,
      heightCm: heightVal,
      weightKg: weightVal,
      allergies: allergiesVal,
      emergencyContact: emergencyContact,
      emergencyName: emNameVal,
      emergencyRelationship: emRelVal,
      medicalNotes: notes,
      avatarInitials: avatarInitials,
      avatarColorValue: avatarColorValue,
    );
  }

  FamilyMember copyWith({
    String? id,
    String? name,
    String? relationship,
    String? relationshipBn,
    int? age,
    int? birthYear,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    double? heightCm,
    double? weightKg,
    String? allergies,
    String? emergencyContact,
    String? emergencyName,
    String? emergencyRelationship,
    String? medicalNotes,
    String? avatarInitials,
    int? avatarColorValue,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      relationshipBn: relationshipBn ?? this.relationshipBn,
      age: age ?? this.age,
      birthYear: birthYear ?? this.birthYear,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      allergies: allergies ?? this.allergies,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyName: emergencyName ?? this.emergencyName,
      emergencyRelationship:
          emergencyRelationship ?? this.emergencyRelationship,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
    );
  }
}
