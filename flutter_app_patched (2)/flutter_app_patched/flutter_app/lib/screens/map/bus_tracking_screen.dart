import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Bus Tracking Screen using OpenStreetMap (flutter_map)
/// Replaces the old Google Maps implementation.
/// Shows live user location with auto-refresh every 5 seconds.
class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  // Demo bus positions (in a real app fetch from backend RTDB)
  final List<_BusMarker> _buses = [
    _BusMarker(id: 'BUS-01', route: 'Route A', latLng: const LatLng(13.0827, 80.2707)),
    _BusMarker(id: 'BUS-02', route: 'Route B', latLng: const LatLng(13.0700, 80.2600)),
    _BusMarker(id: 'BUS-03', route: 'Route C', latLng: const LatLng(13.0950, 80.2800)),
  ];
  Timer? _locationTimer;
  bool _locationPermissionDenied = false;
  bool _isLoading = true;

  // Default location — college campus (change as needed)
  static const LatLng _defaultCenter = LatLng(13.0827, 80.2707);

  @override
  void initState() {
    super.initState();
    _initLocation();
    // Simulate bus movement every 5 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateLocation();
      _simulateBusMovement();
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final req = await Geolocator.requestPermission();
      if (req == LocationPermission.denied ||
          req == LocationPermission.deniedForever) {
        setState(() {
          _locationPermissionDenied = true;
          _isLoading = false;
        });
        return;
      }
    }
    await _updateLocation();
  }

  Future<void> _updateLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentLocation = _defaultCenter;
          _isLoading = false;
        });
      }
    }
  }

  /// Simulate bus movement for demo purposes
  void _simulateBusMovement() {
    if (!mounted) return;
    setState(() {
      for (final bus in _buses) {
        bus.latLng = LatLng(
          bus.latLng.latitude + (0.0002 * (1 - 2 * (DateTime.now().second % 2))),
          bus.latLng.longitude + (0.0001 * (1 - 2 * (DateTime.now().millisecond % 2))),
        );
      }
    });
  }

  void _centerOnUser() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final center = _currentLocation ?? _defaultCenter;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text('Getting your location…',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (_locationPermissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded,
                  size: 64, color: cs.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('Location Permission Denied',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: cs.onSurface)),
              const SizedBox(height: 8),
              Text('Enable location to track live bus positions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                  _initLocation();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
            maxZoom: 18,
            minZoom: 10,
          ),
          children: [
            // OpenStreetMap tile layer — no API key needed
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.onecampus.app',
            ),
            // User location marker
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 48,
                    height: 48,
                    child: _UserLocationMarker(color: cs.primary),
                  ),
                ],
              ),
            // Bus markers
            MarkerLayer(
              markers: _buses.map((bus) {
                return Marker(
                  point: bus.latLng,
                  width: 60,
                  height: 60,
                  child: _BusLocationMarker(bus: bus),
                );
              }).toList(),
            ),
          ],
        ),

        // Map legend card
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: cs.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('You', style: TextStyle(fontSize: 12, color: cs.onSurface)),
                const SizedBox(width: 16),
                const Text('🚌', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text('Live Buses (${_buses.length})',
                    style: TextStyle(fontSize: 12, color: cs.onSurface)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: cs.secondary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text('Live',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.secondary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Center on me button
        Positioned(
          bottom: 24,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'center_location',
            mini: true,
            onPressed: _centerOnUser,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
      ],
    );
  }
}

class _BusMarker {
  final String id;
  final String route;
  LatLng latLng;
  _BusMarker({required this.id, required this.route, required this.latLng});
}

class _UserLocationMarker extends StatelessWidget {
  final Color color;
  const _UserLocationMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BusLocationMarker extends StatelessWidget {
  final _BusMarker bus;
  const _BusLocationMarker({required this.bus});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            bus.route,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Text('🚌', style: TextStyle(fontSize: 22)),
      ],
    );
  }
}
