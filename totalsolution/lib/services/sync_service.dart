import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Service to sync products and customers from desktop software via API
///
/// Desktop Software Integration:
/// - When desktop clicks "Upload", it should call the POST endpoints:
///   - POST /api/products/receive - to push products to mobile
///   - POST /api/customers/receive - to push customers to mobile
/// - Or use the sync endpoints to pull data:
///   - POST /sync/products - pull products from desktop
///   - POST /sync/customers - pull customers from desktop
class SyncService {
  // Configure your desktop server URL here
  // Change this to your desktop software's API URL
  // For Firebase, use your Firebase Cloud Functions URL
  static const String _baseUrl = 'http://localhost:3000';

  /// Timeout duration for API calls
  static const Duration _timeout = Duration(seconds: 30);

  // For storing the server URL at runtime
  static String _customBaseUrl = _baseUrl;

  /// Update server URL at runtime
  static void updateServerUrl(String newUrl) {
    _customBaseUrl = newUrl;
  }

  /// Get current server URL
  static String get serverUrl => _customBaseUrl;

  /// Sync ALL data (products and customers) at once
  /// This is the main function to call when desktop software clicks "Upload"
  static Future<SyncResult> syncAllFromDesktop() async {
    try {
      // First try to sync products
      final productsResult = await syncProductsFromDesktop();

      // Then sync customers
      final customersResult = await syncCustomersFromDesktop();

      // Return combined result
      if (productsResult.success && customersResult.success) {
        return SyncResult(
          success: true,
          message:
              'Synced ${productsResult.total} products and ${customersResult.total} customers',
          inserted: productsResult.inserted + customersResult.inserted,
          updated: productsResult.updated + customersResult.updated,
          total: productsResult.total + customersResult.total,
        );
      } else {
        return SyncResult(
          success: false,
          message:
              'Partial sync: ${productsResult.message} | ${customersResult.message}',
          inserted: productsResult.inserted + customersResult.inserted,
          updated: productsResult.updated + customersResult.updated,
          total: productsResult.total + customersResult.total,
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync all failed: $e',
        inserted: 0,
        updated: 0,
        total: 0,
      );
    }
  }

  /// Sync products from desktop software
  /// Calls POST /sync/products endpoint
  static Future<SyncResult> syncProductsFromDesktop() async {
    try {
      final response = await http
          .post(
            Uri.parse('$_customBaseUrl/sync/products'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SyncResult(
          success: true,
          message: data['message'] ?? 'Products synced successfully',
          inserted: data['inserted'] ?? 0,
          updated: data['updated'] ?? 0,
          total: data['total'] ?? 0,
        );
      } else {
        return SyncResult(
          success: false,
          message: 'Failed to sync products: ${response.statusCode}',
          inserted: 0,
          updated: 0,
          total: 0,
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message:
            'Connection error: Unable to reach desktop software.\n\n'
            'Please ensure:\n'
            '1. Desktop software is running\n'
            '2. Mobile is connected to same network\n'
            '3. Correct server URL is configured\n\n'
            'Error: $e',
        inserted: 0,
        updated: 0,
        total: 0,
      );
    }
  }

  /// Sync customers from desktop software
  /// Calls POST /sync/customers endpoint
  static Future<SyncResult> syncCustomersFromDesktop() async {
    try {
      final response = await http
          .post(
            Uri.parse('$_customBaseUrl/sync/customers'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SyncResult(
          success: true,
          message: data['message'] ?? 'Customers synced successfully',
          inserted: data['inserted'] ?? 0,
          updated: data['updated'] ?? 0,
          total: data['total'] ?? 0,
        );
      } else {
        return SyncResult(
          success: false,
          message: 'Failed to sync customers: ${response.statusCode}',
          inserted: 0,
          updated: 0,
          total: 0,
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message:
            'Connection error: Unable to reach desktop software.\n\n'
            'Please ensure:\n'
            '1. Desktop software is running\n'
            '2. Mobile is connected to same network\n'
            '3. Correct server URL is configured\n\n'
            'Error: $e',
        inserted: 0,
        updated: 0,
        total: 0,
      );
    }
  }

  /// Receive products PUSHED from desktop software
  /// Desktop software calls this endpoint to push data to mobile
  /// This endpoint should be implemented in Firebase Cloud Functions or your backend
  ///
  /// Desktop software usage:
  /// ```javascript
  /// // Example: Desktop pushes products to mobile
  /// const products = [{id: '1', name: 'Product 1', ...}];
  /// await fetch('https://your-mobile-app/api/products/receive', {
  ///   method: 'POST',
  ///   headers: {'Content-Type': 'application/json'},
  ///   body: JSON.stringify({products: products})
  /// });
  /// ```
  static Future<SyncResult> receiveProductsPush(
    List<ProductModel> products,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_customBaseUrl/api/products/receive'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'products': products.map((p) => p.toMap()).toList(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SyncResult(
          success: true,
          message:
              'Received ${data['inserted'] ?? products.length} products from desktop',
          inserted: data['inserted'] ?? products.length,
          updated: data['updated'] ?? 0,
          total: data['total'] ?? products.length,
        );
      } else {
        return SyncResult(
          success: false,
          message: 'Failed to receive products: ${response.statusCode}',
          inserted: 0,
          updated: 0,
          total: 0,
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Error receiving products: $e',
        inserted: 0,
        updated: 0,
        total: 0,
      );
    }
  }

  /// Receive customers PUSHED from desktop software
  /// Desktop software calls this endpoint to push data to mobile
  ///
  /// Desktop software usage:
  /// ```javascript
  /// // Example: Desktop pushes customers to mobile
  /// const customers = [{id: '1', name: 'Customer 1', ...}];
  /// await fetch('https://your-mobile-app/api/customers/receive', {
  ///   method: 'POST',
  ///   headers: {'Content-Type': 'application/json'},
  ///   body: JSON.stringify({customers: customers})
  /// });
  /// ```
  static Future<SyncResult> receiveCustomersPush(
    List<CustomerModel> customers,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_customBaseUrl/api/customers/receive'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'customers': customers.map((c) => c.toMap()).toList(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SyncResult(
          success: true,
          message:
              'Received ${data['inserted'] ?? customers.length} customers from desktop',
          inserted: data['inserted'] ?? customers.length,
          updated: data['updated'] ?? 0,
          total: data['total'] ?? customers.length,
        );
      } else {
        return SyncResult(
          success: false,
          message: 'Failed to receive customers: ${response.statusCode}',
          inserted: 0,
          updated: 0,
          total: 0,
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Error receiving customers: $e',
        inserted: 0,
        updated: 0,
        total: 0,
      );
    }
  }

  /// Fetch products from desktop API (GET request)
  static Future<List<ProductModel>> fetchProductsFromDesktop() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_customBaseUrl/api/products'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> productsJson = data['data'];
          return productsJson
              .map(
                (json) => ProductModel(
                  id: json['id'] ?? '',
                  name: json['name'] ?? '',
                  category: json['category'] ?? '',
                  sku: json['sku'] ?? '',
                  price: (json['price'] ?? 0).toDouble(),
                  stock: json['stock'] ?? 0,
                  description: json['description'],
                  createdAt: json['createdAt'] != null
                      ? DateTime.parse(json['createdAt'])
                      : DateTime.now(),
                  updatedAt: json['updatedAt'] != null
                      ? DateTime.parse(json['updatedAt'])
                      : DateTime.now(),
                ),
              )
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch customers from desktop API (GET request)
  static Future<List<CustomerModel>> fetchCustomersFromDesktop() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_customBaseUrl/api/customers'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> customersJson = data['data'];
          return customersJson
              .map(
                (json) => CustomerModel(
                  id: json['id'] ?? '',
                  name: json['name'] ?? '',
                  phone: json['phone'],
                  mobile: json['mobile'],
                  gstin: json['gstin'],
                  address: json['address'] ?? '',
                  area: json['area'] ?? '',
                  route: json['route'],
                  salesmanId: json['salesmanId'],
                  company: json['company'],
                  outstanding: (json['outstanding'] ?? 0).toDouble(),
                  lastVisit: json['lastVisit'],
                  createdAt: json['createdAt'] != null
                      ? DateTime.parse(json['createdAt'])
                      : DateTime.now(),
                  updatedAt: json['updatedAt'] != null
                      ? DateTime.parse(json['updatedAt'])
                      : DateTime.now(),
                ),
              )
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Check if desktop server is reachable
  static Future<bool> checkServerConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_customBaseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Result class for sync operations
class SyncResult {
  final bool success;
  final String message;
  final int inserted;
  final int updated;
  final int total;

  SyncResult({
    required this.success,
    required this.message,
    required this.inserted,
    required this.updated,
    required this.total,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, inserted: $inserted, updated: $updated, total: $total)';
  }
}
