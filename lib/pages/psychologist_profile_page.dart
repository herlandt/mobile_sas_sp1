// lib/pages/psychologist_profile_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PsychologistProfilePage extends StatefulWidget {
  const PsychologistProfilePage({super.key});

  @override
  State<PsychologistProfilePage> createState() => _PsychologistProfilePageState();
}

class _PsychologistProfilePageState extends State<PsychologistProfilePage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final _licenseController = TextEditingController();
  final _bioController = TextEditingController();
  final _educationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profileData = await _apiService.getMyProfessionalProfile();
    if (profileData != null && mounted) {
      setState(() {
        _licenseController.text = profileData['license_number'] ?? '';
        _bioController.text = profileData['bio'] ?? '';
        _educationController.text = profileData['education'] ?? '';
        _experienceController.text = (profileData['experience_years'] ?? 0).toString();
        _feeController.text = (profileData['consultation_fee'] ?? '0.0').toString();
        _isLoading = false;
      });
    } else {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final dataToUpdate = {
        'license_number': _licenseController.text,
        'bio': _bioController.text,
        'education': _educationController.text,
        'experience_years': int.tryParse(_experienceController.text) ?? 0,
        'consultation_fee': double.tryParse(_feeController.text) ?? 0.0,
      };

      final success = await _apiService.updateProfessionalProfile(dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Perfil guardado con éxito' : 'No se pudo guardar el perfil'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil Profesional'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _licenseController,
                      decoration: const InputDecoration(labelText: 'Número de Licencia'),
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Biografía (Acerca de mí)'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _educationController,
                      decoration: const InputDecoration(labelText: 'Educación'),
                       maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _experienceController,
                      decoration: const InputDecoration(labelText: 'Años de Experiencia'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _feeController,
                      decoration: const InputDecoration(labelText: 'Tarifa por Sesión (Bs.)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Guardar Cambios'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    // ... dispose all controllers
    _licenseController.dispose();
    _bioController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    super.dispose();
  }
}