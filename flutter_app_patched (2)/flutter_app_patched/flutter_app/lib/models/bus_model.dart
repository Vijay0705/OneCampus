class BusModel {
  final String id;
  final String busNumber;
  final String routeName;
  final int capacity;
  final bool isActive;
  final String createdAt;

  BusModel({
    required this.id,
    required this.busNumber,
    required this.routeName,
    required this.capacity,
    required this.isActive,
    required this.createdAt,
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      id: json['id'] ?? '',
      busNumber: json['bus_number'] ?? '',
      routeName: json['route_name'] ?? '',
      capacity: json['capacity'] ?? 50,
      isActive: json['is_active'] ?? true,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class BusLocation {
  final String busId;
  final double latitude;
  final double longitude;
  final String timestamp;
  final String source;
  final String updatedAt;
  final bool isOffline;

  BusLocation({
    required this.busId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.source,
    required this.updatedAt,
    this.isOffline = false,
  });

  factory BusLocation.fromJson(Map<String, dynamic> json) {
    final updatedAt = json['updatedAt'] ?? json['timestamp'] ?? '';
    bool offline = false;
    if (updatedAt.isNotEmpty) {
      final last = DateTime.tryParse(updatedAt);
      if (last != null) {
        offline = DateTime.now().difference(last).inSeconds > 30;
      }
    }
    return BusLocation(
      busId: json['bus_id'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? '',
      source: json['source'] ?? 'unknown',
      updatedAt: updatedAt,
      isOffline: json['isOffline'] ?? offline,
    );
  }
}

class BusSchedule {
  final String id;
  final String busId;
  final String date;
  final List<String> stops;
  final String departureTime;
  final String? arrivalTime;

  BusSchedule({
    required this.id,
    required this.busId,
    required this.date,
    required this.stops,
    required this.departureTime,
    this.arrivalTime,
  });

  factory BusSchedule.fromJson(Map<String, dynamic> json) {
    return BusSchedule(
      id: json['id'] ?? '',
      busId: json['bus_id'] ?? '',
      date: json['date'] ?? '',
      stops: List<String>.from(json['stops'] ?? []),
      departureTime: json['departure_time'] ?? '',
      arrivalTime: json['arrival_time'],
    );
  }
}
