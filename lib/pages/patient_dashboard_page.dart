// lib/pages/patient_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../models/appointment_model.dart'; // Importamos el modelo de citas
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

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

  // --- FUNCIÓN AÑADIDA PARA REFRESCAR LA LISTA ---
  void _refreshAppointments() {
    setState(() {
      _appointmentsFuture = _apiService.getMyAppointments();
    });
  }

  // --- FUNCIÓN MODIFICADA PARA CONSTRUIR LA LISTA DE CITAS ---// lib/pages/patient_dashboard_page.dart

  Widget _buildAppointmentsList(List<Appointment> appointments) {
    if (appointments.isEmpty) {
      // ... (sin cambios)
      return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No tienes citas agendadas.', style: TextStyle(fontSize: 16, color: Colors.grey))));
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
              final success = await _apiService.confirmAppointment(appointment.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Has confirmado tu asistencia' : 'No se pudo confirmar'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                if (success) _refreshAppointments();
              }
            },
            child: const Text('Confirmar'),
          );
        } else if (appointment.status == 'Confirmada') {
          bool hasLink = appointment.meetingLink != null && appointment.meetingLink!.isNotEmpty;
          if (hasLink) {
            // --- LÓGICA MODIFICADA PARA LOS BOTONES ---
            trailingWidget = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón para abrir el link de la videollamada
                IconButton(
                  icon: const Icon(Icons.videocam, color: Colors.green),
                  tooltip: 'Abrir videollamada',
                  onPressed: () async {
                    final Uri url = Uri.parse(appointment.meetingLink!);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No se pudo abrir el link: ${appointment.meetingLink}')),
                      );
                    }
                  },
                ),
                // Botón para ir al chat
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  tooltip: 'Ir al chat',
                  onPressed: () {
                    // TODO: Aquí irá la navegación a tu pantalla de chat
                    
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
            leading: const Icon(Icons.calendar_today_outlined, color: Colors.blueAccent),
            title: Text('Cita con ${appointment.psychologistName}'),
            subtitle: Text('${appointment.appointmentDate} a las ${appointment.startTime}'),
            trailing: trailingWidget,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, $_userName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await _apiService.logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dashboard del Paciente',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.go('/professionals');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Buscar Nuevos Psicólogos'),
            ),
            const Divider(height: 40),
            Text(
              'Mis Próximas Citas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Appointment>>(
              future: _appointmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar las citas.'));
                }
                return _buildAppointmentsList(snapshot.data ?? []);
              },
            ),
          ],
        ),
      ),
    );
  }
}