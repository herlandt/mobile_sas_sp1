// lib/models/professional_model.dart

class Specialization {
  // ... (sin cambios aquí)
  final int id;
  final String name;
  Specialization({required this.id, required this.name});
  factory Specialization.fromJson(Map<String, dynamic> json) {
    return Specialization(id: json['id'] ?? 0, name: json['name'] ?? 'Sin especialidad');
  }
}

class Professional {
  final int profileId; // Renombrado para claridad
  final int userId;    // <-- NUEVO CAMPO
  final String fullName;
  final String bio;
  final int experienceYears;
  final double averageRating;
  final double consultationFee;
  final List<Specialization> specializations;

  Professional({
    required this.profileId,
    required this.userId, // <-- NUEVO
    required this.fullName,
    required this.bio,
    required this.experienceYears,
    required this.averageRating,
    required this.consultationFee,
    required this.specializations,
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    var specList = (json['specializations'] as List<dynamic>?)
            ?.map((specJson) => Specialization.fromJson(specJson))
            .toList() ?? [];

    return Professional(
      profileId: json['id'] ?? 0,
      userId: json['user_id'] ?? 0, // <-- LEEMOS EL USER_ID DEL JSON
      fullName: json['full_name'] ?? 'Nombre no disponible',
      bio: json['bio'] ?? 'Biografía no disponible.',
      experienceYears: json['experience_years'] ?? 0,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0.0') ?? 0.0,
      consultationFee: double.tryParse(json['consultation_fee']?.toString() ?? '0.0') ?? 0.0,
      specializations: specList,
    );
  }
}