// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/professional_model.dart';
import '../models/schedule_model.dart';
import '../models/appointment_model.dart';

class ApiService {
  final String _baseUrl = "http://10.0.2.2:8000/api";
  final _storage = const FlutterSecureStorage();

  // --- OBTENER TOKEN (LA FUNCIÓN QUE FALTABA) ---
  Future<String?> getToken() async {
    return await _storage.read(key: 'authToken');
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Token no encontrado.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Token $token',
    };
  }

  Future<String?> login(String email, String password) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/login/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        await _storage.write(key: 'authToken', value: data['token']);
        await _storage.write(key: 'userType', value: data['user']['user_type']);
        return data['user']['user_type'];
      }
    } catch (e) {
      print('Excepción en el login: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final url = Uri.parse('$_baseUrl/auth/profile/');
      final headers = await getAuthHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print('Excepción al obtener perfil: $e');
    }
    return null;
  }

  Future<List<Professional>> getProfessionals() async {
    try {
      final url = Uri.parse('$_baseUrl/professionals/');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> professionalList = data['professionals'];
        return professionalList
            .map((json) => Professional.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Excepción al obtener profesionales: $e');
    }
    return [];
  }

  Future<Professional?> getProfessionalDetails(int professionalId) async {
    try {
      final url = Uri.parse('$_baseUrl/professionals/$professionalId/');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Professional.fromJson(data);
      }
    } catch (e) {
      print('Excepción al obtener detalle del profesional: $e');
    }
    return null;
  }

  Future<List<DaySchedule>> getPsychologistSchedule(int psychologistId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/appointments/psychologist/$psychologistId/schedule/',
      );
      final headers = await getAuthHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> scheduleList = data['schedule'];
        return scheduleList
            .map((dayJson) => DaySchedule.fromJson(dayJson))
            .toList();
      }
    } catch (e) {
      print('Excepción al obtener el horario: $e');
    }
    return [];
  }

  Future<bool> bookAppointment({
    required int psychologistUserId,
    required String date,
    required String startTime,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/appointments/appointments/');
      final headers = await getAuthHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'psychologist': psychologistUserId,
          'appointment_date': date,
          'start_time': startTime,
          'appointment_type': 'online',
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Excepción al agendar cita: $e');
    }
    return false;
  }

  Future<List<Appointment>> getMyAppointments() async {
    try {
      final url = Uri.parse('$_baseUrl/appointments/appointments/');
      final headers = await getAuthHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        final List<dynamic> results = data['results'];
        return results.map((json) => Appointment.fromJson(json)).toList();
      }
    } catch (e) {
      print('Excepción al obtener mis citas: $e');
    }
    return [];
  }

  Future<bool> confirmAppointment(int appointmentId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/appointments/appointments/$appointmentId/',
      );
      final headers = await getAuthHeaders();
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode({'status': 'confirmed'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Excepción al confirmar cita: $e');
    }
    return false;
  }

  Future<bool> addMeetingLink(int appointmentId, String meetingLink) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/appointments/appointments/$appointmentId/',
      );
      final headers = await getAuthHeaders();
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode({'meeting_link': meetingLink}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Excepción al añadir link: $e');
    }
    return false;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'authToken');
    await _storage.delete(key: 'userType');
  }

  // lib/services/api_service.dart

// ... (dentro de la clase ApiService)

  // --- OBTENER PERFIL DEL PSICÓLOGO LOGUEADO (NUEVA FUNCIÓN) ---
  Future<Map<String, dynamic>?> getMyProfessionalProfile() async {
    try {
      // El backend ya sabe qué usuario está logueado por el token
      final url = Uri.parse('$_baseUrl/professionals/profile/');
      final headers = await getAuthHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print('Error al obtener perfil profesional: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Excepción al obtener perfil profesional: $e');
      return null;
    }
  }

  // --- ACTUALIZAR PERFIL DEL PSICÓLOGO (NUEVA FUNCIÓN) ---
  Future<bool> updateProfessionalProfile(Map<String, dynamic> profileData) async {
    try {
      final url = Uri.parse('$_baseUrl/professionals/profile/');
      final headers = await getAuthHeaders();
      
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        print('Perfil profesional actualizado.');
        return true;
      } else {
        print('Error al actualizar perfil profesional: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción al actualizar perfil profesional: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> register(Map<String, String> userData) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/register/');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) { // 201 Created es el código de éxito
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final token = data['token'];
        final userType = data['user']['user_type'];

        // Guardamos el token y el tipo de usuario para iniciar sesión automáticamente
        await _storage.write(key: 'authToken', value: token);
        await _storage.write(key: 'userType', value: userType);
        
        print('Registro exitoso. Usuario logueado.');
        return {'token': token, 'userType': userType};
      } else {
        print('Error en el registro: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Excepción en el registro: $e');
      return null;
    }
  }
}
