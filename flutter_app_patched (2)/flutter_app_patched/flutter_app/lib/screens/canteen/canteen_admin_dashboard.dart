import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/canteen_provider.dart';
import '../../models/canteen_model.dart';
import '../../widgets/common_widgets.dart';

class CanteenAdminDashboard extends StatefulWidget {
  const CanteenAdminDashboard({super.key});

  @override
  State<CanteenAdminDashboard> createState() => _CanteenAdminDashboardState();
}

class _CanteenAdminDashboardState extends State<CanteenAdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CanteenProvider>().fetchAllOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canteen = context.watch<CanteenProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => canteen.fetchAllOrders(),
          ),
        ],
      ),
      body: canteen.loadingOrders
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : canteen.allOrders.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No Orders Today',
                  subtitle: 'Orders will appear here',
                )
              : Column(
                  children: [
                    _SummaryRow(orders: canteen.allOrders),
                    _ItemSummarySection(orders: canteen.allOrders),
                    Divider(height: 1, color: cs.outline.withOpacity(0.3)),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => canteen.fetchAllOrders(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: canteen.allOrders.length,
                          itemBuilder: (_, i) => _AdminOrderCard(
                            order: canteen.allOrders[i],
                            onStatusUpdate: (status) =>
                                canteen.updateOrderStatus(
                                    canteen.allOrders[i].id, status),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<CanteenOrder> orders;
  const _SummaryRow({required this.orders});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalOrders = orders.length;
    final totalRevenue = orders.fold<double>(0, (s, o) => s + o.totalPrice);
    final pending = orders.where((o) => o.status == 'pending').length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: cs.surface,
      child: Row(
        children: [
          _SumCard(
            label: 'Orders',
            value: '$totalOrders',
            color: cs.primary,
            icon: Icons.receipt_rounded,
          ),
          const SizedBox(width: 10),
          _SumCard(
            label: 'Revenue',
            value: '₹${totalRevenue.toStringAsFixed(0)}',
            color: cs.secondary,
            icon: Icons.currency_rupee_rounded,
          ),
          const SizedBox(width: 10),
          _SumCard(
            label: 'Pending',
            value: '$pending',
            color: const Color(0xFFFFB300),
            icon: Icons.pending_actions_rounded,
          ),
        ],
      ),
    );
  }
}

class _SumCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SumCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ItemSummarySection extends StatelessWidget {
  final List<CanteenOrder> orders;
  const _ItemSummarySection({required this.orders});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // BUG FIX: Aggregate items by name (was empty because name was '\'Unknown\'' in old code)
    final Map<String, int> itemCounts = {};
    for (final order in orders) {
      for (final item in order.items) {
        final name = item.name.isNotEmpty ? item.name : 'Unknown Item';
        itemCounts[name] = (itemCounts[name] ?? 0) + item.quantity;
      }
    }
    final sorted = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item Summary',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: cs.onSurface),
          ),
          const SizedBox(height: 12),
          if (sorted.isEmpty)
            Text('No items data',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))
          else
            ...sorted.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.fastfood_rounded,
                            color: cs.primary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.key,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '×${e.value}',
                          style: TextStyle(
                            color: cs.secondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final CanteenOrder order;
  final void Function(String status) onStatusUpdate;
  const _AdminOrderCard(
      {required this.order, required this.onStatusUpdate});

  Color _statusColor(BuildContext context, String s) {
    final cs = Theme.of(context).colorScheme;
    switch (s) {
      case 'pending': return const Color(0xFFFFB300);
      case 'preparing': return cs.primary;
      case 'ready': return cs.secondary;
      case 'completed': return cs.onSurfaceVariant;
      case 'cancelled': return cs.error;
      default: return cs.onSurfaceVariant;
    }
  }

  String? _nextStatus(String current) {
    const flow = ['pending', 'preparing', 'ready', 'completed'];
    final idx = flow.indexOf(current);
    if (idx == -1 || idx == flow.length - 1) return null;
    return flow[idx + 1];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final next = _nextStatus(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BUG FIX: Use displayId (ORD format) instead of raw Firestore ID
                      Text(
                        order.displayId,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.studentName.isNotEmpty
                            ? order.studentName
                            : 'Student',
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: order.status.toUpperCase(),
                  color: _statusColor(context, order.status),
                ),
              ],
            ),
            Divider(height: 20, color: cs.outline.withOpacity(0.3)),
            // BUG FIX: Item names now display correctly
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '×${item.quantity}',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                              fontSize: 14, color: cs.onSurface),
                        ),
                      ),
                      Text(
                        '₹${item.subtotal.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: cs.onSurface),
                      ),
                    ],
                  ),
                )),
            Divider(height: 16, color: cs.outline.withOpacity(0.3)),
            Row(
              children: [
                Text('Total',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: cs.onSurface)),
                const Spacer(),
                Text(
                  '₹${order.totalPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      fontSize: 16),
                ),
              ],
            ),
            if (next != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _statusColor(context, next),
                    minimumSize: const Size(0, 42),
                  ),
                  onPressed: () => onStatusUpdate(next),
                  child: Text(
                      'Mark as ${next[0].toUpperCase()}${next.substring(1)}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}