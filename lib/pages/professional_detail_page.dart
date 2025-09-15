import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/professional_model.dart';
import 'package:go_router/go_router.dart';
class ProfessionalDetailPage extends StatefulWidget {
  final String professionalId; // Recibimos el ID como un String desde la ruta

  const ProfessionalDetailPage({super.key, required this.professionalId});

  @override
  State<ProfessionalDetailPage> createState() => _ProfessionalDetailPageState();
}

class _ProfessionalDetailPageState extends State<ProfessionalDetailPage> {
  final ApiService _apiService = ApiService();
  late Future<Professional?> _professionalFuture;

  @override
  void initState() {
    super.initState();
    // Convertimos el ID a entero y cargamos los datos
    final int id = int.tryParse(widget.professionalId) ?? 0;
    _professionalFuture = _apiService.getProfessionalDetails(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Profesional'),
      ),
      body: FutureBuilder<Professional?>(
        future: _professionalFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No se pudo cargar el perfil.'));
          }

          final professional = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con Nombre y Rating
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      child: Text(professional.fullName[0], style: const TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(professional.fullName, style: Theme.of(context).textTheme.headlineSmall),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              Text(professional.averageRating.toStringAsFixed(1), style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Biografía
                Text('Acerca de mí', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(professional.bio, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),

                // Especialidades
                Text('Especialidades', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: professional.specializations.map((spec) => Chip(label: Text(spec.name))).toList(),
                ),
                const SizedBox(height: 24),

                // Información Adicional
                ListTile(
                  leading: const Icon(Icons.work_history_outlined),
                  title: Text('${professional.experienceYears} años de experiencia'),
                ),
                ListTile(
                  leading: const Icon(Icons.monetization_on_outlined),
                  title: Text('Costo por sesión: \$${professional.consultationFee.toStringAsFixed(2)}'),
                ),
                const SizedBox(height: 32),
                
                // Botón para agendar cita
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navegamos a la pantalla de agendar cita
                      // Pasamos el nombre del profesional como un 'extra'
                     // LÍNEA CORRECTA
                      context.go(
                        '/professionals/${professional.profileId}/schedule',
                        extra: professional.fullName,
                      );
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                    child: const Text('Agendar una Cita'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}