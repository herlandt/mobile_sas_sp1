// lib/pages/patient_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../models/appointment_model.dart'; // Importamos el modelo de citas
import 'package:url_launcher/url_launcher.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  final ApiService _apiService = ApiService();
  String _userName = 'Cargando...';
  late Future<List<Appointment>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Cargamos tanto el perfil como las citas al iniciar
  void _loadInitialData() {
    _apiService.getUserProfile().then((profile) {
      if (profile != null && mounted) {
        setState(() {
          _userName = profile['first_name'] ?? 'Paciente';
        });
      }
    });
    _appointmentsFuture = _apiService.getMyAppointments();
  }

  // Función para refrescar la lista
  void _refreshAppointments() {
    setState(() {
      _appointmentsFuture = _apiService.getMyAppointments();
    });
  }

  // Helper para cerrar sesión
  Future<void> _logout() async {
    await _apiService.logout();
    if (mounted) context.go('/login');
  }

  // --- ESTE ES EL MÉTODO 'BUILD' QUE FALTABA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, $_userName'),
        actions: [
          // Botón de Perfil
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mi Perfil',
            onPressed: () {
              // Navegamos a la nueva ruta
              context.go('/patient-profile');
            },
          ),
          // Botón de Logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshAppointments();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mis Próximas Citas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Appointment>>(
                future: _appointmentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error al cargar las citas: ${snapshot.error}'));
                  }
                  return _buildAppointmentsList(snapshot.data ?? []);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/professionals');
        },
        label: const Text('Agendar Nueva Cita'),
        icon: const Icon(Icons.add),
      ),
    );
  }
  // --- FIN DEL MÉTODO BUILD ---


  // Esta es tu función para construir la lista (la tenías correcta en el log)
  Widget _buildAppointmentsList(List<Appointment> appointments) {
    if (appointments.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('No tienes citas agendadas.',
                  style: TextStyle(fontSize: 16, color: Colors.grey))));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        Widget trailingWidget;

        if (appointment.status == 'Pendiente') {
          trailingWidget = ElevatedButton(
            onPressed: () async {
              final success =
                  await _apiService.confirmAppointment(appointment.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Has confirmado tu asistencia'
                        : 'No se pudo confirmar'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                if (success) _refreshAppointments();
              }
            },
            child: const Text('Confirmar'),
          );
        } else if (appointment.status == 'Confirmada') {
          bool hasLink = appointment.meetingLink != null &&
              appointment.meetingLink!.isNotEmpty;
          if (hasLink) {
            trailingWidget = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.videocam, color: Colors.green),
                  tooltip: 'Abrir videollamada',
                  onPressed: () async {
                    final Uri url = Uri.parse(appointment.meetingLink!);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    } else {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'No se pudo abrir el link: ${appointment.meetingLink}')),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  tooltip: 'Ir al chat',
                  onPressed: () {
                    context.go('/chat/${appointment.id}');
                  },
                ),
              ],
            );
          } else {
            trailingWidget = const Chip(label: Text('Esperando Link'));
          }
        } else {
          trailingWidget = Chip(label: Text(appointment.status));
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.calendar_today_outlined,
                color: Colors.blueAccent),
            title: Text('Cita con ${appointment.psychologistName}'),
            subtitle: Text(
                '${appointment.appointmentDate} a las ${appointment.startTime}'),
            trailing: trailingWidget,
          ),
        );
      },
    );
  }
}