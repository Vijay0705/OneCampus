import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class MarketplaceProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _myProducts = [];
  bool _loading = false;
  String? _errorMessage;
  String? _successMessage;

  List<Product> get products => _products;
  List<Product> get myProducts => _myProducts;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> fetchProducts() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await ApiService.get(AppConstants.marketplaceProductsUrl);
      final list = res is List ? res : (res['data'] ?? res['products'] ?? []);
      _products = (list as List)
          .map((p) => Product.fromJson(p as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load products.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyProducts() async {
    try {
      final res = await ApiService.get(AppConstants.marketplaceMyProductsUrl);
      final list = res is List ? res : (res['data'] ?? res['products'] ?? []);
      _myProducts = (list as List)
          .map((p) => Product.fromJson(p as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> addProduct({
    required String name,
    required double price,
    required String description,
    required String category,
    required String condition,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (imageBytes != null && imageName != null) {
        await ApiService.uploadWithImage(
          AppConstants.marketplaceAddUrl,
          {
            'name': name,
            'price': price.toString(),
            'description': description,
            'category': category,
            'condition': condition,
          },
          imageBytes: imageBytes,
          imageName: imageName,
        );
      } else {
        await ApiService.post(AppConstants.marketplaceAddUrl, {
          'name': name,
          'price': price,
          'description': description,
          'category': category,
          'condition': condition,
        });
      }
      _successMessage = 'Item listed successfully!';
      await fetchProducts();
      await fetchMyProducts();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to list item.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> markAsSold(String id) async {
    try {
      await ApiService.patch('${AppConstants.marketplaceMarkSoldUrl}/$id', {});
      _successMessage = 'Marked as sold!';
      await fetchMyProducts();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to mark as sold.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await ApiService.delete('${AppConstants.marketplaceDeleteUrl}/$id');
      _myProducts.removeWhere((p) => p.id == id);
      _products.removeWhere((p) => p.id == id);
      _successMessage = 'Listing deleted.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete listing.';
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}