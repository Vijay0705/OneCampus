import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/bus_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

/// 🔵 Replacement for Google Maps LatLng
class BusLocation {
  final double latitude;
  final double longitude;

  BusLocation({
    required this.latitude,
    required this.longitude,
  });

  factory BusLocation.fromJson(Map<String, dynamic> json) {
    return BusLocation(
      latitude: (json['latitude'] ?? json['lat'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? 0).toDouble(),
    );
  }
}

class BusProvider extends ChangeNotifier {
  List<BusModel> _buses = [];
  List<BusSchedule> _schedules = [];
  final Map<String, BusLocation> _busLocations = {};
  final Map<String, Timer> _timers = {};
  bool _loading = false;
  String? _errorMessage;

  List<BusModel> get buses => _buses;
  List<BusSchedule> get schedules => _schedules;
  Map<String, BusLocation> get busLocations => _busLocations;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  // 🚍 Fetch buses
  Future<void> fetchBuses() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.get(AppConstants.trackingBusesUrl);

      final list = res is List
          ? res
          : (res['data']?['buses'] ?? res['buses'] ?? res['data'] ?? []);

      _buses = (list as List)
          .map((b) => BusModel.fromJson(b as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      // fallback silent
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // 📅 Fetch schedules
  Future<void> fetchSchedules({String? date}) async {
    try {
      final url = date != null
          ? '${AppConstants.trackingSchedulesUrl}?date=$date'
          : AppConstants.trackingSchedulesUrl;

      final res = await ApiService.get(url);

      final list = res is List
          ? res
          : (res['data']?['schedules'] ?? res['schedules'] ?? []);

      _schedules = (list as List)
          .map((s) => BusSchedule.fromJson(s as Map<String, dynamic>))
          .toList();

      notifyListeners();
    } catch (_) {}
  }

  // 📍 Track bus location (without Google Maps)
  void startTrackingBus(String busId) {
    _timers[busId]?.cancel();

    _timers[busId] = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final res =
            await ApiService.get('${AppConstants.trackingLocationUrl}/$busId');

        final loc = res['data']?['location'] ?? res;

        _busLocations[busId] =
            BusLocation.fromJson(loc as Map<String, dynamic>);

        notifyListeners();
      } catch (_) {}
    });
  }

  void stopAllTracking() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }

  // ➕ Add new bus
  Future<bool> addBus({
    required String busNumber,
    required String route,
    required String driverName,
  }) async {
    try {
      await ApiService.post(AppConstants.trackingBusesUrl, {
        'busNumber': busNumber,
        'route': route,
        'driverName': driverName,
      });

      await fetchBuses();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add bus.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    stopAllTracking();
    super.dispose();
  }
}