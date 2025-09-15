// lib/models/patient_profile_model.dart
import 'dart:convert';

// Modelo para los datos específicos del paciente (el objeto anidado)
class PatientSpecificProfile {
  String emergencyContactName;
  String emergencyContactPhone;
  String emergencyContactRelationship;
  String occupation;

  PatientSpecificProfile({
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.emergencyContactRelationship,
    required this.occupation,
  });

  factory PatientSpecificProfile.fromJson(Map<String, dynamic> json) {
    return PatientSpecificProfile(
      emergencyContactName: json['emergency_contact_name'] ?? '',
      emergencyContactPhone: json['emergency_contact_phone'] ?? '',
      emergencyContactRelationship: json['emergency_contact_relationship'] ?? '',
      occupation: json['occupation'] ?? '',
    );
  }

  // Helper para convertir nuestro formulario de vuelta a JSON para el API
  Map<String, dynamic> toJson() {
    return {
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relationship': emergencyContactRelationship,
      'occupation': occupation,
    };
  }
}

// Modelo principal que combina User y Patient data
class FullPatientProfile {
  String firstName;
  String lastName;
  String ci;
  String phone;
  String address;
  String dateOfBirth; // Mantenido como String (YYYY-MM-DD) para simplicidad
  PatientSpecificProfile? patientProfile; // Puede ser nulo si nunca se ha creado

  FullPatientProfile({
    required this.firstName,
    required this.lastName,
    required this.ci,
    required this.phone,
    required this.address,
    required this.dateOfBirth,
    this.patientProfile,
  });

  factory FullPatientProfile.fromJson(Map<String, dynamic> json) {
    return FullPatientProfile(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      ci: json['ci'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      // Si 'patient_profile' no es nulo en el JSON, lo parseamos
      patientProfile: json['patient_profile'] != null
          ? PatientSpecificProfile.fromJson(json['patient_profile'])
          : null,
    );
  }

  // Helper para enviar solo los datos del USUARIO (PUT a /users/profile/)
  Map<String, dynamic> userToJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'ci': ci,
      'phone': phone,
      'address': address,
      'date_of_birth': dateOfBirth,
    };
  }
}