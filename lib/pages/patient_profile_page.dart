// lib/pages/patient_profile_page.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/patient_profile_model.dart'; // Asegúrate de que este import esté correcto

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _error = '';
  
  // NUEVA VARIABLE: para rastrear si debemos usar POST o PUT
  bool _hasExistingPatientProfile = false;

  final _formKey = GlobalKey<FormState>(); // Key para el formulario

  // Controladores
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ciController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelController = TextEditingController();
  final _occupationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await _apiService.getPatientProfile();

      // Llenar datos de Usuario
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _ciController.text = profile.ci;
      _phoneController.text = profile.phone;
      _dobController.text = profile.dateOfBirth;
      _addressController.text = profile.address;

      // LÓGICA DE CONTROL (FIX PARA EL 404)
      if (profile.patientProfile != null) {
        // Si el backend devolvió un perfil anidado, significa que ya existe
        setState(() {
          _hasExistingPatientProfile = true; 
        });
        _emergencyNameController.text = profile.patientProfile!.emergencyContactName;
        _emergencyPhoneController.text = profile.patientProfile!.emergencyContactPhone;
        _emergencyRelController.text = profile.patientProfile!.emergencyContactRelationship;
        _occupationController.text = profile.patientProfile!.occupation;
      } else {
         // Si es nulo, el perfil de paciente aún no se ha creado
        setState(() {
          _hasExistingPatientProfile = false;
        });
      }

    } catch (e) {
      setState(() {
        _error = 'Error al cargar el perfil: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // --- FIX PARA ERROR 400 (Fecha) ---
      // Si el texto está vacío, envía null. Si no, envía el texto.
      final dobToSend = _dobController.text.isEmpty ? null : _dobController.text;

      // 1. Preparar y enviar los datos del Usuario
      final userData = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'ci': _ciController.text,
        'phone': _phoneController.text,
        'date_of_birth': dobToSend, // Usamos la variable corregida
        'address': _addressController.text,
      };
      // Esta llamada siempre usa PUT (updatePatientUser)
      await _apiService.updatePatientUser(userData); 

      // 2. Preparar datos del Perfil de Paciente
      final profileData = {
        'emergency_contact_name': _emergencyNameController.text,
        'emergency_contact_phone': _emergencyPhoneController.text,
        'emergency_contact_relationship': _emergencyRelController.text,
        'occupation': _occupationController.text,
      };

      // --- FIX PARA ERROR 404 (Perfil no encontrado) ---
      // Lógica condicional: POST si es nuevo, PUT si ya existe
      if (_hasExistingPatientProfile) {
        // Ya existe, usamos PUT para actualizar
        await _apiService.updatePatientProfile(profileData);
      } else {
        // No existe, usamos POST para crear
        await _apiService.createPatientProfile(profileData);
        // Marcamos que ya existe para la próxima vez que guarde
        setState(() {
          _hasExistingPatientProfile = true;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('¡Perfil guardado exitosamente!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() {
        _error = 'Error al guardar: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Limpiar todos los controladores
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ciController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Mi Perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (_error.isNotEmpty)
                    Text(_error, style: const TextStyle(color: Colors.red, fontSize: 16)),
                  
                  const Text('Información Personal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildTextField(_firstNameController, 'Nombre'),
                  _buildTextField(_lastNameController, 'Apellido'),
                  _buildTextField(_ciController, 'CI'),
                  _buildTextField(_phoneController, 'Teléfono'),
                  _buildTextField(_dobController, 'Fecha de Nacimiento (YYYY-MM-DD)'),
                  _buildTextField(_addressController, 'Dirección'),
                  
                  const SizedBox(height: 24),
                  const Text('Perfil Adicional (Paciente)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildTextField(_emergencyNameController, 'Contacto de Emergencia (Nombre)'),
                  _buildTextField(_emergencyPhoneController, 'Contacto de Emergencia (Teléfono)'),
                  _buildTextField(_emergencyRelController, 'Contacto de Emergencia (Parentesco)'),
                  _buildTextField(_occupationController, 'Ocupación'),
                  
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}