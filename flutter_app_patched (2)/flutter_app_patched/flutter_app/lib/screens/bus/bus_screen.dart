import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bus_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../models/bus_model.dart';
import '../map/bus_tracking_screen.dart';

class BusScreen extends StatefulWidget {
  const BusScreen({super.key});

  @override
  State<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends State<BusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final p = context.read<BusProvider>();
    await p.fetchBuses();
    await p.fetchSchedules();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BusProvider>();
    final user = context.read<AuthProvider>().user;
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bus Tracker 🚌'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.map_outlined), text: 'Live Map'),
            Tab(icon: Icon(Icons.schedule_outlined), text: 'Schedules'),
          ]),
          actions: [
            if (user?.isAdmin == true)
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => _showAddBusDialog(context),
                tooltip: 'Add Bus',
              ),
          ],
        ),
        body: TabBarView(children: [
          const BusTrackingScreen(),
          _SchedulesTab(provider: p),
        ]),
      ),
    );
  }

  void _showAddBusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<BusProvider>(),
        child: const _AddBusDialog(),
      ),
    );
  }
}

// ── Schedules Tab ─────────────────────────────────────────────────
class _SchedulesTab extends StatelessWidget {
  final BusProvider provider;
  const _SchedulesTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (provider.loading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }

    final demoSchedules = [
      _DemoSchedule('Route A', 'Main Gate → Campus', '07:00', '07:30', 'On Time'),
      _DemoSchedule('Route B', 'East Block → Campus', '07:15', '07:45', 'Delayed'),
      _DemoSchedule('Route C', 'West Area → Campus', '07:30', '08:00', 'On Time'),
      _DemoSchedule('Route A', 'Campus → Main Gate', '17:00', '17:30', 'On Time'),
      _DemoSchedule('Route B', 'Campus → East Block', '17:15', '17:45', 'On Time'),
      _DemoSchedule('Route C', 'Campus → West Area', '17:30', '18:00', 'On Time'),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: demoSchedules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ScheduleCard(s: demoSchedules[i]),
    );
  }
}

class _DemoSchedule {
  final String route;
  final String description;
  final String departure;
  final String arrival;
  final String status;
  const _DemoSchedule(this.route, this.description, this.departure,
      this.arrival, this.status);
}

class _ScheduleCard extends StatelessWidget {
  final _DemoSchedule s;
  const _ScheduleCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOnTime = s.status == 'On Time';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.directions_bus_rounded,
                color: cs.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.route,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      fontSize: 15,
                    )),
                const SizedBox(height: 3),
                Text(s.description,
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 13, color: cs.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(
                      '${s.departure} → ${s.arrival}',
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isOnTime
                  ? const Color(0xFF00C9A7).withOpacity(0.12)
                  : const Color(0xFFFFB300).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOnTime
                    ? const Color(0xFF00C9A7).withOpacity(0.3)
                    : const Color(0xFFFFB300).withOpacity(0.3),
              ),
            ),
            child: Text(
              s.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isOnTime
                    ? const Color(0xFF00C9A7)
                    : const Color(0xFFFFB300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Bus Dialog ────────────────────────────────────────────────
class _AddBusDialog extends StatefulWidget {
  const _AddBusDialog();

  @override
  State<_AddBusDialog> createState() => _AddBusDialogState();
}

class _AddBusDialogState extends State<_AddBusDialog> {
  final _busNumberCtrl = TextEditingController();
  final _routeCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();

  @override
  void dispose() {
    _busNumberCtrl.dispose();
    _routeCtrl.dispose();
    _driverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BusProvider>();

    return AlertDialog(
      title: const Text('Add Bus'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _busNumberCtrl,
            decoration: const InputDecoration(
                labelText: 'Bus Number',
                prefixIcon: Icon(Icons.confirmation_number_rounded)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _routeCtrl,
            decoration: const InputDecoration(
                labelText: 'Route',
                prefixIcon: Icon(Icons.alt_route_rounded)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _driverCtrl,
            decoration: const InputDecoration(
                labelText: 'Driver Name',
                prefixIcon: Icon(Icons.person_rounded)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: p.loading
              ? null
              : () async {
                  if (_busNumberCtrl.text.isEmpty ||
                      _routeCtrl.text.isEmpty) return;
                  final ok = await p.addBus(
                    busNumber: _busNumberCtrl.text.trim(),
                    route: _routeCtrl.text.trim(),
                    driverName: _driverCtrl.text.trim(),
                  );
                  if (ok && context.mounted) Navigator.pop(context);
                },
          child: const Text('Add Bus'),
        ),
      ],
    );
  }
}