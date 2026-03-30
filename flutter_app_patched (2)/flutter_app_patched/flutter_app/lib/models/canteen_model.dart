class CanteenItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final int availableQuantity;
  final String category;
  final String? imageUrl;
  final String date;
  final bool isAvailable;

  CanteenItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.availableQuantity,
    required this.category,
    this.imageUrl,
    required this.date,
    required this.isAvailable,
  });

  factory CanteenItem.fromJson(Map<String, dynamic> json) {
    return CanteenItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      availableQuantity: json['available_quantity'] ?? 0,
      category: json['category'] ?? 'General',
      imageUrl: json['image_url'],
      date: json['date'] ?? '',
      isAvailable: json['is_available'] ?? true,
    );
  }
}

class OrderItem {
  final String itemId;
  final String name;
  final int quantity;
  final double price;
  final double subtotal;

  OrderItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final qty = json['quantity'] ?? 1;
    final price = (json['price'] ?? 0).toDouble();
    final subtotal = json['subtotal'] != null
        ? (json['subtotal']).toDouble()
        : price * qty;
    return OrderItem(
      itemId: json['item_id'] ?? json['itemId'] ?? '',
      // BUG FIX: backend stores 'name' inside each order item
      name: json['name'] ?? json['itemName'] ?? json['item_name'] ?? 'Unknown Item',
      quantity: qty,
      price: price,
      subtotal: subtotal,
    );
  }
}

class CanteenOrder {
  final String id;
  final String displayId; // e.g. ORD-2026-0001
  final String studentId;
  final String studentName;
  final List<OrderItem> items;
  final double totalPrice;
  final String status;
  final String date;
  final String createdAt;

  CanteenOrder({
    required this.id,
    required this.displayId,
    required this.studentId,
    required this.studentName,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.date,
    required this.createdAt,
  });

  factory CanteenOrder.fromJson(Map<String, dynamic> json) {
    // Support new ORD-YYYY-NNNN format OR fall-back to truncated raw ID
    final rawId = json['id'] ?? '';
    final displayId = json['orderId'] ?? json['displayId'] ??
        (rawId.length >= 8 ? 'ORD-${rawId.substring(0, 8).toUpperCase()}' : rawId);

    return CanteenOrder(
      id: rawId,
      displayId: displayId,
      studentId: json['userId'] ?? json['student_id'] ?? '',
      studentName: json['studentName'] ?? json['student_name'] ?? 'Student',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPrice: (json['total'] ?? json['total_price'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      date: json['date'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class CartItem {
  final CanteenItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  double get subtotal => item.price * quantity;
}
