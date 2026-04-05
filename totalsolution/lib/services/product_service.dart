import 'package:flutter/material.dart';
import '../models/models.dart';

// Mock Product Service - Works without Firebase for immediate testing
class ProductService extends ChangeNotifier {
  List<ProductModel> _products = [];
  bool _isLoading = false;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;

  ProductService() {
    _loadMockProducts();
  }

  void _loadMockProducts() {
    _products = [
      ProductModel(
        id: 'prod_001',
        name: 'Crunchy Chips 100g',
        category: 'Snacks',
        sku: 'CC122',
        price: 120.0,
        stock: 500,
        description: 'Delicious crispy chips',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'prod_002',
        name: 'Cool Cola 500ml',
        category: 'Beverages',
        sku: 'CL499',
        price: 45.0,
        stock: 1000,
        description: 'Refreshing cola drink',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'prod_003',
        name: 'Sweet Biscuits 200g',
        category: 'Bakery',
        sku: 'CL179',
        price: 25.0,
        stock: 800,
        description: 'Crunchy sweet biscuits',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'prod_004',
        name: 'Sunkist Shampoo 400ml',
        category: 'Personal Care',
        sku: 'SH401',
        price: 199.0,
        stock: 200,
        description: 'Anti-dandruff shampoo',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'prod_005',
        name: 'Tropical Juice 1L',
        category: 'Beverages',
        sku: 'TJ100',
        price: 89.0,
        stock: 300,
        description: 'Mixed fruit juice',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'prod_006',
        name: 'Creamy Milk 1L',
        category: 'Dairy',
        sku: 'DM100',
        price: 55.0,
        stock: 500,
        description: 'Fresh toned milk',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  Future<List<ProductModel>> getProducts() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    _isLoading = false;
    notifyListeners();
    return _products;
  }

  Future<ProductModel?> getProductById(String id) async {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addProduct(ProductModel product) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    _products.add(product);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProduct(ProductModel product) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    _products.removeWhere((p) => p.id == id);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> syncProducts(List<ProductModel> products) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    // Idempotent sync: update if exists, add if not
    for (final product in products) {
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
      } else {
        _products.add(product);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) return _products;

    final lowerQuery = query.toLowerCase();
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(lowerQuery) ||
              p.sku.toLowerCase().contains(lowerQuery) ||
              p.category.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }
}
