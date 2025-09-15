// lib/pages/professionals_list_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/professional_model.dart';
import 'package:go_router/go_router.dart';
class ProfessionalsListPage extends StatefulWidget {
  const ProfessionalsListPage({super.key});

  @override
  State<ProfessionalsListPage> createState() => _ProfessionalsListPageState();
}

class _ProfessionalsListPageState extends State<ProfessionalsListPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Professional>> _professionalsFuture;

  @override
  void initState() {
    super.initState();
    _professionalsFuture = _apiService.getProfessionals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Psicólogos Disponibles'),
      ),
      body: FutureBuilder<List<Professional>>(
        future: _professionalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se encontraron profesionales.'));
          }

          final professionals = snapshot.data!;
          return ListView.builder(
            itemCount: professionals.length,
            itemBuilder: (context, index) {
              final professional = professionals[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(professional.fullName.isNotEmpty ? professional.fullName[0] : '?'),
                  ),
                  title: Text(professional.fullName),
                  subtitle: Text(
                    professional.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(professional.averageRating.toStringAsFixed(1)),
                    ],
                  ),
                onTap: () {
                    // LÍNEA CORRECTA
                      context.go('/professionals/${professional.profileId}'); 
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}