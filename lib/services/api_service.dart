import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/appointment_model.dart';
import '../models/time_slot_model.dart';
import '../models/user_model.dart';

class ApiService {
  static const String _baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080');

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password,
      {String? phone}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<Map<String, dynamic>> socialLogin(
      String provider, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/social'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'provider': provider, 'token': token}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // Time Slots
  Future<List<TimeSlotModel>> getTimeSlots(DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first;
    final response = await http.get(
      Uri.parse('$_baseUrl/api/slots?date=$dateStr'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final slots = data['slots'] as List<dynamic>;
      return slots
          .map((s) => TimeSlotModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // Appointments
  Future<AppointmentModel> createAppointment(
      DateTime date, String timeSlotId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/appointments'),
      headers: _headers,
      body: jsonEncode({
        'date': date.toIso8601String().split('T').first,
        'time_slot_id': timeSlotId,
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AppointmentModel.fromJson(data);
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<List<AppointmentModel>> getMyAppointments() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/appointments/me'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final appointments = data['appointments'] as List<dynamic>;
      return appointments
          .map((a) => AppointmentModel.fromJson(a as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<void> cancelAppointment(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/appointments/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  // Admin
  Future<List<AppointmentModel>> getAllAppointments(
      {String? date, String? status}) async {
    final queryParams = <String, String>{};
    if (date != null) queryParams['date'] = date;
    if (status != null) queryParams['status'] = status;

    final uri =
        Uri.parse('$_baseUrl/api/admin/appointments').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final appointments = data['appointments'] as List<dynamic>;
      return appointments
          .map((a) => AppointmentModel.fromJson(a as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<void> adminDeleteAppointment(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/admin/appointments/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  Future<AppointmentModel> adminCreateAppointment(
      String userId, DateTime date, String timeSlotId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/admin/appointments'),
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'date': date.toIso8601String().split('T').first,
        'time_slot_id': timeSlotId,
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AppointmentModel.fromJson(data);
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<TimeSlotModel> adminCreateTimeSlot(DateTime date, String time) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/admin/slots'),
      headers: _headers,
      body: jsonEncode({
        'date': date.toIso8601String().split('T').first,
        'time': time,
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return TimeSlotModel.fromJson(data);
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<void> adminDeleteTimeSlot(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/admin/slots/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _parseError(response.body));
    }
  }

  Future<List<UserModel>> adminGetUsers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/admin/users'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final users = data['users'] as List<dynamic>;
      return users
          .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['error'] as String? ?? 'Erro desconhecido';
    } catch (_) {
      return 'Erro desconhecido';
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
