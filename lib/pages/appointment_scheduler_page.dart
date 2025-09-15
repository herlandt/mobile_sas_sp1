import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // <--- LA LÍNEA QUE FALTABA
import '../services/api_service.dart';
import '../models/schedule_model.dart';

class AppointmentSchedulerPage extends StatefulWidget {
  final String professionalId;
  final String professionalName;

  const AppointmentSchedulerPage({
    super.key,
    required this.professionalId,
    required this.professionalName,
  });

  @override
  State<AppointmentSchedulerPage> createState() => _AppointmentSchedulerPageState();
}

class _AppointmentSchedulerPageState extends State<AppointmentSchedulerPage> {
  final ApiService _apiService = ApiService();
  late Future<List<DaySchedule>> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    final int id = int.tryParse(widget.professionalId) ?? 0;
    _scheduleFuture = _apiService.getPsychologistSchedule(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agendar con ${widget.professionalName}'),
      ),
      body: FutureBuilder<List<DaySchedule>>(
        future: _scheduleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se pudo cargar el horario.'));
          }

          final weeklySchedule = snapshot.data!;
          return ListView.builder(
            itemCount: weeklySchedule.length,
            itemBuilder: (context, index) {
              final day = weeklySchedule[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${day.dayName}, ${day.date}', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      if (day.isBlocked)
                        const Text('Día bloqueado por el profesional', style: TextStyle(color: Colors.red)),
                      if (!day.isAvailable && !day.isBlocked)
                        const Text('No hay horario disponible este día'),
                      if (day.isAvailable && !day.isBlocked)
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: day.timeSlots.map((slot) {
                            return ActionChip(
                              label: Text(slot.startTime),
                              backgroundColor: slot.isAvailable ? Colors.green[100] : Colors.grey[300],
                              // lib/pages/appointment_scheduler_page.dart

// ... (dentro del onPressed del ActionChip)
onPressed: slot.isAvailable
    ? () async {
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            // ... (el AlertDialog no cambia)
            return AlertDialog(
              title: const Text('Confirmar Cita'),
              content: Text('¿Deseas agendar una cita para el ${day.date} a las ${slot.startTime}?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Confirmar'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );

        if (confirmed == true) {
          // --- AQUÍ ESTÁ EL CAMBIO IMPORTANTE ---
          // Buscamos el ID del perfil en la lista para obtener su userId
          final professionalData = weeklySchedule
              .expand((day) => day.timeSlots)
              .isNotEmpty
              ? await _apiService.getProfessionalDetails(int.parse(widget.professionalId))
              : null;
          
          if (professionalData != null) {
              final success = await _apiService.bookAppointment(
                psychologistUserId: professionalData.userId, // <-- USAMOS EL ID DE USUARIO
                date: day.date,
                startTime: slot.startTime,
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '¡Cita agendada con éxito!' : 'Error: El horario ya no está disponible.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                if (success) {
                  context.pop();
                }
              }
          } else {
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al obtener datos del profesional.')),
                );
             }
          }
        }
      }
    : null,
// ...
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}