import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../models/canteen_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class CanteenProvider extends ChangeNotifier {
  List<CanteenItem> _items = [];
  List<CanteenOrder> _orders = [];
  final List<CartItem> _cart = [];
  bool _loadingItems = false;
  bool _loadingOrders = false;
  bool _placingOrder = false;
  String? _errorMessage;
  String? _successMessage;

  List<CanteenItem> get items => _items;
  List<CanteenOrder> get orders => _orders;
  List<CartItem> get cart => _cart;
  bool get loadingItems => _loadingItems;
  bool get loadingOrders => _loadingOrders;
  bool get placingOrder => _placingOrder;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  int get cartItemCount => _cart.fold(0, (sum, c) => sum + c.quantity);

  double get cartTotal =>
      _cart.fold(0.0, (sum, c) => sum + c.subtotal);

  // ── Fetch today's menu ────────────────────────────────────────────
  Future<void> fetchTodayItems() async {
    _loadingItems = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await ApiService.get(AppConstants.canteenTodayItemsUrl);
      _items = (res['data']['items'] as List)
          .map((i) => CanteenItem.fromJson(i as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _loadingItems = false;
      notifyListeners();
    }
  }

  // ── Fetch orders ──────────────────────────────────────────────────
  Future<void> fetchOrders() async {
    _loadingOrders = true;
    notifyListeners();
    try {
      final res = await ApiService.get(AppConstants.canteenOrdersUrl);
      _orders = (res['data']['orders'] as List)
          .map((o) => CanteenOrder.fromJson(o as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _loadingOrders = false;
      notifyListeners();
    }
  }

  List<CanteenOrder> get allOrders => _orders;

  Future<void> fetchAllOrders() => fetchOrders();

  Future<void> updateOrderStatus(String orderId, String status) async {
    _loadingOrders = true;
    notifyListeners();
    try {
      await ApiService.patch('${AppConstants.canteenOrderUrl}/$orderId/status', {'status': status});
      await fetchOrders();
    } on ApiException catch(e) {
      _errorMessage = e.message;
    } finally {
      _loadingOrders = false;
      notifyListeners();
    }
  }

  /// Called by the student after picking up their food (status must be 'ready').
  Future<bool> markOrderCompleted(String orderId) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await ApiService.patch(
        '${AppConstants.canteenOrderUrl}/$orderId/status',
        {'status': 'completed'},
      );
      await fetchOrders();
      _successMessage = 'Order marked as completed!';
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  // ── Cart operations ───────────────────────────────────────────────
  void addToCart(CanteenItem item) {
    final existing = _cart.where((c) => c.item.id == item.id).firstOrNull;
    if (existing != null) {
      if (existing.quantity < item.availableQuantity) {
        existing.quantity++;
        notifyListeners();
      }
    } else {
      _cart.add(CartItem(item: item));
      notifyListeners();
    }
  }

  void removeFromCart(String itemId) {
    _cart.removeWhere((c) => c.item.id == itemId);
    notifyListeners();
  }

  void decrementCart(String itemId) {
    final existing = _cart.where((c) => c.item.id == itemId).firstOrNull;
    if (existing != null) {
      if (existing.quantity > 1) {
        existing.quantity--;
      } else {
        _cart.removeWhere((c) => c.item.id == itemId);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  int cartQuantityFor(String itemId) {
    return _cart
        .where((c) => c.item.id == itemId)
        .fold(0, (_, c) => c.quantity);
  }

  // ── Place order ───────────────────────────────────────────────────
  Future<bool> placeOrder() async {
    if (_cart.isEmpty) return false;
    _placingOrder = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final orderItems = _cart
          .map((c) => {'item_id': c.item.id, 'quantity': c.quantity})
          .toList();
      await ApiService.post(AppConstants.canteenOrderUrl, {'items': orderItems});
      _successMessage = 'Order placed! Check your order status.';
      clearCart();
      await fetchTodayItems(); // Refresh quantities
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _placingOrder = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // ── Admin: add menu item ──────────────────────────────────────────
  Future<bool> addItem({
    required String name,
    required String description,
    required double price,
    required int quantity,
    required String category,
  }) async {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      await ApiService.post(AppConstants.canteenAddItemUrl, {
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
        'category': category,
      });
      _successMessage = 'Item added to today\'s menu!';
      await fetchTodayItems();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }
}
