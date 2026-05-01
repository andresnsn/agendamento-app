import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../models/time_slot_model.dart';
import '../services/api_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<TimeSlotModel> _timeSlots = [];
  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> _allAppointments = [];
  bool _isLoading = false;
  String? _error;

  AppointmentProvider(this._apiService);

  List<TimeSlotModel> get timeSlots => _timeSlots;
  List<AppointmentModel> get appointments => _appointments;
  List<AppointmentModel> get allAppointments => _allAppointments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTimeSlots(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _timeSlots = await _apiService.getTimeSlots(date);
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar horários.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> bookAppointment(DateTime date, String timeSlotId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final appointment =
          await _apiService.createAppointment(date, timeSlotId);
      _appointments.add(appointment);
      _timeSlots = _timeSlots.map((slot) {
        if (slot.id == timeSlotId) {
          return TimeSlotModel(
            id: slot.id,
            date: slot.date,
            time: slot.time,
            isAvailable: false,
          );
        }
        return slot;
      }).toList();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erro ao agendar. Tente novamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMyAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _apiService.getMyAppointments();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar agendamentos.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelAppointment(String id) async {
    try {
      await _apiService.cancelAppointment(id);
      _appointments.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erro ao cancelar agendamento.';
      notifyListeners();
      return false;
    }
  }

  // Admin methods
  Future<void> loadAllAppointments({String? date, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allAppointments =
          await _apiService.getAllAppointments(date: date, status: status);
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar agendamentos.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> adminDeleteAppointment(String id) async {
    try {
      await _apiService.adminDeleteAppointment(id);
      _allAppointments.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erro ao excluir agendamento.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminCreateTimeSlot(DateTime date, String time) async {
    try {
      final slot = await _apiService.adminCreateTimeSlot(date, time);
      _timeSlots.add(slot);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erro ao criar horário.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminDeleteTimeSlot(String id) async {
    try {
      await _apiService.adminDeleteTimeSlot(id);
      _timeSlots.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erro ao excluir horário.';
      notifyListeners();
      return false;
    }
  }
}
