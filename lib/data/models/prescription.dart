class Prescription {
  final String id;
  final String title;
  final String doctorName;
  final String hospitalName;
  final DateTime date;
  final String familyMemberId;
  final String notes;
  final List<String> tags;
  final String? imageUrl;

  const Prescription({
    required this.id,
    required this.title,
    required this.doctorName,
    required this.hospitalName,
    required this.date,
    required this.familyMemberId,
    required this.notes,
    this.tags = const [],
    this.imageUrl,
  });

  Prescription copyWith({
    String? id,
    String? title,
    String? doctorName,
    String? hospitalName,
    DateTime? date,
    String? familyMemberId,
    String? notes,
    List<String>? tags,
    String? imageUrl,
  }) {
    return Prescription(
      id: id ?? this.id,
      title: title ?? this.title,
      doctorName: doctorName ?? this.doctorName,
      hospitalName: hospitalName ?? this.hospitalName,
      date: date ?? this.date,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
