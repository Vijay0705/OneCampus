import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/canteen_provider.dart';
import '../../models/canteen_model.dart';
import '../../models/user_model.dart';
import '../../widgets/common_widgets.dart';
import 'canteen_admin_dashboard.dart';

class CanteenScreen extends StatefulWidget {
  const CanteenScreen({super.key});

  @override
  State<CanteenScreen> createState() => _CanteenScreenState();
}

class _CanteenScreenState extends State<CanteenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CanteenProvider>().fetchTodayItems();
      context.read<CanteenProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canteen = context.watch<CanteenProvider>();
    final user = context.read<AuthProvider>().user;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canteen 🍔'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu_rounded), text: "Today's Menu"),
            Tab(icon: Icon(Icons.receipt_outlined), text: 'My Orders'),
          ],
        ),
        actions: [
          if (user?.isStudent == true && canteen.cartItemCount > 0)
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => _showCart(context, canteen),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            color: cs.error, shape: BoxShape.circle),
                        child: Text(
                          '${canteen.cartItemCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (user?.canManageCanteen == true) ...[
            IconButton(
              icon: const Icon(Icons.dashboard_customize_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CanteenAdminDashboard()),
              ),
              tooltip: 'Admin Dashboard',
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showAddItemDialog(context),
              tooltip: 'Add Item',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (canteen.errorMessage != null)
            ErrorBanner(
              message: canteen.errorMessage!,
              onDismiss: canteen.clearMessages,
            ),
          if (canteen.successMessage != null)
            SuccessBanner(
              message: canteen.successMessage!,
              onDismiss: canteen.clearMessages,
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MenuTab(canteen: canteen, user: user),
                _OrdersTab(canteen: canteen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCart(BuildContext context, CanteenProvider canteen) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(
        value: canteen,
        child: const _CartSheet(),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CanteenProvider>(),
        child: const _AddItemDialog(),
      ),
    );
  }
}

// ── Add Item Dialog ──────────────────────────────────────────────
class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog();

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _catCtrl = TextEditingController(text: 'Main Course');
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final provider = context.read<CanteenProvider>();
    final ok = await provider.addItem(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text),
      quantity: int.parse(_qtyCtrl.text),
      category: _catCtrl.text.trim(),
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? "Item added to today's menu!"
            : provider.errorMessage ?? 'Failed to add item'),
        backgroundColor: ok
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Menu Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Item Name',
                    prefixIcon: Icon(Icons.fastfood_rounded)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_rounded)),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price (₹)'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      if (n == null || n < 1) return 'Min 1';
                      return null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              TextFormField(
                controller: _catCtrl,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Add'),
        ),
      ],
    );
  }
}

// ── Menu Tab ─────────────────────────────────────────────────────
class _MenuTab extends StatelessWidget {
  final CanteenProvider canteen;
  final UserModel? user;
  const _MenuTab({required this.canteen, required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (canteen.loadingItems) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (canteen.items.isEmpty) {
      return EmptyState(
        icon: Icons.no_meals_outlined,
        title: 'No Items Today',
        subtitle: "Today's menu hasn't been set yet",
        actionLabel: 'Refresh',
        onAction: () => context.read<CanteenProvider>().fetchTodayItems(),
      );
    }

    final grouped = <String, List<CanteenItem>>{};
    for (final item in canteen.items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CanteenProvider>().fetchTodayItems(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: entry.key),
              ...entry.value.map((item) => _MenuItemCard(
                    item: item,
                    canteen: canteen,
                    isStudent: user?.isStudent == true,
                  )),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final CanteenItem item;
  final CanteenProvider canteen;
  final bool isStudent;

  const _MenuItemCard({
    required this.item,
    required this.canteen,
    required this.isStudent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cartQty = canteen.cartQuantityFor(item.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.fastfood_rounded,
                  color: cs.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: cs.onSurface)),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.description,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    Text('₹${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.availableQuantity > 0
                            ? cs.secondary.withOpacity(0.1)
                            : cs.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.availableQuantity > 0
                            ? '${item.availableQuantity} left'
                            : 'Sold out',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.availableQuantity > 0
                                ? cs.secondary
                                : cs.error),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            if (isStudent) ...[
              if (cartQty == 0)
                IconButton(
                  icon: Icon(Icons.add_circle_rounded, color: cs.primary, size: 32),
                  onPressed: item.availableQuantity > 0
                      ? () => canteen.addToCart(item)
                      : null,
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline_rounded,
                          color: cs.primary, size: 24),
                      onPressed: () => canteen.decrementCart(item.id),
                    ),
                    Text('$cartQty',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: cs.onSurface)),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline_rounded,
                          color: cs.primary, size: 24),
                      onPressed: cartQty < item.availableQuantity
                          ? () => canteen.addToCart(item)
                          : null,
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Orders Tab ─────────────────────────────────────────────────────
class _OrdersTab extends StatelessWidget {
  final CanteenProvider canteen;
  const _OrdersTab({required this.canteen});

  Color _statusColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case 'pending': return const Color(0xFFFFB300);
      case 'preparing': return cs.primary;
      case 'ready': return cs.secondary;
      case 'completed': return cs.onSurfaceVariant;
      case 'cancelled': return cs.error;
      default: return cs.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (canteen.loadingOrders) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (canteen.orders.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No Orders Today',
        subtitle: 'Your orders will appear here',
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<CanteenProvider>().fetchOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: canteen.orders.length,
        itemBuilder: (_, i) {
          final order = canteen.orders[i];
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
                  Row(children: [
                    Expanded(
                      child: Text(
                        order.displayId,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: cs.onSurface),
                      ),
                    ),
                    StatusChip(
                      label: order.status.toUpperCase(),
                      color: _statusColor(context, order.status),
                    ),
                  ]),
                  Divider(height: 16, color: cs.outline.withOpacity(0.3)),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text('${item.quantity}',
                                  style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item.name,
                                style: TextStyle(
                                    fontSize: 14, color: cs.onSurface)),
                          ),
                          Text(
                            '₹${item.subtotal.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface),
                          ),
                        ]),
                      )),
                  Divider(height: 16, color: cs.outline.withOpacity(0.3)),
                  Row(children: [
                    Text('Total',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: cs.onSurface)),
                    const Spacer(),
                    Text(
                      '₹${order.totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                          fontSize: 16),
                    ),
                  ]),
                  if (order.status == 'ready') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Mark as Picked Up'),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.secondary,
                          minimumSize: const Size(0, 42),
                        ),
                        onPressed: () async {
                          final ok = await context
                              .read<CanteenProvider>()
                              .markOrderCompleted(order.id);
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Great! Enjoy your meal 🎉')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Cart Sheet ─────────────────────────────────────────────────────
class _CartSheet extends StatelessWidget {
  const _CartSheet();

  @override
  Widget build(BuildContext context) {
    final canteen = context.watch<CanteenProvider>();
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scrollController) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Your Cart',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              const Spacer(),
              TextButton(
                onPressed: canteen.clearCart,
                child: Text('Clear', style: TextStyle(color: cs.error)),
              ),
            ]),
            Divider(color: cs.outline.withOpacity(0.3)),
            Expanded(
              child: canteen.cart.isEmpty
                  ? Center(
                      child: Text('Cart is empty',
                          style:
                              TextStyle(color: cs.onSurfaceVariant)))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: canteen.cart.length,
                      itemBuilder: (_, i) {
                        final cartItem = canteen.cart[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cartItem.item.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface)),
                                    Text(
                                        '₹${cartItem.item.price.toStringAsFixed(0)} × ${cartItem.quantity}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: cs.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${cartItem.subtotal.toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: cs.primary,
                                    fontSize: 15),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Divider(color: cs.outline.withOpacity(0.3)),
            Row(children: [
              Text('Total:',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              const Spacer(),
              Text(
                '₹${canteen.cartTotal.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.primary),
              ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canteen.placingOrder
                    ? null
                    : () async {
                        final ok = await canteen.placeOrder();
                        if (ok && context.mounted) Navigator.pop(context);
                      },
                child: canteen.placingOrder
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
