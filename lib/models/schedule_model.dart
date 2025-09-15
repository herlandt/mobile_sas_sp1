// lib/models/schedule_model.dart

// Representa un único bloque de tiempo (ej: 09:00 - 10:00)
class TimeSlot {
  final String startTime;
  final String endTime;
  final bool isAvailable;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      isAvailable: json['is_available'] ?? false,
    );
  }
}

// Representa la agenda completa para un día
class DaySchedule {
  final String date;
  final String dayName;
  final bool isAvailable;
  final bool isBlocked;
  final List<TimeSlot> timeSlots;

  DaySchedule({
    required this.date,
    required this.dayName,
    required this.isAvailable,
    required this.isBlocked,
    required this.timeSlots,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    var slotsList = (json['time_slots'] as List<dynamic>?)
            ?.map((slotJson) => TimeSlot.fromJson(slotJson))
            .toList() ??
        [];

    return DaySchedule(
      date: json['date'] ?? '',
      dayName: json['day_name'] ?? 'Día',
      isAvailable: json['is_available'] ?? false,
      isBlocked: json['blocked'] ?? false,
      timeSlots: slotsList,
    );
  }
}