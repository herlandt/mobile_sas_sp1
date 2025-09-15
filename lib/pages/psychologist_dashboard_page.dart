import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../models/appointment_model.dart';

class PsychologistDashboardPage extends StatefulWidget {
  const PsychologistDashboardPage({super.key});

  @override
  State<PsychologistDashboardPage> createState() => _PsychologistDashboardPageState();
}

class _PsychologistDashboardPageState extends State<PsychologistDashboardPage> {
  final ApiService _apiService = ApiService();
  String _userName = 'Cargando...';
  late Future<List<Appointment>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _apiService.getUserProfile().then((profile) {
      if (profile != null && mounted) {
        setState(() {
          _userName = profile['first_name'] ?? 'Psicólogo';
        });
      }
    });
    _appointmentsFuture = _apiService.getMyAppointments();
  }

  void _refreshAppointments() {
    setState(() {
      _appointmentsFuture = _apiService.getMyAppointments();
    });
  }

  // --- WIDGET DE LA LISTA DE CITAS (MODIFICADO) ---
  Widget _buildAppointmentsList(List<Appointment> appointments) {
    if (appointments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No tienes citas pendientes.', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }
    
    final confirmedAppointments = appointments.where((a) => a.status == 'Confirmada').toList();
    final otherAppointments = appointments.where((a) => a.status != 'Confirmada').toList();
    final sortedAppointments = [...confirmedAppointments, ...otherAppointments];

    return ListView.builder(
      itemCount: sortedAppointments.length,
      itemBuilder: (context, index) {
        final appointment = sortedAppointments[index];
        bool isConfirmed = appointment.status == 'Confirmada';
        // --- LÍNEA AÑADIDA PARA VERIFICAR SI HAY LINK ---
        bool hasLink = appointment.meetingLink != null && appointment.meetingLink!.isNotEmpty;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(
              isConfirmed ? Icons.check_circle_outline : Icons.pending_actions_outlined,
              color: isConfirmed ? Colors.green : Colors.orangeAccent,
            ),
            title: Text('Cita con ${appointment.patientName}'),
            subtitle: Text('${appointment.appointmentDate} a las ${appointment.startTime}'),
            trailing: isConfirmed
                ? ElevatedButton(
                    // --- LÓGICA MODIFICADA ---
                    onPressed: () => _showAddLinkDialog(appointment),
                    child: Text(hasLink ? 'Editar Link' : 'Añadir Link'),
                  )
                : Chip(label: Text(appointment.status)),
          ),
        );
      },
    );
  }

  // --- FUNCIÓN DEL DIÁLOGO (MODIFICADA) ---
  void _showAddLinkDialog(Appointment appointment) {
    // El controlador ahora empieza con el valor del link existente
    final TextEditingController linkController = TextEditingController(text: appointment.meetingLink);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir o Editar Link'),
          content: TextField(
            controller: linkController,
            decoration: const InputDecoration(hintText: "https://meet.google.com/..."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (linkController.text.isNotEmpty) {
                  final success = await _apiService.addMeetingLink(appointment.id, linkController.text);
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Link guardado' : 'No se pudo guardar el link'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                    if (success) _refreshAppointments();
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... El resto del build no cambia ...
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, Dr. $_userName'),
        actions: [
           TextButton(
            onPressed: () => context.go('/psychologist-profile'),
            child: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
          ),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Tus Citas Agendadas',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Appointment>>(
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
          ),
        ],
      ),
    );
  }
}