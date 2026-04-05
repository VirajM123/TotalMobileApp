import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:fl_chart/fl_chart.dart';

// Define models inline if missing
enum UserRole {
  distributor,
  salesman,
}

enum OrderStatus {
  pending,
  taken,
  dispatched,
  delivered,
  cancelled,
}

enum OrderType {
  regular,
  urgent,
}

enum PaymentMode {
  cash,
  upi,
  bankTransfer,
  credit,
  partial,
  cheque,
  chequeWithCash,
}

enum UpiType {
  gpay,
  phonepe,
  paytm,
  other,
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;
  final String? distributorId;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.createdAt,
    required this.isActive,
    this.distributorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'distributorId': distributorId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['fullName'] ?? map['name'] ?? '',
      phone: map['phoneNumber'] ?? map['phone'] ?? '',
      role: map['role'] == 'distributor' ? UserRole.distributor : UserRole.salesman,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
      distributorId: map['distributorId'] ?? map['distributor_id'],
    );
  }
}

class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final String? mobile;
  final String area;
  final String? route;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final String? createdBy;
  final String? customerId;
  final String? distributorId;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.mobile,
    required this.area,
    this.route,
    this.address,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'active',
    this.createdBy,
    this.customerId,
    this.distributorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'customer_id': customerId,
      'phone': phone ?? mobile,
      'area': area,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status,
      'created_by': createdBy,
      'distributor_id': distributorId,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map, String id) {
    return CustomerModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? map['mobile'],
      mobile: map['mobile'] ?? map['phone'],
      area: map['area'] ?? '',
      route: map['route'],
      address: map['address'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
      status: map['status'] ?? 'active',
      createdBy: map['created_by'],
      customerId: map['customer_id'],
      distributorId: map['distributor_id'],
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String sku;
  final double price;
  final String category;
  final int stock;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? distributorId;
  final bool isActive;
  final List<String> images;
  final List<String> tags;

  ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.category,
    required this.stock,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.distributorId,
    this.isActive = true,
    this.images = const [],
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'productName': name,
      'sku': sku,
      'price': price,
      'category': category,
      'stock': stock >= 10 ? 'Available' : 'Low Stock',
      'stockQuantity': stock,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'distributorId': distributorId,
      'isActive': isActive,
      'images': images,
      'tags': tags,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['productName'] ?? map['name'] ?? '',
      sku: map['sku'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      stock: map['stockQuantity'] ?? map['stock'] ?? 0,
      description: map['description'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      createdBy: map['createdBy'],
      distributorId: map['distributorId'],
      isActive: map['isActive'] ?? true,
      images: List<String>.from(map['images'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}

class SalesmanModel {
  final String id;
  final String salesmanId;
  final String name;
  final String email;
  final String phone;
  final String distributorId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final double targetAmount;
  final double achievedAmount;
  final double commissionRate;
  final String areaAssigned;
  final String address;
  final DateTime joiningDate;
  final Map<String, dynamic> performanceMetrics;
  final Map<String, dynamic> bankDetails;
  final Map<String, dynamic> documents;
  final String notes;

  SalesmanModel({
    required this.id,
    required this.salesmanId,
    required this.name,
    required this.email,
    required this.phone,
    required this.distributorId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'active',
    this.targetAmount = 0,
    this.achievedAmount = 0,
    this.commissionRate = 0,
    this.areaAssigned = '',
    this.address = '',
    required this.joiningDate,
    this.performanceMetrics = const {},
    this.bankDetails = const {},
    this.documents = const {},
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'salesman_id': salesmanId,
      'name': name,
      'email': email,
      'phone': phone,
      'distributor_id': distributorId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status,
      'target_amount': targetAmount,
      'achieved_amount': achievedAmount,
      'commission_rate': commissionRate,
      'area_assigned': areaAssigned,
      'address': address,
      'joining_date': joiningDate.toIso8601String(),
      'performance_metrics': performanceMetrics,
      'bank_details': bankDetails,
      'documents': documents,
      'notes': notes,
    };
  }

  factory SalesmanModel.fromMap(Map<String, dynamic> map, String id) {
    return SalesmanModel(
      id: id,
      salesmanId: map['salesman_id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      distributorId: map['distributor_id'] ?? '',
      createdBy: map['created_by'] ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
      status: map['status'] ?? 'active',
      targetAmount: (map['target_amount'] ?? 0).toDouble(),
      achievedAmount: (map['achieved_amount'] ?? 0).toDouble(),
      commissionRate: (map['commission_rate'] ?? 0).toDouble(),
      areaAssigned: map['area_assigned'] ?? '',
      address: map['address'] ?? '',
      joiningDate: map['joining_date'] != null ? DateTime.parse(map['joining_date']) : DateTime.now(),
      performanceMetrics: map['performance_metrics'] ?? {},
      bankDetails: map['bank_details'] ?? {},
      documents: map['documents'] ?? {},
      notes: map['notes'] ?? '',
    );
  }
}

class OrderItemModel {
  final String id;
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double rate;
  final double amount;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.rate,
    required this.amount,
  });
}

class OrderTimelineEvent {
  final String id;
  final String status;
  final String message;
  final DateTime timestamp;

  OrderTimelineEvent({
    required this.id,
    required this.status,
    required this.message,
    required this.timestamp,
  });
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String areaName;
  final String routeName;
  final String salesmanId;
  final String salesmanName;
  final List<OrderItemModel> items;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final OrderStatus status;
  final OrderType orderType;
  final PaymentMode? paymentMode;
  final DateTime? scheduledDate;
  final String? notes;
  final String? internalNotes;
  final DateTime createdAt;
  final List<OrderTimelineEvent> timeline;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.areaName,
    required this.routeName,
    required this.salesmanId,
    required this.salesmanName,
    required this.items,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.status,
    required this.orderType,
    this.paymentMode,
    this.scheduledDate,
    this.notes,
    this.internalNotes,
    required this.createdAt,
    required this.timeline,
  });

  String get statusDisplay {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.taken:
        return 'Order Taken';
      case OrderStatus.dispatched:
        return 'Dispatched';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class OrderTemplateModel {
  final String id;
  final String name;
  final List<String> productIds;
  final String? description;

  OrderTemplateModel({
    required this.id,
    required this.name,
    required this.productIds,
    this.description,
  });
}

// Helper function to show SnackBar safely
void showSafeSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// API Service for backend communication
class ApiService {
  static String get apiUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:3000/api';
    }
    
    return 'http://localhost:3000/api';
  }

  // Customer APIs
  static Future<Map<String, dynamic>> addCustomer(Map<String, dynamic> customerData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/customers'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(customerData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Failed to add customer: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error adding customer: $e');
    }
  }

  // Fixed: Use correct endpoint with distributorId parameter
  static Future<List<dynamic>> getCustomers(String distributorId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/customers/$distributorId'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Product APIs
  static Future<Map<String, dynamic>> addProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(productData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Failed to add product: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error adding product: $e');
    }
  }

  // Fixed: Use correct endpoint with distributorId parameter
  static Future<List<dynamic>> getProducts(String distributorId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/products/$distributorId'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Salesman APIs
  static Future<Map<String, dynamic>> addSalesman(Map<String, dynamic> salesmanData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/salesmen'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(salesmanData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Failed to add salesman: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error adding salesman: $e');
    }
  }

  // Fixed: Use correct endpoint with distributorId parameter
  static Future<List<dynamic>> getSalesmen(String distributorId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/salesmen/$distributorId'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

// Mock Services (modified to use API)
class CustomerService {
  List<CustomerModel> _customers = [];
  String? _currentDistributorId;

  void setDistributorId(String distributorId) {
    _currentDistributorId = distributorId;
  }

  Future<List<CustomerModel>> getCustomers() async {
    if (_currentDistributorId == null) return [];
    
    try {
      final response = await ApiService.getCustomers(_currentDistributorId!);
      _customers = response.map((data) => CustomerModel.fromMap(data, data['_id']?.toString() ?? '')).toList();
      return _customers;
    } catch (e) {
      // Fallback to mock data if API fails
      await Future.delayed(const Duration(milliseconds: 300));
      _customers = [
        CustomerModel(
          id: 'cust_001',
          name: 'Ramesh Patel',
          phone: '9876543210',
          mobile: '9876543210',
          area: 'Andheri East',
          route: 'Route A',
          address: '123, Main Road, Andheri East',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
          customerId: 'GK001',
          distributorId: _currentDistributorId,
        ),
        CustomerModel(
          id: 'cust_002',
          name: 'Suresh Sharma',
          phone: '9876543211',
          mobile: '9876543211',
          area: 'Bandra West',
          route: 'Route B',
          address: '456, Linking Road, Bandra West',
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
          updatedAt: DateTime.now(),
          customerId: 'GK002',
          distributorId: _currentDistributorId,
        ),
      ];
      return _customers;
    }
  }

  Future<void> addCustomer(CustomerModel customer) async {
    try {
      final response = await ApiService.addCustomer(customer.toMap());
      final newCustomer = CustomerModel.fromMap(response, response['_id']?.toString() ?? customer.id);
      _customers.add(newCustomer);
    } catch (e) {
      // Fallback to local storage
      _customers.add(customer);
    }
  }

  Future<void> syncCustomers(List<CustomerModel> customers) async {
    _customers = customers;
  }
}

class ProductService {
  List<ProductModel> _products = [];
  String? _currentDistributorId;
  String? _currentCreatedBy;

  void setDistributorInfo(String distributorId, String createdBy) {
    _currentDistributorId = distributorId;
    _currentCreatedBy = createdBy;
  }

  Future<List<ProductModel>> getProducts() async {
    if (_currentDistributorId == null) return [];
    
    try {
      final response = await ApiService.getProducts(_currentDistributorId!);
      _products = response.map((data) => ProductModel.fromMap(data, data['_id']?.toString() ?? '')).toList();
      return _products;
    } catch (e) {
      // Fallback to mock data
      await Future.delayed(const Duration(milliseconds: 300));
      _products = [
        ProductModel(
          id: 'prod_001',
          name: 'Premium Rice 5kg',
          sku: 'RICE005',
          price: 250,
          category: 'Rice',
          stock: 100,
          description: 'High quality basmati rice',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: _currentCreatedBy,
          distributorId: _currentDistributorId,
        ),
        ProductModel(
          id: 'prod_002',
          name: 'Wheat Flour 5kg',
          sku: 'FLOUR005',
          price: 180,
          category: 'Flour',
          stock: 150,
          description: 'Whole wheat flour',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: _currentCreatedBy,
          distributorId: _currentDistributorId,
        ),
      ];
      return _products;
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      final response = await ApiService.addProduct(product.toMap());
      final newProduct = ProductModel.fromMap(response, response['_id']?.toString() ?? product.id);
      _products.add(newProduct);
    } catch (e) {
      _products.add(product);
    }
  }

  Future<void> syncProducts(List<ProductModel> products) async {
    _products = products;
  }
}

class SalesmanService {
  List<SalesmanModel> _salesmen = [];
  String? _currentDistributorId;
  String? _currentCreatedBy;

  void setDistributorInfo(String distributorId, String createdBy) {
    _currentDistributorId = distributorId;
    _currentCreatedBy = createdBy;
  }

  Future<List<SalesmanModel>> getSalesmen() async {
    if (_currentDistributorId == null) return [];
    
    try {
      final response = await ApiService.getSalesmen(_currentDistributorId!);
      _salesmen = response.map((data) => SalesmanModel.fromMap(data, data['_id']?.toString() ?? '')).toList();
      return _salesmen;
    } catch (e) {
      // Fallback to mock data
      await Future.delayed(const Duration(milliseconds: 300));
      _salesmen = [
        SalesmanModel(
          id: 'salesman_001',
          salesmanId: 'SM001',
          name: 'John Salesman',
          email: 'john@demo.com',
          phone: '9876543211',
          distributorId: _currentDistributorId!,
          createdBy: _currentCreatedBy!,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          joiningDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ];
      return _salesmen;
    }
  }

  Future<void> addSalesman(SalesmanModel salesman) async {
    try {
      final response = await ApiService.addSalesman(salesman.toMap());
      final newSalesman = SalesmanModel.fromMap(response, response['_id']?.toString() ?? salesman.id);
      _salesmen.add(newSalesman);
    } catch (e) {
      _salesmen.add(salesman);
    }
  }
}

class OrderService {
  List<OrderModel> _orders = [];
  List<OrderModel> _draftOrders = [];

  Future<List<OrderModel>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _orders = [
      OrderModel(
        id: 'ord_001',
        orderNumber: 'ORD001',
        customerId: 'cust_001',
        customerName: 'Ramesh Patel',
        customerPhone: '9876543210',
        areaName: 'Andheri East',
        routeName: 'Route A',
        salesmanId: 'salesman_001',
        salesmanName: 'John Salesman',
        items: [
          OrderItemModel(
            id: 'item_001',
            productId: 'prod_001',
            productName: 'Premium Rice 5kg',
            sku: 'RICE005',
            quantity: 2,
            rate: 250,
            amount: 500,
          ),
        ],
        totalAmount: 500,
        paidAmount: 0,
        dueAmount: 500,
        status: OrderStatus.pending,
        orderType: OrderType.regular,
        paymentMode: PaymentMode.credit,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        timeline: [],
      ),
    ];
    return _orders;
  }

  Future<void> createOrder(OrderModel order) async {
    _orders.add(order);
  }

  List<OrderModel> getDraftOrders() {
    return _draftOrders;
  }

  int get todayOrders {
    return _orders.where((o) => 
      o.createdAt.day == DateTime.now().day &&
      o.createdAt.month == DateTime.now().month &&
      o.createdAt.year == DateTime.now().year
    ).length;
  }

  double get totalPendingAmount {
    return _orders.fold(0.0, (sum, o) => sum + o.dueAmount);
  }

  Future<void> recordPayment(String orderId, double amount, PaymentMode mode, {String? reference}) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      final newPaidAmount = order.paidAmount + amount;
      _orders[index] = OrderModel(
        id: order.id,
        orderNumber: order.orderNumber,
        customerId: order.customerId,
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        areaName: order.areaName,
        routeName: order.routeName,
        salesmanId: order.salesmanId,
        salesmanName: order.salesmanName,
        items: order.items,
        totalAmount: order.totalAmount,
        paidAmount: newPaidAmount,
        dueAmount: order.totalAmount - newPaidAmount,
        status: newPaidAmount >= order.totalAmount ? OrderStatus.delivered : order.status,
        orderType: order.orderType,
        paymentMode: mode,
        scheduledDate: order.scheduledDate,
        notes: order.notes,
        internalNotes: order.internalNotes,
        createdAt: order.createdAt,
        timeline: order.timeline,
      );
    }
  }
}

class SyncService {
  static Future<SyncResult> syncCustomersFromDesktop() async {
    await Future.delayed(const Duration(seconds: 1));
    return SyncResult(success: true, message: 'Synced 10 customers from desktop');
  }

  static Future<SyncResult> syncProductsFromDesktop() async {
    await Future.delayed(const Duration(seconds: 1));
    return SyncResult(success: true, message: 'Synced 25 products from desktop');
  }
}

class SyncResult {
  final bool success;
  final String message;
  SyncResult({required this.success, required this.message});
}

class ImportService {
  static Future<List<ProductModel>?> importProductsFromCsv() async {
    await Future.delayed(const Duration(seconds: 1));
    return null;
  }

  static Future<List<CustomerModel>?> importCustomersFromCsv() async {
    await Future.delayed(const Duration(seconds: 1));
    return null;
  }
}

class PdfService {
  static Future<String?> downloadOrderPdf(OrderModel order) async {
    await Future.delayed(const Duration(seconds: 1));
    return '/storage/emulated/0/Download/order_${order.orderNumber}.pdf';
  }

  static Future<void> shareOrderPdf(OrderModel order) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}

// Cart Item Data Model for Salesman Dashboard
class CartItemData {
  String productId;
  String productName;
  String sku;
  int quantity;
  double rate;
  double schPer;
  double schAmt;
  double grossAmt;
  double netAmt;

  CartItemData({
    required this.productId,
    required this.productName,
    required this.sku,
    this.quantity = 1,
    this.rate = 0,
    this.schPer = 0,
    this.schAmt = 0,
    this.grossAmt = 0,
    this.netAmt = 0,
  });

  void calculate() {
    grossAmt = quantity * rate;
    schAmt = (schPer / 100) * grossAmt;
    netAmt = grossAmt - schAmt;
  }
}

// ==================== DISTRIBUTOR DASHBOARD (FULL FEATURED) ====================
class DistributorDashboardEnhanced extends StatefulWidget {
  final UserModel? loggedInUser;
  
  const DistributorDashboardEnhanced({super.key, this.loggedInUser});

  @override
  State<DistributorDashboardEnhanced> createState() =>
      _DistributorDashboardEnhancedState();
}

class _DistributorDashboardEnhancedState
    extends State<DistributorDashboardEnhanced> {
  // Color constants
  static const Color primaryBlue = Color(0xFF1A3B70);
  static const Color accentTeal = Color(0xFF00A68A);
  static const Color secondaryBlue = Color(0xFF2C599D);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53935);
  static const Color cardPurple = Color(0xFF9B59B6);

  // Theme mode
  ThemeMode _themeMode = ThemeMode.light;

  int _selectedIndex = 0;
  bool _isSidebarOpen = false;

  // Services
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  final SalesmanService _salesmanService = SalesmanService();

  // Current distributor - Load from logged in user
  late UserModel _currentDistributor;

  // Data
  List<CustomerModel> _customers = [];
  List<ProductModel> _products = [];
  List<OrderModel> _orders = [];
  List<SalesmanModel> _salesmen = [];
  List<OrderTemplateModel> _orderTemplates = [];
  bool _isLoading = true;

  // Sync from desktop
  final SyncService _syncService = SyncService();
  bool _isSyncing = false;
  final Map<String, int> _cart = {};

  // Order creation state
  int _orderStep = 1;
  String? _selectedCustomerId;
  String? _selectedSalesmanId;
  OrderType _selectedOrderType = OrderType.regular;
  DateTime? _scheduledDate;
  PaymentMode _selectedPaymentMode = PaymentMode.credit;
  String _orderNotes = '';
  String _internalNotes = '';

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;

  // Search type (Customer, Product, Order)
  String _searchType = 'All';
  final TextEditingController _orderSearchController = TextEditingController();
  String _orderSearchQuery = '';

  // Order filter by salesman
  String? _selectedOrderSalesmanId;

  // Order selection for posting to desktop
  final Set<String> _selectedOrderIds = {};
  bool _isPostingToDesktop = false;

  // Customer search for Create Order
  final TextEditingController _customerSearchController =
      TextEditingController();
  String _customerSearchQuery = '';

  // Product search for Create Order
  final TextEditingController _productSearchController =
      TextEditingController();
  String _productSearchQuery = '';

  // Salesman search
  final TextEditingController _salesmanSearchController =
      TextEditingController();
  String _salesmanSearchQuery = '';

  // Payment collection
  final TextEditingController _paymentAmountController =
      TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _chequeNumberController = TextEditingController();
  final TextEditingController _chequeDateController = TextEditingController();
  final TextEditingController _chequeAmountController = TextEditingController();
  final TextEditingController _cashAmountController = TextEditingController();
  final TextEditingController _transactionNumberController =
      TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  // Payment dialog state
  UpiType? _selectedUpiType;
  String? _paymentScreenshotPath;

  // Analytics time filter
  String _analyticsTimeFilter = 'month';

  // Monthly target
  double _monthlyTarget = 500000;

  // Draft orders
  List<OrderModel> _draftOrders = [];

  // Get filtered products
  List<ProductModel> get filteredProducts {
    var products = _products;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      products = products
          .where(
            (p) =>
                p.name.toLowerCase().contains(query) ||
                p.sku.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query),
          )
          .toList();
    }
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      products = products
          .where((p) => p.category == _selectedCategory)
          .toList();
    }
    if (_minPrice != null) {
      products = products.where((p) => p.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      products = products.where((p) => p.price <= _maxPrice!).toList();
    }
    return products;
  }

  // Get categories
  List<String> get categories {
    return _products.map((p) => p.category).toSet().toList();
  }

  // Get filtered customers
  List<CustomerModel> get filteredCustomers {
    var customers = _customers;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      customers = customers
          .where(
            (c) =>
                c.name.toLowerCase().contains(query) ||
                c.area.toLowerCase().contains(query) ||
                (c.phone?.toLowerCase().contains(query) ?? false) ||
                (c.mobile?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }
    return customers;
  }

  // Get filtered customers for Create Order
  List<CustomerModel> get orderFilteredCustomers {
    if (_customerSearchQuery.isEmpty) return _customers;
    final query = _customerSearchQuery.toLowerCase();
    return _customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(query) ||
              c.area.toLowerCase().contains(query) ||
              (c.phone?.toLowerCase().contains(query) ?? false) ||
              (c.mobile?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  // Get filtered products for Create Order
  List<ProductModel> get orderFilteredProducts {
    if (_productSearchQuery.isEmpty) return _products;
    final query = _productSearchQuery.toLowerCase();
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(query) ||
              p.sku.toLowerCase().contains(query) ||
              p.category.toLowerCase().contains(query),
        )
        .toList();
  }

  // Get filtered salesmen
  List<SalesmanModel> get filteredSalesmen {
    var salesmen = _salesmen;
    if (_salesmanSearchQuery.isNotEmpty) {
      final query = _salesmanSearchQuery.toLowerCase();
      salesmen = salesmen
          .where(
            (s) =>
                s.name.toLowerCase().contains(query) ||
                s.email.toLowerCase().contains(query),
          )
          .toList();
    }
    return salesmen;
  }

  // Get customer outstanding
  double getCustomerOutstanding(String customerId) {
    return _orders
        .where(
          (o) =>
              o.customerId == customerId && o.status != OrderStatus.cancelled,
        )
        .fold(0.0, (sum, o) => sum + o.dueAmount);
  }

  // Get last order for customer
  OrderModel? getLastOrderForCustomer(String customerId) {
    final customerOrders = _orders
        .where((o) => o.customerId == customerId)
        .toList();
    if (customerOrders.isEmpty) return null;
    customerOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return customerOrders.first;
  }

  // Get last order for salesman
  OrderModel? getLastOrderForSalesman(String salesmanId) {
    final salesmanOrders = _orders
        .where((o) => o.salesmanId == salesmanId)
        .toList();
    if (salesmanOrders.isEmpty) return null;
    salesmanOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return salesmanOrders.first;
  }

  // Get salesman orders count
  int getSalesmanOrderCount(String salesmanId) {
    return _orders.where((o) => o.salesmanId == salesmanId).length;
  }

  // Get salesman total revenue
  double getSalesmanRevenue(String salesmanId) {
    return _orders
        .where(
          (o) =>
              o.salesmanId == salesmanId && o.status != OrderStatus.cancelled,
        )
        .fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  // Get salesman total collection
  double getSalesmanCollection(String salesmanId) {
    return _orders
        .where(
          (o) =>
              o.salesmanId == salesmanId && o.status != OrderStatus.cancelled,
        )
        .fold(0.0, (sum, o) => sum + o.paidAmount);
  }

  // Get last sale for product
  OrderModel? getLastSaleForProduct(String productId) {
    final productOrders = _orders
        .where((o) => o.items.any((item) => item.productId == productId))
        .toList();
    if (productOrders.isEmpty) return null;
    productOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return productOrders.first;
  }

  // Get filtered orders by salesman
  List<OrderModel> get filteredOrders {
    var orders = _orders;
    if (_selectedOrderSalesmanId != null) {
      orders = orders
          .where((o) => o.salesmanId == _selectedOrderSalesmanId)
          .toList();
    }
    if (_orderSearchQuery.isNotEmpty) {
      final query = _orderSearchQuery.toLowerCase();
      orders = orders
          .where(
            (o) =>
                o.orderNumber.toLowerCase().contains(query) ||
                o.customerName.toLowerCase().contains(query) ||
                o.salesmanName.toLowerCase().contains(query),
          )
          .toList();
    }
    return orders;
  }

  // Get orders for a specific salesman or all
  List<OrderModel> getOrdersForSalesman(String? salesmanId) {
    if (salesmanId == null) return _orders;
    return _orders.where((o) => o.salesmanId == salesmanId).toList();
  }

  // Post orders to desktop
  Future<void> _postOrdersToDesktop() async {
    if (_selectedOrderIds.isEmpty) {
      showSafeSnackBar(context, 'Please select at least one order to post', backgroundColor: warningOrange);
      return;
    }

    setState(() => _isPostingToDesktop = true);

    try {
      final selectedOrders = _orders
          .where((o) => _selectedOrderIds.contains(o.id))
          .toList();

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Post to Desktop'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to post ${selectedOrders.length} order(s) to desktop:',
              ),
              const SizedBox(height: 12),
              ...selectedOrders.map(
                (o) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• ${o.orderNumber} - ₹${o.totalAmount.toStringAsFixed(0)}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Total: ₹${selectedOrders.fold<double>(0, (sum, o) => sum + o.totalAmount).toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
              child: const Text('Post to Desktop'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          showSafeSnackBar(context, '✅ Successfully posted ${selectedOrders.length} order(s) to desktop!', backgroundColor: successGreen);

          setState(() {
            _selectedOrderIds.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error posting orders: $e', backgroundColor: errorRed);
      }
    } finally {
      if (mounted) {
        setState(() => _isPostingToDesktop = false);
      }
    }
  }

  // Toggle order selection
  void _toggleOrderSelection(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  // Select all orders
  void _selectAllOrders() {
    setState(() {
      if (_selectedOrderIds.length == filteredOrders.length) {
        _selectedOrderIds.clear();
      } else {
        _selectedOrderIds.clear();
        _selectedOrderIds.addAll(filteredOrders.map((o) => o.id));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize current distributor from passed user or create default
    if (widget.loggedInUser != null) {
      _currentDistributor = widget.loggedInUser!;
    } else {
      _currentDistributor = UserModel(
        id: 'dist_001',
        email: 'distributor@demo.com',
        name: 'Admin Distributor',
        phone: '+91 9876543210',
        role: UserRole.distributor,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        isActive: true,
      );
    }
    
    // Set distributor info in services
    _customerService.setDistributorId(_currentDistributor.id);
    _productService.setDistributorInfo(_currentDistributor.id, _currentDistributor.email);
    _salesmanService.setDistributorInfo(_currentDistributor.id, _currentDistributor.email);
    
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _customerService.getCustomers(),
      _productService.getProducts(),
      _orderService.getOrders(),
      _salesmanService.getSalesmen(),
    ]);

    setState(() {
      _customers = results[0] as List<CustomerModel>;
      _products = results[1] as List<ProductModel>;
      _orders = results[2] as List<OrderModel>;
      _salesmen = results[3] as List<SalesmanModel>;
      _draftOrders = _orderService.getDraftOrders();
      _isLoading = false;
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Cart methods
  void addToCart(String productId, {int quantity = 1}) {
    setState(() {
      _cart[productId] = (_cart[productId] ?? 0) + quantity;
    });
  }

  void removeFromCart(String productId) {
    setState(() {
      final currentQty = _cart[productId];
      if (currentQty == null) return;
      if (currentQty > 1) {
        _cart[productId] = currentQty - 1;
      } else {
        _cart.remove(productId);
      }
    });
  }

  void updateCartQuantity(String productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(productId);
      } else {
        _cart[productId] = quantity;
      }
    });
  }

  double get cartTotal {
    double total = 0;
    _cart.forEach((productId, qty) {
      try {
        final product = _products.firstWhere((p) => p.id == productId);
        total += product.price * qty;
      } catch (e) {
        // Product not found
      }
    });
    return total;
  }

  int get cartItemCount => _cart.values.fold(0, (a, b) => a + b);

  // Submit order
  Future<void> submitOrder() async {
    if (_selectedCustomerId == null || _cart.isEmpty) return;

    final customer = _customers.firstWhere((c) => c.id == _selectedCustomerId);
    final salesman = _selectedSalesmanId != null
        ? _salesmen.firstWhere((s) => s.id == _selectedSalesmanId)
        : _salesmen.first;

    final order = OrderModel(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}',
      orderNumber:
          'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      customerId: _selectedCustomerId!,
      customerName: customer.name,
      customerPhone: customer.phone ?? customer.mobile ?? '',
      areaName: customer.area,
      routeName: customer.route ?? '',
      salesmanId: salesman.id,
      salesmanName: salesman.name,
      items: _cart.entries.map((entry) {
        final product = _products.firstWhere((p) => p.id == entry.key);
        return OrderItemModel(
          id: 'item_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
          productId: product.id,
          productName: product.name,
          sku: product.sku,
          quantity: entry.value,
          rate: product.price,
          amount: product.price * entry.value,
        );
      }).toList(),
      totalAmount: cartTotal,
      paidAmount:
          _selectedPaymentMode == PaymentMode.cash ||
              _selectedPaymentMode == PaymentMode.upi
          ? cartTotal
          : 0,
      dueAmount: _selectedPaymentMode == PaymentMode.credit ? cartTotal : 0,
      status: OrderStatus.pending,
      orderType: _selectedOrderType,
      paymentMode: _selectedPaymentMode,
      scheduledDate: _scheduledDate,
      notes: _orderNotes,
      internalNotes: _internalNotes,
      createdAt: DateTime.now(),
      timeline: [
        OrderTimelineEvent(
          id: 'timeline_${DateTime.now().millisecondsSinceEpoch}',
          status: 'pending',
          message: 'Order created and pending',
          timestamp: DateTime.now(),
        ),
      ],
    );

    await _orderService.createOrder(order);

    if (mounted) {
      showSafeSnackBar(context, '✅ Order submitted successfully!', backgroundColor: successGreen);
      _clearCart();
      _loadData();
    }
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _selectedCustomerId = null;
      _selectedSalesmanId = null;
      _orderStep = 1;
      _orderNotes = '';
      _internalNotes = '';
      _selectedOrderType = OrderType.regular;
      _scheduledDate = null;
      _selectedPaymentMode = PaymentMode.credit;
    });
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  Future<void> _importProducts() async {
    try {
      final products = await ImportService.importProductsFromCsv();
      if (products != null && products.isNotEmpty) {
        await _productService.syncProducts(products);
        await _loadData();
        if (mounted) {
          showSafeSnackBar(context, '✅ Imported ${products.length} products successfully!', backgroundColor: successGreen);
        }
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error importing products: $e', backgroundColor: errorRed);
      }
    }
  }

  Future<void> _importCustomers() async {
    try {
      final customers = await ImportService.importCustomersFromCsv();
      if (customers != null && customers.isNotEmpty) {
        await _customerService.syncCustomers(customers);
        await _loadData();
        if (mounted) {
          showSafeSnackBar(context, '✅ Imported ${customers.length} customers successfully!', backgroundColor: successGreen);
        }
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error importing customers: $e', backgroundColor: errorRed);
      }
    }
  }

  Future<void> _syncCustomersFromDesktop() async {
    setState(() => _isSyncing = true);
    try {
      final result = await SyncService.syncCustomersFromDesktop();
      if (mounted) {
        showSafeSnackBar(context, result.message, backgroundColor: result.success ? successGreen : errorRed);
        if (result.success) {
          await _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error: $e', backgroundColor: errorRed);
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _syncProductsFromDesktop() async {
    setState(() => _isSyncing = true);
    try {
      final result = await SyncService.syncProductsFromDesktop();
      if (mounted) {
        showSafeSnackBar(context, result.message, backgroundColor: result.success ? successGreen : errorRed);
        if (result.success) {
          await _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error: $e', backgroundColor: errorRed);
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final areaController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: areaController,
                decoration: const InputDecoration(
                  labelText: 'Area',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final customer = CustomerModel(
                  id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  phone: phoneController.text,
                  area: areaController.text,
                  address: addressController.text,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  customerId: 'GK${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 13)}',
                  createdBy: _currentDistributor.email,
                  distributorId: _currentDistributor.id,
                );
                await _customerService.addCustomer(customer);
                await _loadData();
                if (mounted) {
                  Navigator.pop(context);
                  showSafeSnackBar(context, 'Customer added successfully!', backgroundColor: successGreen);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                final product = ProductModel(
                  id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  sku: skuController.text,
                  price: double.tryParse(priceController.text) ?? 0,
                  category: categoryController.text,
                  stock: int.tryParse(stockController.text) ?? 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  createdBy: _currentDistributor.email,
                  distributorId: _currentDistributor.id,
                );
                await _productService.addProduct(product);
                await _loadData();
                if (mounted) {
                  Navigator.pop(context);
                  showSafeSnackBar(context, 'Product added successfully!', backgroundColor: successGreen);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddSalesmanDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final areaController = TextEditingController();
    final addressController = TextEditingController();
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Salesman'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: areaController,
                decoration: const InputDecoration(
                  labelText: 'Area Assigned',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  emailController.text.isNotEmpty) {
                final salesman = SalesmanModel(
                  id: 'salesman_${DateTime.now().millisecondsSinceEpoch}',
                  salesmanId: 'SM${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 13)}',
                  name: nameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  distributorId: _currentDistributor.id,
                  createdBy: _currentDistributor.email,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  areaAssigned: areaController.text,
                  address: addressController.text,
                  targetAmount: double.tryParse(targetController.text) ?? 0,
                  joiningDate: DateTime.now(),
                );
                await _salesmanService.addSalesman(salesman);
                await _loadData();
                if (mounted) {
                  Navigator.pop(context);
                  showSafeSnackBar(context, 'Salesman added successfully!', backgroundColor: successGreen);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _isSidebarOpen = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Stack(
          children: [
            Container(color: Colors.black54),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: primaryBlue,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                child: Text(
                                  _currentDistributor.name
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentDistributor.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Distributor',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    setState(() => _isSidebarOpen = false),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: [
                              _buildSidebarItem(
                                Icons.dashboard,
                                'Dashboard',
                                0,
                              ),
                              _buildSidebarItem(Icons.pie_chart, 'Overview', 1),
                              _buildSidebarItem(Icons.people, 'Customers', 2),
                              _buildSidebarItem(
                                Icons.inventory_2,
                                'Products',
                                3,
                              ),
                              _buildSidebarItem(Icons.badge, 'Salesmen', 4),
                              _buildSidebarItem(
                                Icons.receipt_long,
                                'Orders',
                                5,
                              ),
                              _buildSidebarItem(
                                Icons.add_shopping_cart,
                                'New Order',
                                6,
                              ),
                              _buildSidebarItem(Icons.payment, 'Payments', 7),
                              _buildSidebarItem(
                                Icons.description,
                                'Templates',
                                8,
                              ),
                              _buildSidebarItem(
                                Icons.analytics,
                                'Analytics',
                                9,
                              ),
                              const Divider(height: 32),
                              _buildSidebarItem(
                                Icons.logout,
                                'Logout',
                                -1,
                                isLogout: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String label,
    int index, {
    bool isLogout = false,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout
            ? errorRed
            : (isSelected ? primaryBlue : Colors.grey[600]),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isLogout
              ? errorRed
              : (isSelected ? primaryBlue : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: primaryBlue.withOpacity(0.1),
      onTap: () {
        if (isLogout) {
          setState(() => _isSidebarOpen = false);
          _logout();
        } else {
          setState(() {
            _selectedIndex = index;
            _isSidebarOpen = false;
          });
        }
      },
    );
  }

  Widget _buildTemplatesSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Order Templates',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('Coming soon...', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Analytics',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('Coming soon...', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  void _showOrderDetailsDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order ${order.orderNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Customer:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(order.customerName),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Phone:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(order.customerPhone),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Area:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(order.areaName),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              order.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.statusDisplay,
                            style: TextStyle(
                              color: _getStatusColor(order.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: order.items.length,
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'SKU: ${item.sku}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Qty: ${item.quantity}'),
                              Text('Rate: ₹${item.rate.toStringAsFixed(2)}'),
                              Text(
                                '₹${item.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: accentTeal,
                    ),
                  ),
                ],
              ),
              if (order.paidAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Paid:', style: TextStyle(color: Colors.green)),
                    Text(
                      '₹${order.paidAmount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              if (order.dueAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Due:', style: TextStyle(color: errorRed)),
                    Text(
                      '₹${order.dueAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: errorRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final path = await PdfService.downloadOrderPdf(order);
                          if (mounted) {
                            Navigator.pop(context);
                            showSafeSnackBar(context, path != null ? 'PDF saved to: $path' : 'Failed to download PDF', backgroundColor: path != null ? successGreen : errorRed);
                          }
                        } catch (e) {
                          if (mounted) {
                            showSafeSnackBar(context, 'Error: $e', backgroundColor: errorRed);
                          }
                        }
                      },
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await PdfService.shareOrderPdf(order);
                        } catch (e) {
                          if (mounted) {
                            showSafeSnackBar(context, 'Error sharing: $e', backgroundColor: errorRed);
                          }
                        }
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share to WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: successGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Distributor Dashboard',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData.light().copyWith(
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      home: Scaffold(
        key: const ValueKey('distributorScaffold'),
        backgroundColor: _themeMode == ThemeMode.dark
            ? const Color(0xFF1A1A2E)
            : const Color(0xFFF5F7FA),
        body: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(),
                ),
              ],
            ),
            if (_isSidebarOpen) _buildSidebarOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = _themeMode == ThemeMode.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      color: primaryBlue,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: Colors.white,
                child: Text(
                  _currentDistributor.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentDistributor.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Distributor Portal',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: _toggleTheme,
                tooltip: isDark ? 'Light Mode' : 'Dark Mode',
              ),
              _headerIcon(Icons.notifications_none, "Alerts"),
              _headerIcon(Icons.logout, "Logout", onTap: _logout),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isSidebarOpen ? Icons.close : Icons.menu,
                  color: Colors.white,
                ),
                onPressed: () =>
                    setState(() => _isSidebarOpen = !_isSidebarOpen),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search products, customers, orders...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.white70),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, String label, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildOverviewSection();
      case 2:
        return _buildCustomersSection();
      case 3:
        return _buildProductsSection();
      case 4:
        return _buildSalesmenSection();
      case 5:
        return _buildOrdersSection();
      case 6:
        return _buildCreateOrderSection();
      case 7:
        return _buildPaymentCollectionSection();
      case 8:
        return _buildTemplatesSection();
      case 9:
        return _buildAnalyticsSection();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final totalRevenue = _orders
        .where((o) => o.status == OrderStatus.delivered)
        .fold<double>(0, (sum, o) => sum + o.totalAmount);
    final todayOrders = _orderService.todayOrders;
    final totalCollection = _orders.fold<double>(
      0,
      (sum, o) => sum + o.paidAmount,
    );
    final totalPending = _orders.fold<double>(0, (sum, o) => sum + o.dueAmount);
    final achievementPercentage = _monthlyTarget > 0
        ? (totalRevenue / _monthlyTarget * 100).clamp(0, 100)
        : 0.0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [accentTeal, Color(0xFF00D9C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _currentDistributor.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Here\'s your business overview! 📊',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Monthly Target',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: achievementPercentage >= 100
                              ? successGreen.withOpacity(0.1)
                              : warningOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${achievementPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: achievementPercentage >= 100
                                ? successGreen
                                : warningOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: achievementPercentage / 100,
                      minHeight: 20,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        achievementPercentage >= 100
                            ? successGreen
                            : accentTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target: ₹${(_monthlyTarget / 1000).toStringAsFixed(0)}K',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Achievement: ₹${(totalRevenue / 1000).toStringAsFixed(1)}K',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    'Today\'s Orders',
                    '$todayOrders',
                    Icons.shopping_bag,
                    primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickStatCard(
                    'Total Revenue',
                    '₹${(totalRevenue / 1000).toStringAsFixed(1)}K',
                    Icons.currency_rupee,
                    successGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    'Collection',
                    '₹${(totalCollection / 1000).toStringAsFixed(1)}K',
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickStatCard(
                    'Pending Dues',
                    '₹${(totalPending / 1000).toStringAsFixed(1)}K',
                    Icons.pending_actions,
                    warningOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    'Customers',
                    '${_customers.length}',
                    Icons.people,
                    cardPurple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickStatCard(
                    'Salesmen',
                    '${_salesmen.length}',
                    Icons.badge,
                    goldAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'New Order',
                    Icons.add_shopping_cart,
                    Colors.orange,
                    () => setState(() => _selectedIndex = 6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionCard(
                    'Add Customer',
                    Icons.person_add,
                    Colors.blue,
                    () => _showAddCustomerDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Add Product',
                    Icons.inventory_2,
                    accentTeal,
                    () => _showAddProductDialog(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionCard(
                    'Add Salesman',
                    Icons.person_add_alt,
                    cardPurple,
                    () => _showAddSalesmanDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildRecentOrders(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    final recentOrders = _orders.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 5),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recentOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No orders yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          ...recentOrders.map((order) => _buildOrderCard(order)),
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return GestureDetector(
      onTap: () => _showOrderDetailsDialog(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.receipt,
                color: _getStatusColor(order.status),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (order.orderType == OrderType.urgent)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: errorRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'URGENT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '${order.customerName} • ${order.items.length} items',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                    fontSize: 16,
                  ),
                ),
                if (order.dueAmount > 0)
                  Text(
                    'Due: ₹${order.dueAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 10, color: warningOrange),
                  ),
                Text(
                  order.statusDisplay,
                  style: TextStyle(
                    fontSize: 10,
                    color: _getStatusColor(order.status),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return warningOrange;
      case OrderStatus.taken:
        return Colors.blue;
      case OrderStatus.dispatched:
        return cardPurple;
      case OrderStatus.delivered:
        return accentTeal;
      case OrderStatus.cancelled:
        return errorRed;
    }
  }

  Widget _buildOverviewSection() {
    final totalRevenue = _orders
        .where((o) => o.status == OrderStatus.delivered)
        .fold<double>(0, (sum, o) => sum + o.totalAmount);
    final totalOrders = _orders.length;
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Overview',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Total Revenue',
                  '₹${(totalRevenue / 100000).toStringAsFixed(2)}L',
                  Icons.currency_rupee,
                  successGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOverviewCard(
                  'Total Orders',
                  '$totalOrders',
                  Icons.receipt_long,
                  primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Avg Order Value',
                  '₹${avgOrderValue.toStringAsFixed(0)}',
                  Icons.trending_up,
                  accentTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOverviewCard(
                  'Active Customers',
                  '${_customers.length}',
                  Icons.people,
                  cardPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Order Status Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          _buildOrderStatusChart(),
          const SizedBox(height: 20),
          const Text(
            'Top Performing Salesmen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildTopSalesmen(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildOrderStatusChart() {
    final statusCounts = <OrderStatus, int>{};
    for (var order in _orders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }

    final total = _orders.length;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No orders yet', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: statusCounts.entries.map((entry) {
          final percentage = (entry.value / total * 100);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStatusColor(entry.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_getStatusLabel(entry.key)),
                      ],
                    ),
                    Text(
                      '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(entry.key),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(entry.key),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.taken:
        return 'Order Taken';
      case OrderStatus.dispatched:
        return 'Dispatched';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  List<Widget> _buildTopSalesmen() {
    final salesmanPerformance = <SalesmanModel, Map<String, dynamic>>{};

    for (var salesman in _salesmen) {
      final orders = _orders.where((o) => o.salesmanId == salesman.id).toList();
      final revenue = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
      final collection = orders.fold<double>(0, (sum, o) => sum + o.paidAmount);

      salesmanPerformance[salesman] = {
        'orders': orders.length,
        'revenue': revenue,
        'collection': collection,
      };
    }

    final sortedSalesmen = salesmanPerformance.entries.toList()
      ..sort(
        (a, b) => (b.value['revenue'] as double).compareTo(
          a.value['revenue'] as double,
        ),
      );

    return sortedSalesmen.take(5).map((entry) {
      final salesman = entry.key;
      final data = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: accentTeal.withOpacity(0.1),
              child: Text(
                salesman.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: accentTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salesman.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${data['orders']} orders',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${((data['revenue'] as double) / 1000).toStringAsFixed(1)}K',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                Text(
                  'Revenue',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildCustomersSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Customers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cardPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredCustomers.length} Customers',
                      style: const TextStyle(
                        color: cardPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    tooltip: 'Import from CSV',
                    onPressed: _importCustomers,
                  ),
                  IconButton(
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_download),
                    tooltip: 'Sync from Desktop',
                    onPressed: _isSyncing ? null : _syncCustomersFromDesktop,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name, area, phone...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredCustomers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        'No customers yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    final outstanding = getCustomerOutstanding(customer.id);
                    final lastOrder = getLastOrderForCustomer(customer.id);
                    return _buildCustomerCard(customer, outstanding, lastOrder);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(
    CustomerModel customer,
    double outstanding,
    OrderModel? lastOrder,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: primaryBlue.withOpacity(0.1),
          child: const Icon(Icons.person, color: primaryBlue),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Area: ${customer.area}'),
            Text('Phone: ${customer.phone ?? "N/A"}'),
          ],
        ),
        trailing: outstanding > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${outstanding.toStringAsFixed(0)} due',
                  style: const TextStyle(
                    color: errorRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            : const Icon(Icons.check_circle, color: successGreen),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lastOrder != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.receipt, size: 16, color: primaryBlue),
                            SizedBox(width: 8),
                            Text(
                              'Last Billing Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Order:'),
                            Text(
                              lastOrder.orderNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Date:'),
                            Text(
                              '${lastOrder.createdAt.day}/${lastOrder.createdAt.month}/${lastOrder.createdAt.year}',
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Amount:'),
                            Text(
                              '₹${lastOrder.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Status:'),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  lastOrder.status,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                lastOrder.statusDisplay,
                                style: TextStyle(
                                  color: _getStatusColor(lastOrder.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (customer.address != null &&
                    customer.address!.isNotEmpty) ...[
                  Text('Address: ${customer.address}'),
                  const Divider(),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _selectedCustomerId = customer.id);
                        setState(() => _selectedIndex = 6);
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text('New Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentTeal,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredProducts.length} Items',
                      style: const TextStyle(
                        color: accentTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    tooltip: 'Import from CSV',
                    onPressed: _importProducts,
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => _showFilterDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name, SKU, category...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip('All', null),
                    ...categories.map((c) => _buildCategoryChip(c, c)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              final lastSale = getLastSaleForProduct(product.id);
              return _buildProductCard(product, lastSale);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) =>
            setState(() => _selectedCategory = selected ? category : null),
        selectedColor: accentTeal.withOpacity(0.2),
        checkmarkColor: accentTeal,
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, OrderModel? lastSale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.inventory_2, color: primaryBlue),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${product.sku} | Stock: ${product.stock}'),
            Text('Category: ${product.category}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${product.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryBlue,
                fontSize: 16,
              ),
            ),
            if (product.stock < 10)
              const Text(
                'Low Stock',
                style: TextStyle(fontSize: 10, color: errorRed),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lastSale != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.shopping_bag,
                              size: 16,
                              color: successGreen,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Last Sale Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: successGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Customer:'),
                            Text(
                              lastSale.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Date:'),
                            Text(
                              '${lastSale.createdAt.day}/${lastSale.createdAt.month}/${lastSale.createdAt.year}',
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Qty Sold:'),
                            Text(
                              lastSale.items
                                  .firstWhere(
                                    (i) => i.productId == product.id,
                                    orElse: () => OrderItemModel(
                                      id: '',
                                      productId: '',
                                      productName: '',
                                      sku: '',
                                      quantity: 0,
                                      rate: 0,
                                      amount: 0,
                                    ),
                                  )
                                  .quantity
                                  .toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  Text('Description: ${product.description}'),
                  const Divider(),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Stock'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                ...categories.map(
                  (c) => FilterChip(
                    label: Text(c),
                    selected: _selectedCategory == c,
                    onSelected: (_) => setState(() => _selectedCategory = c),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Min Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        setState(() => _minPrice = double.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Max Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        setState(() => _maxPrice = double.tryParse(v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _selectedCategory = null;
                      _minPrice = null;
                      _maxPrice = null;
                    }),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesmenSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Salesmen',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddSalesmanDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _salesmanSearchController,
                decoration: InputDecoration(
                  hintText: 'Search salesman by name...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) =>
                    setState(() => _salesmanSearchQuery = value),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredSalesmen.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        'No salesmen yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredSalesmen.length,
                  itemBuilder: (context, index) {
                    final salesman = filteredSalesmen[index];
                    return _buildSalesmanCard(salesman);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSalesmanCard(SalesmanModel salesman) {
    final orderCount = getSalesmanOrderCount(salesman.id);
    final revenue = getSalesmanRevenue(salesman.id);
    final collection = getSalesmanCollection(salesman.id);
    final lastOrder = getLastOrderForSalesman(salesman.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: salesman.status == 'active'
              ? accentTeal.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: salesman.status == 'active' ? accentTeal : Colors.grey,
          ),
        ),
        title: Text(
          salesman.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(salesman.email),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: salesman.status == 'active'
                ? successGreen.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            salesman.status == 'active' ? 'Active' : 'Inactive',
            style: TextStyle(
              color: salesman.status == 'active' ? successGreen : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (lastOrder != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.shopping_bag,
                              size: 16,
                              color: warningOrange,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Last Order',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: warningOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Order:'),
                            Text(
                              lastOrder.orderNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Customer:'),
                            Text(
                              lastOrder.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Amount:'),
                            Text(
                              '₹${lastOrder.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Date:'),
                            Text(
                              '${lastOrder.createdAt.day}/${lastOrder.createdAt.month}/${lastOrder.createdAt.year}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _buildSalesmanStat(
                        'Orders',
                        '$orderCount',
                        Icons.receipt,
                      ),
                    ),
                    Expanded(
                      child: _buildSalesmanStat(
                        'Revenue',
                        '₹${(revenue / 1000).toStringAsFixed(1)}K',
                        Icons.currency_rupee,
                      ),
                    ),
                    Expanded(
                      child: _buildSalesmanStat(
                        'Collection',
                        '₹${(collection / 1000).toStringAsFixed(1)}K',
                        Icons.account_balance_wallet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Orders'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesmanStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: primaryBlue, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  String _getPaymentModeText(OrderModel order) {
    if (order.paymentMode == null) return '-';
    switch (order.paymentMode!) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.bankTransfer:
        return 'Bank Transfer';
      case PaymentMode.credit:
        return 'Credit';
      case PaymentMode.partial:
        return 'Partial';
      case PaymentMode.cheque:
        return 'Cheque';
      case PaymentMode.chequeWithCash:
        return 'Cheque+Cash';
    }
  }

  bool _isPaidAtDelivery(OrderModel order) {
    return order.paymentMode == PaymentMode.cash ||
        order.paymentMode == PaymentMode.upi ||
        order.paymentMode == PaymentMode.bankTransfer;
  }

  Widget _buildOrdersSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cardPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredOrders.length} Orders',
                      style: const TextStyle(
                        color: cardPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _orderSearchController,
                decoration: InputDecoration(
                  hintText: 'Search by order number, customer, salesman...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _orderSearchQuery = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Filter by Salesman: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: _selectedOrderSalesmanId,
                          hint: const Text('All Salesmen'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Salesmen'),
                            ),
                            ..._salesmen.map(
                              (salesman) => DropdownMenuItem<String?>(
                                value: salesman.id,
                                child: Text(salesman.name),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedOrderSalesmanId = value),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value:
                        _selectedOrderIds.length == filteredOrders.length &&
                        filteredOrders.isNotEmpty,
                    onChanged: (_) => _selectAllOrders(),
                  ),
                  const Text('Select All'),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _selectedOrderIds.isEmpty
                        ? null
                        : _postOrdersToDesktop,
                    icon: const Icon(Icons.desktop_windows, size: 18),
                    label: Text(
                      _selectedOrderIds.isEmpty
                          ? 'Post to Desktop'
                          : 'Post ${_selectedOrderIds.length} to Desktop',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentTeal,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          color: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                flex: 2,
                child: Text(
                  'Order Date',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Order ID',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Customer Name',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Salesman Name',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Payment Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredOrders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No orders found',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    final isSelected = _selectedOrderIds.contains(order.id);
                    return _buildOrderTableRow(order, index + 1, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOrderTableRow(OrderModel order, int srNo, bool isSelected) {
    return GestureDetector(
      onTap: () => _showOrderDetailsDialog(order),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? accentTeal.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentTeal : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleOrderSelection(order.id),
                  activeColor: accentTeal,
                ),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  '$srNo',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (order.orderType == OrderType.urgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: errorRed,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  order.customerName,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  order.salesmanName,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: primaryBlue,
                      ),
                    ),
                    if (order.dueAmount > 0)
                      Text(
                        'Due: ₹${order.dueAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: warningOrange,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: _isPaidAtDelivery(order)
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getPaymentModeText(order),
                          style: const TextStyle(
                            fontSize: 10,
                            color: successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Text(
                        _getPaymentModeText(order),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateOrderSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(),
          const SizedBox(height: 20),
          if (_orderStep == 1) _buildCustomerSelectionStep(),
          if (_orderStep == 2) _buildProductSelectionStep(),
          if (_orderStep == 3) _buildReviewStep(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStepCircle(1, 'Customer'),
          _buildStepLine(1),
          _buildStepCircle(2, 'Products'),
          _buildStepLine(2),
          _buildStepCircle(3, 'Review'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _orderStep >= step;
    final isCurrent = _orderStep == step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? accentTeal : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isActive && _orderStep > step
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '$step',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isCurrent ? primaryBlue : Colors.grey[600],
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    return Expanded(
      child: Container(
        height: 2,
        color: _orderStep > afterStep ? accentTeal : Colors.grey[300],
      ),
    );
  }

  Widget _buildCustomerSelectionStep() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Customer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _customerSearchController,
            decoration: InputDecoration(
              hintText: 'Search by name, area, phone...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) => setState(() => _customerSearchQuery = value),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orderFilteredCustomers.length,
            itemBuilder: (context, index) {
              final customer = orderFilteredCustomers[index];
              final isSelected = _selectedCustomerId == customer.id;
              final outstanding = getCustomerOutstanding(customer.id);
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCustomerId = customer.id;
                  _orderStep = 2;
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryBlue.withOpacity(0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? primaryBlue : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isSelected
                            ? primaryBlue
                            : primaryBlue.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: isSelected ? Colors.white : primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? primaryBlue : Colors.black,
                              ),
                            ),
                            Text(
                              'Area: ${customer.area}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            if (outstanding > 0)
                              Text(
                                'Outstanding: ₹${outstanding.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: errorRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: primaryBlue),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: primaryBlue),
              const SizedBox(width: 8),
              Text(
                '$cartItemCount items in cart',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ₹${cartTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: accentTeal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];
            final inCart = _cart[product.id] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: inCart > 0
                    ? accentTeal.withOpacity(0.1)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (inCart > 0)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          onPressed: () => removeFromCart(product.id),
                        ),
                        Text(
                          '$inCart',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          onPressed: () => addToCart(product.id),
                        ),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: () => addToCart(product.id),
                      child: const Text('Add'),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _orderStep = 1),
                child: const Text('← Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _cart.isNotEmpty
                    ? () => setState(() => _orderStep = 3)
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
                child: Text(_cart.isEmpty ? 'Add items' : 'Review →'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    if (_selectedCustomerId == null) return const SizedBox();
    final customer = _customers.firstWhere((c) => c.id == _selectedCustomerId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.person, color: primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    customer.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    customer.area,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Mode',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Credit'),
                    selected: _selectedPaymentMode == PaymentMode.credit,
                    onSelected: (_) => setState(
                      () => _selectedPaymentMode = PaymentMode.credit,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Cash'),
                    selected: _selectedPaymentMode == PaymentMode.cash,
                    onSelected: (_) =>
                        setState(() => _selectedPaymentMode = PaymentMode.cash),
                  ),
                  ChoiceChip(
                    label: const Text('UPI'),
                    selected: _selectedPaymentMode == PaymentMode.upi,
                    onSelected: (_) =>
                        setState(() => _selectedPaymentMode = PaymentMode.upi),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$cartItemCount items',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    'Total: ₹${cartTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: accentTeal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _orderStep = 2),
                child: const Text('← Edit'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: submitOrder,
                style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
                child: const Text('Submit ✅'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentCollectionSection() {
    final ordersWithDue = _orders
        .where((o) => o.dueAmount > 0 && o.status != OrderStatus.cancelled)
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Payment Collection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '₹${_orderService.totalPendingAmount.toStringAsFixed(0)} Due',
                  style: const TextStyle(
                    color: successGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ordersWithDue.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 60, color: successGreen),
                      SizedBox(height: 10),
                      Text(
                        'All payments collected!',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ordersWithDue.length,
                  itemBuilder: (context, index) {
                    final order = ordersWithDue[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.orderNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: warningOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '₹${order.dueAmount.toStringAsFixed(0)} due',
                                  style: const TextStyle(
                                    color: warningOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text('Customer: ${order.customerName}'),
                          Text(
                            'Total: ₹${order.totalAmount.toStringAsFixed(0)} | Paid: ₹${order.paidAmount.toStringAsFixed(0)}',
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showPaymentDialog(order),
                            icon: const Icon(Icons.payment, size: 16),
                            label: const Text('Collect Payment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: successGreen,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showPaymentDialog(OrderModel order) {
    _paymentAmountController.text = order.dueAmount.toStringAsFixed(0);
    PaymentMode selectedMode = PaymentMode.cash;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Collect Payment - ${order.orderNumber}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: ₹${order.totalAmount.toStringAsFixed(0)} | Paid: ₹${order.paidAmount.toStringAsFixed(0)}',
                ),
                Text(
                  'Balance Due: ₹${order.dueAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: warningOrange,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _paymentAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount to Collect',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Payment Mode:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Cash'),
                      selected: selectedMode == PaymentMode.cash,
                      onSelected: (_) =>
                          setDialogState(() => selectedMode = PaymentMode.cash),
                    ),
                    ChoiceChip(
                      label: const Text('UPI'),
                      selected: selectedMode == PaymentMode.upi,
                      onSelected: (_) =>
                          setDialogState(() => selectedMode = PaymentMode.upi),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _remarkController,
                  decoration: const InputDecoration(
                    labelText: 'Remark (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(_paymentAmountController.text);
                if (amount != null && amount > 0) {
                  await _orderService.recordPayment(
                    order.id,
                    amount,
                    selectedMode,
                    reference: _referenceController.text,
                  );
                  await _loadData();
                  if (mounted) {
                    Navigator.pop(context);
                    showSafeSnackBar(context, 'Payment collected successfully!', backgroundColor: successGreen);
                  }
                }
              },
              child: const Text('Collect'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SALESMAN DASHBOARD ====================
class SalesmanDashboardEnhanced extends StatefulWidget {
  final UserModel? loggedInUser;
  
  const SalesmanDashboardEnhanced({super.key, this.loggedInUser});

  @override
  State<SalesmanDashboardEnhanced> createState() =>
      _SalesmanDashboardEnhancedState();
}

class _SalesmanDashboardEnhancedState extends State<SalesmanDashboardEnhanced> {
  static const Color primaryBlue = Color(0xFF1A3B70);
  static const Color accentTeal = Color(0xFF00A68A);
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);

  int _selectedIndex = 0;
  bool _isSidebarOpen = false;
  bool _isLoading = true;
  
  // Current salesman
  late UserModel _currentSalesman;

  // Data
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _orders = [];

  // Cart
  final Map<String, CartItemData> _cart = {};

  // Order creation state
  int _orderStep = 1;
  String? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    // Initialize current salesman from passed user or create default
    if (widget.loggedInUser != null) {
      _currentSalesman = widget.loggedInUser!;
    } else {
      _currentSalesman = UserModel(
        id: 'salesman_001',
        email: 'salesman@demo.com',
        name: 'John Salesman',
        phone: '+91 9876543211',
        role: UserRole.salesman,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        isActive: true,
      );
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  double get cartTotal {
    double total = 0;
    for (var item in _cart.values) {
      total += item.netAmt;
    }
    return total;
  }

  int get cartItemCount => _cart.length;

  void addToCart(String productId, String productName, String sku, double price) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!.quantity++;
        _cart[productId]!.calculate();
      } else {
        _cart[productId] = CartItemData(
          productId: productId,
          productName: productName,
          sku: sku,
          quantity: 1,
          rate: price,
        );
        _cart[productId]!.calculate();
      }
    });
  }

  void removeFromCart(String productId) {
    setState(() {
      _cart.remove(productId);
    });
  }

  void updateCartQuantity(String productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(productId);
      } else if (_cart.containsKey(productId)) {
        _cart[productId]!.quantity = quantity;
        _cart[productId]!.calculate();
      }
    });
  }

  void clearCart() {
    setState(() {
      _cart.clear();
      _selectedCustomerId = null;
      _orderStep = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('salesmanScaffold'),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(),
              ),
            ],
          ),
          if (_isSidebarOpen) _buildSidebarOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      color: primaryBlue,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: Colors.white,
                child: Text(
                  _currentSalesman.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentSalesman.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Salesman Portal',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: _showCartDialog,
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$cartItemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isSidebarOpen ? Icons.close : Icons.menu,
                  color: Colors.white,
                ),
                onPressed: () =>
                    setState(() => _isSidebarOpen = !_isSidebarOpen),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search products, customers...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _isSidebarOpen = false),
      child: Container(
        color: Colors.black54,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: primaryBlue,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                child: Text(
                                  _currentSalesman.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Salesman',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Salesman',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    setState(() => _isSidebarOpen = false),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: [
                              _buildSidebarItem(
                                Icons.dashboard,
                                'Dashboard',
                                0,
                              ),
                              _buildSidebarItem(
                                Icons.inventory_2,
                                'Products',
                                1,
                              ),
                              _buildSidebarItem(
                                Icons.people,
                                'Customers',
                                2,
                              ),
                              _buildSidebarItem(
                                Icons.add_shopping_cart,
                                'Create Order',
                                3,
                              ),
                              _buildSidebarItem(
                                Icons.receipt_long,
                                'My Orders',
                                4,
                              ),
                              _buildSidebarItem(
                                Icons.payment,
                                'Payments',
                                5,
                              ),
                              const Divider(height: 32),
                              _buildSidebarItem(
                                Icons.logout,
                                'Logout',
                                -1,
                                isLogout: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String label,
    int index, {
    bool isLogout = false,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout
            ? errorRed
            : (isSelected ? primaryBlue : Colors.grey[600]),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isLogout
              ? errorRed
              : (isSelected ? primaryBlue : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: primaryBlue.withOpacity(0.1),
      onTap: () {
        if (isLogout) {
          setState(() => _isSidebarOpen = false);
          _logout();
        } else {
          setState(() {
            _selectedIndex = index;
            _isSidebarOpen = false;
          });
        }
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildProductsSection();
      case 2:
        return _buildCustomersSection();
      case 3:
        return _buildCreateOrderSection();
      case 4:
        return _buildOrdersSection();
      case 5:
        return _buildPaymentsSection();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [accentTeal, Color(0xFF00D9C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome to',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _currentSalesman.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Track your sales and grow your business! 💪',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Today\'s Orders',
                  '0',
                  Icons.shopping_bag,
                  primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Today Collection',
                  '₹0',
                  Icons.currency_rupee,
                  successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending Dues',
                  '₹0',
                  Icons.pending_actions,
                  warningOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Total Sales',
                  '₹0',
                  Icons.trending_up,
                  accentTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'New Order',
                  Icons.add_shopping_cart,
                  Colors.orange,
                  () => setState(() => _selectedIndex = 3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionCard(
                  'Collect Payment',
                  Icons.payment,
                  successGreen,
                  () => setState(() => _selectedIndex = 5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Products',
                  Icons.inventory_2,
                  accentTeal,
                  () => setState(() => _selectedIndex = 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionCard(
                  'Customers',
                  Icons.people,
                  primaryBlue,
                  () => setState(() => _selectedIndex = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRecentOrders(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Orders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text('No orders yet', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Products Section',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('Feature coming soon...', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildCustomersSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Customers Section',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('Feature coming soon...', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildCreateOrderSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(),
          const SizedBox(height: 20),
          if (_orderStep == 1) _buildCustomerSelectionStep(),
          if (_orderStep == 2) _buildProductSelectionStep(),
          if (_orderStep == 3) _buildReviewStep(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStepCircle(1, 'Customer'),
          _buildStepLine(1),
          _buildStepCircle(2, 'Products'),
          _buildStepLine(2),
          _buildStepCircle(3, 'Review'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _orderStep >= step;
    final isCurrent = _orderStep == step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? accentTeal : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isActive && _orderStep > step
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '$step',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isCurrent ? primaryBlue : Colors.grey[600],
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    return Expanded(
      child: Container(
        height: 2,
        color: _orderStep > afterStep ? accentTeal : Colors.grey[300],
      ),
    );
  }

  Widget _buildCustomerSelectionStep() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Customer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a customer for this order',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCustomerId = 'cust_$index';
                  _orderStep = 2;
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primaryBlue.withOpacity(0.1),
                        child: const Icon(Icons.person, color: primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer ${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Area: Area ${index + 1}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: primaryBlue),
              const SizedBox(width: 8),
              Text(
                '$cartItemCount items in cart',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ₹${cartTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: accentTeal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          itemBuilder: (context, index) {
            final productId = 'prod_$index';
            final inCart = _cart.containsKey(productId);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: inCart ? accentTeal.withOpacity(0.1) : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: inCart ? accentTeal : Colors.grey[300]!,
                  width: inCart ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'SKU: PRD00${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '₹${(index + 1) * 100}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (inCart)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          onPressed: () => removeFromCart(productId),
                        ),
                        Text(
                          '${_cart[productId]?.quantity ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          onPressed: () => addToCart(
                            productId,
                            'Product ${index + 1}',
                            'PRD00${index + 1}',
                            (index + 1) * 100.0,
                          ),
                        ),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: () => addToCart(
                        productId,
                        'Product ${index + 1}',
                        'PRD00${index + 1}',
                        (index + 1) * 100.0,
                      ),
                      child: const Text('Add'),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _orderStep = 1),
                child: const Text('← Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _cart.isNotEmpty
                    ? () => setState(() => _orderStep = 3)
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
                child: Text(_cart.isEmpty ? 'Add items' : 'Review →'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const Divider(),
              ..._cart.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${entry.value.quantity} x ₹${entry.value.rate.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹${entry.value.netAmt.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  Text(
                    '₹${cartTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: accentTeal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _orderStep = 2),
                child: const Text('← Edit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  showSafeSnackBar(context, '✅ Order submitted successfully!', backgroundColor: successGreen);
                  clearCart();
                  setState(() => _selectedIndex = 0);
                },
                style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
                child: const Text('Submit ✅'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrdersSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'My Orders',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('Feature coming soon...', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Payment Collection',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('Feature coming soon...', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🛒 Cart',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              if (_cart.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Cart is empty',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final productId = _cart.keys.elementAt(index);
                      final cartItem = _cart[productId]!;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartItem.productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '₹${cartItem.rate.toStringAsFixed(0)} each',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () {
                                    updateCartQuantity(productId, cartItem.quantity - 1);
                                    Navigator.pop(context);
                                    _showCartDialog();
                                  },
                                ),
                                Text(
                                  '${cartItem.quantity}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () {
                                    updateCartQuantity(productId, cartItem.quantity + 1);
                                    Navigator.pop(context);
                                    _showCartDialog();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${cartItem.netAmt.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    Text(
                      '₹${cartTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: accentTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 3);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Proceed to Checkout'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== LOGIN SCREEN ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Registration form controllers
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.distributor;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showRegistration = false;
  String? _errorMessage;
  String? _successMessage;

  // API endpoint
  static String get apiUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:3000/api';
    }
    
    return 'http://localhost:3000/api';
  }

  static const Color primaryBlue = Color(0xFF1A3B70);
  static const Color accentTeal = Color(0xFF00A68A);
  static const Color formBackground = Color(0xE6FFFFFF);

  @override
  void initState() {
    super.initState();
    _checkLoggedInStatus();
  }

  Future<void> _checkLoggedInStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final userJson = prefs.getString('user_json');
    
    if (isLoggedIn && userJson != null && mounted) {
      try {
        final userData = json.decode(userJson);
        final userRole = userData['role'];
        final user = UserModel.fromMap(userData, userData['_id'] ?? userData['id'] ?? '');
        
        if (userRole == 'distributor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DistributorDashboardEnhanced(loggedInUser: user),
            ),
          );
        } else if (userRole == 'salesman') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SalesmanDashboardEnhanced(loggedInUser: user),
            ),
          );
        }
      } catch (e) {
        // Error parsing user data
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^\d{10}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null && mounted) {
          final userData = data['user'];
          final backendRoleStr = userData['role'];
          
          // Save user data to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_email', userData['email'] ?? '');
          await prefs.setString('user_role', backendRoleStr);
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('user_json', json.encode(userData));
          
          // Create UserModel from response
          final user = UserModel.fromMap(userData, userData['_id'] ?? userData['id'] ?? '');
          
          if (mounted) {
            setState(() {
              _successMessage = data['message'] ?? 'Login successful!';
            });
          }

          // Navigate based on ACTUAL backend role
          if (mounted) {
            if (backendRoleStr == 'distributor') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DistributorDashboardEnhanced(loggedInUser: user),
                ),
              );
            } else if (backendRoleStr == 'salesman') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SalesmanDashboardEnhanced(loggedInUser: user),
                ),
              );
            } else {
              showSafeSnackBar(context, 'Unknown user role!', backgroundColor: Colors.red);
            }
          }
        } else if (mounted) {
          setState(() {
            _errorMessage = data['message'] ?? 'Login failed';
          });
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          if (mounted) {
            setState(() {
              _errorMessage = errorData['message'] ?? 'Login failed';
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Server error. Please try again.';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('Timeout')) {
            _errorMessage = 'Connection timeout. Please check:\n1. Backend server is running\n2. MongoDB is connected\n3. Port 3000 is available';
          } else if (e.toString().contains('Connection refused')) {
            _errorMessage = 'Cannot connect to server. Please start backend: node server.js';
          } else {
            _errorMessage = 'Login error: ${e.toString().replaceAll('Exception: ', '')}';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRegistration() async {
    if (!_registerFormKey.currentState!.validate()) return;

    final email = _regEmailController.text.trim();
    final phone = _regPhoneController.text.trim();

    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    if (!_isValidPhoneNumber(phone)) {
      setState(() {
        _errorMessage = 'Mobile number must be exactly 10 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final registrationData = {
        'fullName': _regNameController.text.trim(),
        'email': email,
        'phoneNumber': phone,
        'password': _regPasswordController.text,
        'role': _selectedRole.toString().split('.').last,
        'accountType': 'PortalUser',
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true
      };

      final registerResponse = await http.post(
        Uri.parse('$apiUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(registrationData),
      ).timeout(const Duration(seconds: 10));

      if (registerResponse.statusCode == 200 || registerResponse.statusCode == 201) {
        final responseData = json.decode(registerResponse.body);
        
        if (mounted) {
          setState(() {
            _successMessage = responseData['message'] ?? 'Registration successful! Please login.';
            _showRegistration = false;
          });
        }
        
        _emailController.text = email;
        _passwordController.text = _regPasswordController.text;
        
        _regNameController.clear();
        _regEmailController.clear();
        _regPhoneController.clear();
        _regPasswordController.clear();
      } else {
        final errorData = json.decode(registerResponse.body);
        if (mounted) {
          setState(() {
            _errorMessage = errorData['message'] ?? 'Registration failed. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('Timeout')) {
            _errorMessage = 'Connection timeout. Please check if server is running.';
          } else if (e.toString().contains('Connection refused')) {
            _errorMessage = 'Cannot connect to server. Please ensure backend is running on port 3000.';
          } else {
            _errorMessage = 'Registration error: ${e.toString().replaceAll('Exception: ', '')}';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleView() {
    setState(() {
      _showRegistration = !_showRegistration;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF87CEEB),
              Color(0xFFB0E0E6),
              Color(0xFFADD8E6),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                _buildLogo(),
                const SizedBox(height: 40),
                if (_showRegistration)
                  _buildRoleSelector(),
                const SizedBox(height: 30),
                if (_showRegistration)
                  _buildRegistrationForm()
                else
                  _buildLoginForm(),
                const SizedBox(height: 20),
                _buildToggleButton(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  _buildError(),
                ],
                if (_successMessage != null) ...[
                  const SizedBox(height: 20),
                  _buildSuccess(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withAlpha(51),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              color: Colors.white,
              child: const Icon(Icons.business, size: 80, color: primaryBlue),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Total Solution',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedRole == UserRole.distributor
              ? 'Distributor Portal'
              : 'Salesman Portal',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: formBackground,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _roleButton(
              'Distributor',
              Icons.admin_panel_settings,
              UserRole.distributor,
            ),
          ),
          Expanded(
            child: _roleButton('Salesman', Icons.person, UserRole.salesman),
          ),
        ],
      ),
    );
  }

  Widget _roleButton(String label, IconData icon, UserRole role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: formBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withAlpha(26),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to continue',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: primaryBlue,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!_isValidEmail(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined, color: primaryBlue),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 4) {
                  return 'Password must be at least 4 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentTeal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: formBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withAlpha(26),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Register to continue',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _regNameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: primaryBlue,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: primaryBlue,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!_isValidEmail(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regPhoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(
                  Icons.phone_outlined,
                  color: primaryBlue,
                ),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length != 10) {
                  return 'Phone number must be exactly 10 digits';
                }
                if (!_isValidPhoneNumber(value)) {
                  return 'Please enter only numbers (0-9)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined, color: primaryBlue),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentTeal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showRegistration)
          TextButton(
            onPressed: _toggleView,
            child: const Text(
              'Already have an account? Sign In',
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
            ),
          )
        else
          TextButton(
            onPressed: _toggleView,
            child: const Text(
              "Don't have an account? Register Here",
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _successMessage!,
              style: TextStyle(color: Colors.green[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// Main app widget to handle routing
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Total Solution',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/distributor-dashboard': (context) => const DistributorDashboardEnhanced(),
        '/salesman-dashboard': (context) => const SalesmanDashboardEnhanced(),
      },
    );
  }
}

void main() {
  runApp(const MyApp());
}