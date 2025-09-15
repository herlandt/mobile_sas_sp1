// lib/models/appointment_model.dart

class Appointment {
  final int id;
  final String psychologistName;
  final String patientName; // <-- NUEVO CAMPO
  final String appointmentDate;
  final String startTime;
    final String? meetingLink; 
  final String status;

  Appointment({
    required this.id,
    required this.psychologistName,
    required this.patientName, // <-- NUEVO
    required this.appointmentDate,
    required this.startTime,
    this.meetingLink, 
    required this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? 0,
      psychologistName: json['psychologist_name'] ?? 'N/A',
      patientName: json['patient_name'] ?? 'N/A', // <-- NUEVO
      appointmentDate: json['appointment_date'] ?? 'Fecha no disponible',
      startTime: json['start_time']?.substring(0, 5) ?? 'Hora no disponible',
      meetingLink: json['meeting_link'],
      status: json['status_display'] ?? 'Estado desconocido',
    );
  }
}