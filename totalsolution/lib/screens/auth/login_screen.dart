import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

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
  final String? salesmanId;
  final Map<String, dynamic>? permissions;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.createdAt,
    required this.isActive,
    this.distributorId,
    this.salesmanId,
    this.permissions,
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
      'salesmanId': salesmanId,
      'permissions': permissions,
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
      distributorId: map['distributor_id'] ?? map['distributorId'],
      salesmanId: map['salesman_id'],
      permissions: map['permissions'] != null ? Map<String, dynamic>.from(map['permissions']) : null,
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
      'route': route,
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
  final double mrp;
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
    required this.mrp,
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
      'mrp': mrp,
      'category': category,
      'stock': stock,
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
      mrp: (map['mrp'] ?? map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      stock: map['stock'] ?? map['stockQuantity'] ?? 0,
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

// ==================== COLLECTION HISTORY MODEL ====================
class CollectionHistoryModel {
  final String id;
  final String collectionId;
  final String orderId;
  final double orderAmount;
  final double amountCollected;
  final String paymentMode;
  final String customerId;
  final String customerName;
  final String distributorId;
  final Map<String, dynamic> collectedBy;
  final Map<String, dynamic>? salesmanDetails;
  final String billNo;
  final DateTime collectionDate;
  final DateTime createdAt;
  final String status;
  final String? chequeNumber;
  final String? bankName;
  final String? chequeDate;
  final String? upiType;
  final String? transactionNumber;

  CollectionHistoryModel({
    required this.id,
    required this.collectionId,
    required this.orderId,
    required this.orderAmount,
    required this.amountCollected,
    required this.paymentMode,
    required this.customerId,
    required this.customerName,
    required this.distributorId,
    required this.collectedBy,
    this.salesmanDetails,
    required this.billNo,
    required this.collectionDate,
    required this.createdAt,
    required this.status,
    this.chequeNumber,
    this.bankName,
    this.chequeDate,
    this.upiType,
    this.transactionNumber,
  });

  factory CollectionHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CollectionHistoryModel(
      id: id,
      collectionId: map['collection_id'] ?? '',
      orderId: map['order_id'] ?? '',
      orderAmount: (map['order_amount'] ?? 0).toDouble(),
      amountCollected: (map['amount_collected'] ?? 0).toDouble(),
      paymentMode: map['payment_mode'] ?? '',
      customerId: map['customer_id'] ?? '',
      customerName: map['customer_name'] ?? '',
      distributorId: map['distributor_id'] ?? '',
      collectedBy: map['collected_by'] ?? {},
      salesmanDetails: map['salesman_details'],
      billNo: map['bill_no'] ?? '',
      collectionDate: map['collection_date'] != null ? DateTime.parse(map['collection_date']) : DateTime.now(),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      status: map['status'] ?? 'completed',
      chequeNumber: map['cheque_number'],
      bankName: map['bank_name'],
      chequeDate: map['cheque_date'],
      upiType: map['upi_type'],
      transactionNumber: map['transaction_number'],
    );
  }
}

class NotificationModel {
  final String id;
  final String distributorId;
  final String? orderId;
  final String orderNumber;
  final String customerName;
  final String salesmanName;
  final double amount;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? orderData;

  NotificationModel({
    required this.id,
    required this.distributorId,
    this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.salesmanName,
    required this.amount,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.orderData,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      distributorId: map['distributor_id'] ?? '',
      orderId: map['order_id'],
      orderNumber: map['order_number'] ?? '',
      customerName: map['customer_name'] ?? '',
      salesmanName: map['salesman_name'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      message: map['message'] ?? '',
      type: map['type'] ?? 'new_order',
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      readAt: map['readAt'] != null ? DateTime.tryParse(map['readAt']) : null,
      orderData: map['order_data'],
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
  final double? mrp;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.mrp,
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

// Cart Item Data Model for Order with Scheme Calculation
class CartItemData {
  String productId;
  String productName;
  String sku;
  int quantity;
  double rate;
  double mrp;
  double schPer;
  double schAmt;
  double grossAmt;
  double netAmt;
  int stock;
  bool schEnabled;

  CartItemData({
    required this.productId,
    required this.productName,
    required this.sku,
    this.quantity = 1,
    this.rate = 0,
    this.mrp = 0,
    this.schPer = 0,
    this.schAmt = 0,
    this.grossAmt = 0,
    this.netAmt = 0,
    this.stock = 0,
    this.schEnabled = false,
  });

  void calculate() {
    grossAmt = quantity * rate;
    schAmt = schEnabled ? (schPer / 100) * grossAmt : 0;
    netAmt = grossAmt - schAmt;
  }

  CartItemData copyWith({
    int? quantity,
    double? rate,
    double? mrp,
    double? schPer,
    bool? schEnabled,
  }) {
    return CartItemData(
      productId: productId,
      productName: productName,
      sku: sku,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      mrp: mrp ?? this.mrp,
      schPer: schPer ?? this.schPer,
      schEnabled: schEnabled ?? this.schEnabled,
    );
  }
}

// ==================== API Service for backend communication ====================
class ApiService {
  static const String _remoteBaseUrl = 'https://totalmobileapp.onrender.com/api';
  
  static String get apiUrl {
    return _remoteBaseUrl;
  }

  // ==================== GLOBAL SEARCH API ====================
  static Future<Map<String, dynamic>> searchGlobal(String distributorId, String query) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/search/$distributorId?query=${Uri.encodeComponent(query)}'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'products': [], 'customers': [], 'orders': []};
    } catch (e) {
      print('Error searching: $e');
      return {'products': [], 'customers': [], 'orders': []};
    }
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
      print('Error fetching customers: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateCustomer(String customerId, Map<String, dynamic> customerData) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/customers/$customerId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(customerData),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to update customer');
    } catch (e) {
      throw Exception('Error updating customer: $e');
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

  static Future<List<dynamic>> getProducts(String distributorId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/products/$distributorId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Products fetched: ${data.length} products');
        return data;
      }
      return [];
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // ==================== COLLECTION HISTORY APIs ====================
  static Future<Map<String, dynamic>> getCollectionHistoryForDistributor(
    String distributorId, {
    DateTime? startDate,
    DateTime? endDate,
    String? salesmanId,
  }) async {
    try {
      var url = '$apiUrl/collection-history/distributor/$distributorId';
      var queryParams = <String>[];
      
      if (startDate != null) {
        queryParams.add('startDate=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        queryParams.add('endDate=${endDate.toIso8601String()}');
      }
      if (salesmanId != null && salesmanId.isNotEmpty && salesmanId != 'all') {
        queryParams.add('salesmanId=$salesmanId');
      }
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'collections': [], 'summary': {}};
    } catch (e) {
      print('Error fetching collection history: $e');
      return {'collections': [], 'summary': {}};
    }
  }

  static Future<Map<String, dynamic>> getCollectionHistoryForSalesman(
    String salesmanId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var url = '$apiUrl/collection-history/salesman/$salesmanId';
      var queryParams = <String>[];
      
      if (startDate != null) {
        queryParams.add('startDate=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        queryParams.add('endDate=${endDate.toIso8601String()}');
      }
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'collections': [], 'summary': {}};
    } catch (e) {
      print('Error fetching salesman collection history: $e');
      return {'collections': [], 'summary': {}};
    }
  }

  static Future<Map<String, dynamic>> reconcileCollections(
    String distributorId, {
    required double expectedAmount,
    DateTime? date,
  }) async {
    try {
      var url = '$apiUrl/collection-history/reconcile/$distributorId?expectedAmount=$expectedAmount';
      if (date != null) {
        url += '&date=${date.toIso8601String().split('T')[0]}';
      }
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'is_matching': false, 'difference': expectedAmount, 'message': 'Failed to reconcile'};
    } catch (e) {
      print('Error reconciling collections: $e');
      return {'is_matching': false, 'difference': expectedAmount, 'message': 'Error: $e'};
    }
  }

  // ==================== IMPORT MASTER DATA APIs ====================
  
  static Future<Map<String, dynamic>> importCustomersFromExcel({
    required String filePath,
    required String distributorId,
    String? createdBy,
    bool updateExisting = true,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/import/customers'),
      );
      
      request.fields['distributorId'] = distributorId;
      if (createdBy != null) request.fields['createdBy'] = createdBy;
      request.fields['updateExisting'] = updateExisting.toString();
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to import customers');
    } catch (e) {
      throw Exception('Error importing customers: $e');
    }
  }

  static Future<Map<String, dynamic>> importProductsFromExcel({
    required String filePath,
    required String distributorId,
    String? createdBy,
    bool updateExisting = true,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/import/products'),
      );
      
      request.fields['distributorId'] = distributorId;
      if (createdBy != null) request.fields['createdBy'] = createdBy;
      request.fields['updateExisting'] = updateExisting.toString();
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to import products');
    } catch (e) {
      throw Exception('Error importing products: $e');
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
      print('Error fetching salesmen: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getSalesmanData(String salesmanId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/salesman-data/$salesmanId'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to fetch salesman data: ${response.statusCode}');
    } catch (e) {
      print('Error fetching salesman data: $e');
      throw Exception('Error fetching salesman data: $e');
    }
  }

  // Order APIs
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      // CRITICAL FIX: Ensure each item has MRP value
      if (orderData.containsKey('items') && orderData['items'] is List) {
        final items = orderData['items'] as List;
        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          // Ensure MRP is present - if not, use rate as fallback
          if (item['mrp'] == null || item['mrp'] == 0) {
            item['mrp'] = item['rate'] ?? 0;
          }
          items[i] = item;
        }
        orderData['items'] = items;
      }
      
      final response = await http.post(
        Uri.parse('$apiUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to create order');
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  static Future<List<dynamic>> getOrdersBySalesman(String salesmanId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/orders/salesman/$salesmanId'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getOrdersByDistributor(String distributorId, {String? customerName, String? salesmanId, DateTime? startDate, DateTime? endDate, String? search}) async {
    try {
      var url = '$apiUrl/orders/distributor/$distributorId';
      var queryParams = <String>[];
      
      if (search != null && search.isNotEmpty) {
        queryParams.add('search=$search');
      }
      if (customerName != null && customerName.isNotEmpty) {
        queryParams.add('customerName=$customerName');
      }
      if (salesmanId != null && salesmanId.isNotEmpty && salesmanId != 'all') {
        queryParams.add('salesmanId=$salesmanId');
      }
      if (startDate != null) {
        queryParams.add('startDate=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        queryParams.add('endDate=${endDate.toIso8601String()}');
      }
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> downloadOrders(String distributorId, {String? startDate, String? endDate, String? filterType}) async {
    try {
      var url = '$apiUrl/orders/download/$distributorId';
      var queryParams = <String>[];
      
      if (filterType != null && filterType.isNotEmpty) {
        queryParams.add('filterType=$filterType');
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams.add('startDate=$startDate');
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams.add('endDate=$endDate');
      }
      
      queryParams.add('includeMrp=true');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.bodyBytes,
          'contentType': response.headers['content-type'] ?? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        };
      }
      final errorData = json.decode(response.body);
      return {
        'success': false,
        'error': errorData['error'] ?? 'Failed to download orders',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error downloading orders: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getLastOrderByCustomer(String customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/orders/customer/$customerId/last'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching last order: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> getLastSaleForProduct(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/products/$productId/last-sale'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching last sale: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> recordPayment(String orderId, Map<String, dynamic> paymentData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/orders/$orderId/payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(paymentData),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to record payment: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error recording payment: $e');
    }
  }

  // FIXED: This method now properly passes cheque and UPI details to the backend
  static Future<Map<String, dynamic>> recordPaymentWithFile({
    required String orderId,
    required double amount,
    required String paymentMode,
    required String collectedBy,
    required String collectedByName,
    required String collectedByType,
    String? salesmanId,
    String? salesmanName,
    String? chequeNumber,
    String? chequeDate,
    String? bankName,
    String? upiType,
    String? transactionNumber,
    String? remark,
    File? paymentPhoto,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/orders/$orderId/payment'),
      );
      
      request.fields['amount'] = amount.toString();
      request.fields['paymentMode'] = paymentMode;
      request.fields['collectedBy'] = collectedBy;
      request.fields['collectedByName'] = collectedByName;
      request.fields['collectedByType'] = collectedByType;
      
      if (salesmanId != null && salesmanId.isNotEmpty) {
        request.fields['salesmanId'] = salesmanId;
      }
      if (salesmanName != null) request.fields['salesmanName'] = salesmanName;
      
      // FIXED: Pass all cheque and UPI details to backend
      if (chequeNumber != null && chequeNumber.isNotEmpty) {
        request.fields['chequeNumber'] = chequeNumber;
        print('Adding chequeNumber: $chequeNumber');
      }
      if (chequeDate != null && chequeDate.isNotEmpty) {
        request.fields['chequeDate'] = chequeDate;
        print('Adding chequeDate: $chequeDate');
      }
      if (bankName != null && bankName.isNotEmpty) {
        request.fields['bankName'] = bankName;
        print('Adding bankName: $bankName');
      }
      if (upiType != null && upiType.isNotEmpty) {
        request.fields['upiType'] = upiType;
        print('Adding upiType: $upiType');
      }
      if (transactionNumber != null && transactionNumber.isNotEmpty) {
        request.fields['transactionNumber'] = transactionNumber;
        print('Adding transactionNumber: $transactionNumber');
      }
      if (remark != null && remark.isNotEmpty) {
        request.fields['remark'] = remark;
      }
      
      if (paymentPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath('paymentPhoto', paymentPhoto.path));
        print('Adding payment photo: ${paymentPhoto.path}');
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Payment API response status: ${response.statusCode}');
      print('Payment API response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      final errorText = response.body;
      throw Exception('Failed to record payment: ${response.statusCode} - $errorText');
    } catch (e) {
      print('Error recording payment: $e');
      throw Exception('Error recording payment: $e');
    }
  }

  static Future<List<dynamic>> getBanks() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/banks'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['banks'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching banks: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getUpiTypes() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/upi-types'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['upiTypes'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching UPI types: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateSalesmanPermissions(String salesmanId, Map<String, dynamic> permissions) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/salesmen/permissions/$salesmanId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'permissions': permissions}),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to update permissions: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating permissions: $e');
    }
  }

  static Future<Map<String, dynamic>> getSalesmanPermissions(String salesmanId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/salesmen/permissions/$salesmanId'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'permissions': {}};
    } catch (e) {
      print('Error fetching permissions: $e');
      return {'permissions': {}};
    }
  }
  
  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/logout'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': true};
    } catch (e) {
      print('Error during logout: $e');
      return {'success': true};
    }
  }

  static Future<double> getCustomerOutstanding(String customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/customers/$customerId/outstanding'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['outstanding'] ?? 0).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('Error fetching outstanding: $e');
      return 0.0;
    }
  }

  static Future<List<dynamic>> getNotifications(String distributorId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/notifications/$distributorId'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  static Future<int> getUnreadNotificationCount(String distributorId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/notifications/unread-count/$distributorId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  static Future<Map<String, dynamic>> markNotificationRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/notifications/$notificationId/read'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to mark notification as read');
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  static Future<Map<String, dynamic>> markAllNotificationsRead(String distributorId) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/notifications/mark-all-read/$distributorId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to mark all notifications as read');
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  static Future<Map<String, dynamic>> updateProductStock(String productId, int stockReduction) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/products/$productId/stock'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'stockReduction': stockReduction}),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to update product stock: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating product stock: $e');
    }
  }

  static Future<Map<String, dynamic>> editOrder(String orderId, Map<String, dynamic> orderData) async {
    try {
      // CRITICAL FIX: Ensure each item has MRP value when editing
      if (orderData.containsKey('items') && orderData['items'] is List) {
        final items = orderData['items'] as List;
        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          if (item['mrp'] == null || item['mrp'] == 0) {
            item['mrp'] = item['rate'] ?? 0;
          }
          items[i] = item;
        }
        orderData['items'] = items;
      }
      
      final response = await http.put(
        Uri.parse('$apiUrl/orders/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to edit order');
    } catch (e) {
      throw Exception('Error editing order: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteOrder(String orderId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/orders/$orderId'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to delete order');
    } catch (e) {
      throw Exception('Error deleting order: $e');
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String userId,
    String? currentPassword,
    required String newPassword,
    required String requestingUserId,
    required String requestingUserRole,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'requestingUserId': requestingUserId,
          'requestingUserRole': requestingUserRole,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to change password');
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }

  static Future<List<dynamic>> getUsersUnderDistributor(String distributorId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/users-under-distributor/$distributorId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['users'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  static Future<List<String>> getAreas({String? city}) async {
    try {
      final uri = city != null && city.isNotEmpty 
          ? Uri.parse('$apiUrl/areas?city=$city')
          : Uri.parse('$apiUrl/areas');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final areas = data['areas'] as List?;
        if (areas != null) {
          return areas.map((a) => a.toString()).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching areas: $e');
      return [];
    }
  }

  static Future<List<String>> getSubAreas({required String area}) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/sub-areas?area=$area'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null) {
          return routes.map((r) => r.toString()).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching sub-areas: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getDashboardStats(String distributorId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/dashboard/stats/$distributorId'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return {};
    }
  }
}

// Services using API
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
      print('Customers response: ${response.length} customers');
      _customers = response.map((data) {
        final id = data['_id']?.toString() ?? data['id']?.toString() ?? '';
        return CustomerModel.fromMap(data, id);
      }).toList();
      print('Loaded ${_customers.length} customers');
      return _customers;
    } catch (e) {
      print('Error in getCustomers: $e');
      return [];
    }
  }

  Future<void> addCustomer(CustomerModel customer) async {
    try {
      final response = await ApiService.addCustomer(customer.toMap());
      final newCustomer = CustomerModel.fromMap(response, response['_id']?.toString() ?? customer.id);
      _customers.add(newCustomer);
    } catch (e) {
      print('Error adding customer: $e');
      _customers.add(customer);
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      final updateMap = customer.toMap();
      await ApiService.updateCustomer(customer.id, updateMap);
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
      }
    } catch (e) {
      print('Error updating customer: $e');
      throw e;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.apiUrl}/customers/$customerId'),
      );
      
      if (response.statusCode == 200) {
        _customers.removeWhere((c) => c.id == customerId);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete customer');
      }
    } catch (e) {
      print('Error deleting customer: $e');
      throw e;
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
      print('Products response: ${response.length} products');
      _products = response.map((data) {
        final id = data['_id']?.toString() ?? data['id']?.toString() ?? '';
        return ProductModel.fromMap(data, id);
      }).toList();
      print('Loaded ${_products.length} products');
      return _products;
    } catch (e) {
      print('Error in getProducts: $e');
      return [];
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      final response = await ApiService.addProduct(product.toMap());
      final newProduct = ProductModel.fromMap(response, response['_id']?.toString() ?? product.id);
      _products.add(newProduct);
    } catch (e) {
      print('Error adding product: $e');
      _products.add(product);
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.apiUrl}/products/${product.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toMap()),
      );
      
      if (response.statusCode == 200) {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = product;
        }
      } else {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      print('Error updating product: $e');
      throw e;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.apiUrl}/products/$productId'),
      );
      
      if (response.statusCode == 200) {
        _products.removeWhere((p) => p.id == productId);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete product');
      }
    } catch (e) {
      print('Error deleting product: $e');
      throw e;
    }
  }

  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.apiUrl}/products/$productId/stock'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'newStock': newStock}),
      );
      
      if (response.statusCode == 200) {
        final index = _products.indexWhere((p) => p.id == productId);
        if (index != -1) {
          _products[index] = ProductModel(
            id: _products[index].id,
            name: _products[index].name,
            sku: _products[index].sku,
            price: _products[index].price,
            mrp: _products[index].mrp,
            category: _products[index].category,
            stock: newStock,
            description: _products[index].description,
            createdAt: _products[index].createdAt,
            updatedAt: DateTime.now(),
            createdBy: _products[index].createdBy,
            distributorId: _products[index].distributorId,
          );
        }
      }
    } catch (e) {
      print('Error updating product stock: $e');
      throw e;
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
      print('Salesmen response: ${response.length} salesmen');
      _salesmen = response.map((data) {
        final id = data['_id']?.toString() ?? data['id']?.toString() ?? '';
        return SalesmanModel.fromMap(data, id);
      }).toList();
      print('Loaded ${_salesmen.length} salesmen');
      return _salesmen;
    } catch (e) {
      print('Error in getSalesmen: $e');
      return [];
    }
  }

  Future<void> addSalesman(SalesmanModel salesman) async {
    try {
      final response = await ApiService.addSalesman(salesman.toMap());
      final newSalesman = SalesmanModel.fromMap(response, response['_id']?.toString() ?? salesman.id);
      _salesmen.add(newSalesman);
      
      if (response['defaultPassword'] != null) {
        print('Salesman default password: ${response['defaultPassword']}');
      }
    } catch (e) {
      print('Error adding salesman: $e');
      _salesmen.add(salesman);
    }
  }

  Future<void> updateSalesman(SalesmanModel salesman) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.apiUrl}/salesmen/${salesman.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(salesman.toMap()),
      );
      
      if (response.statusCode == 200) {
        final index = _salesmen.indexWhere((s) => s.id == salesman.id);
        if (index != -1) {
          _salesmen[index] = salesman;
        }
      } else {
        throw Exception('Failed to update salesman');
      }
    } catch (e) {
      print('Error updating salesman: $e');
      throw e;
    }
  }

  Future<void> deleteSalesman(String salesmanId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.apiUrl}/salesmen/$salesmanId'),
      );
      
      if (response.statusCode == 200) {
        _salesmen.removeWhere((s) => s.id == salesmanId);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete salesman');
      }
    } catch (e) {
      print('Error deleting salesman: $e');
      throw e;
    }
  }
}

class OrderService {
  List<OrderModel> _orders = [];
  List<OrderModel> _draftOrders = [];
  String? _currentDistributorId;
  String? _currentSalesmanId;

  void setDistributorId(String distributorId) {
    _currentDistributorId = distributorId;
  }

  void setSalesmanId(String salesmanId) {
    _currentSalesmanId = salesmanId;
  }

  Future<List<OrderModel>> getOrders({String? customerName, String? salesmanId, DateTime? startDate, DateTime? endDate, String? search}) async {
    if (_currentDistributorId != null) {
      try {
        final response = await ApiService.getOrdersByDistributor(
          _currentDistributorId!,
          customerName: customerName,
          salesmanId: salesmanId,
          startDate: startDate,
          endDate: endDate,
          search: search,
        );
        _orders = _parseOrdersFromResponse(response);
        print('Fetched ${_orders.length} orders for distributor $_currentDistributorId');
      } catch (e) {
        print('Error fetching distributor orders: $e');
      }
    } else if (_currentSalesmanId != null) {
      try {
        final response = await ApiService.getOrdersBySalesman(_currentSalesmanId!);
        _orders = _parseOrdersFromResponse(response);
        print('Fetched ${_orders.length} orders for salesman $_currentSalesmanId');
      } catch (e) {
        print('Error fetching salesman orders: $e');
      }
    }
    return _orders;
  }

  List<OrderModel> _parseOrdersFromResponse(List<dynamic> response) {
    return response.map((data) {
      final id = data['_id']?.toString() ?? data['id']?.toString() ?? '';
      return OrderModel(
        id: id,
        orderNumber: data['orderNumber'] ?? '',
        customerId: data['customerId'] ?? '',
        customerName: data['customerName'] ?? '',
        customerPhone: data['customerPhone'] ?? '',
        areaName: data['areaName'] ?? '',
        routeName: data['routeName'] ?? '',
        salesmanId: data['salesman_id'] ?? data['salesmanId'] ?? '',
        salesmanName: data['salesmanName'] ?? '',
        items: (data['items'] as List?)?.map((item) => OrderItemModel(
          id: item['id'] ?? '',
          productId: item['productId'] ?? '',
          productName: item['productName'] ?? '',
          sku: item['sku'] ?? '',
          quantity: item['quantity'] ?? 0,
          rate: (item['rate'] ?? 0).toDouble(),
          amount: (item['amount'] ?? 0).toDouble(),
          mrp: (item['mrp'] ?? 0).toDouble(),
        )).toList() ?? [],
        totalAmount: (data['grand_total'] ?? data['totalAmount'] ?? 0).toDouble(),
        paidAmount: (data['paidAmount'] ?? 0).toDouble(),
        dueAmount: (data['dueAmount'] ?? 0).toDouble(),
        status: _parseOrderStatus(data['status'] ?? 'pending'),
        orderType: _parseOrderType(data['orderType'] ?? 'regular'),
        paymentMode: data['paymentMode'] != null ? _parsePaymentMode(data['paymentMode']) : null,
        scheduledDate: data['scheduledDate'] != null ? DateTime.tryParse(data['scheduledDate']) : null,
        notes: data['notes'],
        internalNotes: data['internalNotes'],
        createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now(),
        timeline: [],
      );
    }).toList();
  }

  OrderStatus _parseOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return OrderStatus.pending;
      case 'taken': return OrderStatus.taken;
      case 'dispatched': return OrderStatus.dispatched;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  OrderType _parseOrderType(String type) {
    switch (type.toLowerCase()) {
      case 'regular': return OrderType.regular;
      case 'urgent': return OrderType.urgent;
      default: return OrderType.regular;
    }
  }

  PaymentMode _parsePaymentMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash': return PaymentMode.cash;
      case 'upi': return PaymentMode.upi;
      case 'banktransfer': return PaymentMode.bankTransfer;
      case 'credit': return PaymentMode.credit;
      case 'partial': return PaymentMode.partial;
      case 'cheque': return PaymentMode.cheque;
      case 'chequewithcash': return PaymentMode.chequeWithCash;
      default: return PaymentMode.credit;
    }
  }

  Future<void> createOrder(OrderModel order, String? currentDistributorId, String? currentSalesmanId) async {
    try {
      final orderMap = {
        'orderNumber': order.orderNumber,
        'customerId': order.customerId,
        'customerName': order.customerName,
        'customerPhone': order.customerPhone,
        'areaName': order.areaName,
        'routeName': order.routeName,
        'salesman_id': order.salesmanId,
        'salesmanName': order.salesmanName,
        'distributor_id': currentDistributorId,
        'distributorId': currentDistributorId,
        'items': order.items.map((item) => {
          'productId': item.productId,
          'productName': item.productName,
          'sku': item.sku,
          'quantity': item.quantity,
          'rate': item.rate,
          'amount': item.amount,
          'mrp': item.mrp != null && item.mrp! > 0 ? item.mrp : item.rate,
        }).toList(),
        'totalAmount': order.totalAmount,
        'paidAmount': order.paidAmount,
        'dueAmount': order.dueAmount,
        'grand_total': order.totalAmount,
        'order_total': order.totalAmount,
        'status': order.status.toString().split('.').last,
        'orderType': order.orderType.toString().split('.').last,
        'paymentMode': order.paymentMode?.toString().split('.').last,
        'payment_method': order.paymentMode?.toString().split('.').last,
        'payment_status': order.paidAmount >= order.totalAmount ? 'paid' : 'pending',
        'scheduledDate': order.scheduledDate?.toIso8601String(),
        'notes': order.notes,
        'internalNotes': order.internalNotes,
        'customer': {
          'customer_id': order.customerId,
          'name': order.customerName,
          'phone': order.customerPhone,
        },
        'created_by_type': currentSalesmanId != null ? 'salesman' : 'distributor',
        'salesmanName': order.salesmanName,
      };
      
      final response = await ApiService.createOrder(orderMap);
      print('Order created successfully: ${response['orderNumber']}');
      _orders.add(order);
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  Future<void> editOrder(OrderModel order) async {
    try {
      final orderMap = {
        'customerId': order.customerId,
        'customerName': order.customerName,
        'customerPhone': order.customerPhone,
        'areaName': order.areaName,
        'routeName': order.routeName,
        'items': order.items.map((item) => {
          'productId': item.productId,
          'productName': item.productName,
          'sku': item.sku,
          'quantity': item.quantity,
          'rate': item.rate,
          'amount': item.amount,
          'mrp': item.mrp != null && item.mrp! > 0 ? item.mrp : item.rate,
        }).toList(),
        'totalAmount': order.totalAmount,
        'paidAmount': order.paidAmount,
        'dueAmount': order.dueAmount,
        'grand_total': order.totalAmount,
        'status': order.status.toString().split('.').last,
        'orderType': order.orderType.toString().split('.').last,
        'paymentMode': order.paymentMode?.toString().split('.').last,
        'notes': order.notes,
        'internalNotes': order.internalNotes,
      };
      
      final response = await ApiService.editOrder(order.id, orderMap);
      print('Order edited successfully: ${response['message']}');
      
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = order;
      }
    } catch (e) {
      print('Error editing order: $e');
      rethrow;
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      final response = await ApiService.deleteOrder(orderId);
      print('Order deleted successfully: ${response['message']}');
      _orders.removeWhere((o) => o.id == orderId);
    } catch (e) {
      print('Error deleting order: $e');
      rethrow;
    }
  }

  double _getProductMrp(String productId) {
    return 0;
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

  // FIXED: Enhanced recordPayment method to properly pass all cheque and UPI details
  Future<void> recordPayment(String orderId, double amount, PaymentMode mode, 
      {String? reference, String? collectedBy, String? salesmanId, 
      String? chequeNumber, String? chequeDate, String? bankName,
      String? upiType, String? transactionNumber, String? remark,
      File? paymentPhoto}) async {
    try {
      final paymentData = {
        'amount': amount,
        'paymentMode': mode.toString().split('.').last,
        'reference': reference,
        'collectedBy': salesmanId ?? collectedBy,
        'collectedByName': collectedBy ?? '',
        'collectedByType': salesmanId != null ? 'salesman' : 'distributor',
        'salesmanId': salesmanId,
        'salesmanName': salesmanId != null ? 'Salesman' : null,
        'remark': remark,
      };
      
      Map<String, dynamic> response;
      
      // Always use file upload method for cheque and UPI payments to ensure all details are sent
      if (mode == PaymentMode.cheque) {
        response = await ApiService.recordPaymentWithFile(
          orderId: orderId,
          amount: amount,
          paymentMode: mode.toString().split('.').last,
          collectedBy: salesmanId ?? collectedBy ?? '',
          collectedByName: collectedBy ?? '',
          collectedByType: salesmanId != null ? 'salesman' : 'distributor',
          salesmanId: salesmanId,
          chequeNumber: chequeNumber,
          chequeDate: chequeDate,
          bankName: bankName,
          remark: remark,
          paymentPhoto: paymentPhoto,
        );
        print('Cheque payment recorded: Number=$chequeNumber, Bank=$bankName, Date=$chequeDate');
      } else if (mode == PaymentMode.upi) {
        response = await ApiService.recordPaymentWithFile(
          orderId: orderId,
          amount: amount,
          paymentMode: mode.toString().split('.').last,
          collectedBy: salesmanId ?? collectedBy ?? '',
          collectedByName: collectedBy ?? '',
          collectedByType: salesmanId != null ? 'salesman' : 'distributor',
          salesmanId: salesmanId,
          upiType: upiType,
          transactionNumber: transactionNumber,
          remark: remark,
          paymentPhoto: paymentPhoto,
        );
        print('UPI payment recorded: Type=$upiType, Transaction=$transactionNumber');
      } else {
        response = await ApiService.recordPayment(orderId, paymentData);
      }
      
      print('Payment response: $response');
      
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
    } catch (e) {
      print('Error recording payment: $e');
      rethrow;
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

// ==================== NOTIFICATION SERVICE ====================
class NotificationService {
  int _unreadCount = 0;
  List<NotificationModel> _notifications = [];
  Timer? _pollingTimer;
  Function(int)? _onUnreadCountChanged;
  String? _currentDistributorId;

  void init(String distributorId, {Function(int)? onUnreadCountChanged}) {
    _currentDistributorId = distributorId;
    _onUnreadCountChanged = onUnreadCountChanged;
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchUnreadCount();
    });
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    if (_currentDistributorId == null) return;
    try {
      final count = await ApiService.getUnreadNotificationCount(_currentDistributorId!);
      if (count != _unreadCount) {
        _unreadCount = count;
        _onUnreadCountChanged?.call(count);
      }
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  Future<List<NotificationModel>> getNotifications() async {
    if (_currentDistributorId == null) return [];
    try {
      final response = await ApiService.getNotifications(_currentDistributorId!);
      _notifications = response.map((data) {
        final id = data['_id']?.toString() ?? '';
        return NotificationModel.fromMap(data, id);
      }).toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      _onUnreadCountChanged?.call(_unreadCount);
      return _notifications;
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await ApiService.markNotificationRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          distributorId: _notifications[index].distributorId,
          orderId: _notifications[index].orderId,
          orderNumber: _notifications[index].orderNumber,
          customerName: _notifications[index].customerName,
          salesmanName: _notifications[index].salesmanName,
          amount: _notifications[index].amount,
          message: _notifications[index].message,
          type: _notifications[index].type,
          isRead: true,
          createdAt: _notifications[index].createdAt,
          readAt: DateTime.now(),
          orderData: _notifications[index].orderData,
        );
        _unreadCount--;
        _onUnreadCountChanged?.call(_unreadCount);
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_currentDistributorId == null) return;
    try {
      await ApiService.markAllNotificationsRead(_currentDistributorId!);
      _notifications = _notifications.map((n) => NotificationModel(
        id: n.id,
        distributorId: n.distributorId,
        orderId: n.orderId,
        orderNumber: n.orderNumber,
        customerName: n.customerName,
        salesmanName: n.salesmanName,
        amount: n.amount,
        message: n.message,
        type: n.type,
        isRead: true,
        createdAt: n.createdAt,
        readAt: DateTime.now(),
        orderData: n.orderData,
      )).toList();
      _unreadCount = 0;
      _onUnreadCountChanged?.call(0);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
  }
}

// ==================== COLLECTION HISTORY SERVICE ====================
class CollectionHistoryService {
  List<CollectionHistoryModel> _collections = [];
  Map<String, dynamic> _summary = {};
  String? _currentDistributorId;
  String? _currentSalesmanId;

  void setDistributorId(String distributorId) {
    _currentDistributorId = distributorId;
  }

  void setSalesmanId(String salesmanId) {
    _currentSalesmanId = salesmanId;
  }

  Future<Map<String, dynamic>> getCollectionHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? salesmanId,
  }) async {
    if (_currentDistributorId != null) {
      final data = await ApiService.getCollectionHistoryForDistributor(
        _currentDistributorId!,
        startDate: startDate,
        endDate: endDate,
        salesmanId: salesmanId,
      );
      _collections = (data['collections'] as List?)?.map((c) {
        final id = c['_id']?.toString() ?? '';
        return CollectionHistoryModel.fromMap(c, id);
      }).toList() ?? [];
      _summary = data['summary'] ?? {};
      return data;
    } else if (_currentSalesmanId != null) {
      final data = await ApiService.getCollectionHistoryForSalesman(
        _currentSalesmanId!,
        startDate: startDate,
        endDate: endDate,
      );
      _collections = (data['collections'] as List?)?.map((c) {
        final id = c['_id']?.toString() ?? '';
        return CollectionHistoryModel.fromMap(c, id);
      }).toList() ?? [];
      _summary = data['summary'] ?? {};
      return data;
    }
    return {'collections': [], 'summary': {}};
  }

  Future<Map<String, dynamic>> reconcileCollections({
    required double expectedAmount,
    DateTime? date,
  }) async {
    if (_currentDistributorId == null) {
      return {'is_matching': false, 'difference': expectedAmount};
    }
    return await ApiService.reconcileCollections(
      _currentDistributorId!,
      expectedAmount: expectedAmount,
      date: date,
    );
  }

  List<CollectionHistoryModel> get collections => _collections;
  Map<String, dynamic> get summary => _summary;
  double get totalCollected => _summary['total_collected'] ?? 0.0;
  int get totalTransactions => _summary['total_transactions'] ?? 0;
  List<dynamic> get salesmanWise => _summary['salesman_wise'] ?? [];
}

// ==================== PASSWORD CHANGE DIALOG ====================
class ChangePasswordDialog extends StatefulWidget {
  final UserModel currentUser;
  final bool isDistributor;
  final List<Map<String, dynamic>>? users;

  const ChangePasswordDialog({
    super.key,
    required this.currentUser,
    this.isDistributor = false,
    this.users,
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  String? _selectedUserId;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final userId = widget.isDistributor && _selectedUserId != null
        ? _selectedUserId!
        : widget.currentUser.id;
    
    if (_newPasswordController.text.isEmpty) {
      showSafeSnackBar(context, 'Please enter new password', backgroundColor: Colors.red);
      return;
    }
    
    if (_newPasswordController.text.length < 4) {
      showSafeSnackBar(context, 'Password must be at least 4 characters', backgroundColor: Colors.red);
      return;
    }
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      showSafeSnackBar(context, 'New passwords do not match', backgroundColor: Colors.red);
      return;
    }
    
    if (!widget.isDistributor && _currentPasswordController.text.isEmpty) {
      showSafeSnackBar(context, 'Please enter current password', backgroundColor: Colors.red);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService.changePassword(
        userId: userId,
        currentPassword: widget.isDistributor ? null : _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        requestingUserId: widget.currentUser.id,
        requestingUserRole: widget.currentUser.role == UserRole.distributor ? 'distributor' : 'salesman',
      );
      
      if (response['success'] == true) {
        if (mounted) {
          showSafeSnackBar(context, '✅ Password changed successfully!', backgroundColor: Colors.green);
          Navigator.pop(context);
        }
      } else {
        showSafeSnackBar(context, response['error'] ?? 'Failed to change password', backgroundColor: Colors.red);
      }
    } catch (e) {
      showSafeSnackBar(context, 'Error: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock_reset, color: const Color(0xFF1A3B70)),
          const SizedBox(width: 8),
          Text(widget.isDistributor ? 'Change Password' : 'Change Your Password'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isDistributor && widget.users != null && widget.users!.isNotEmpty)
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Select User',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select a user')),
                      ...widget.users!.map((user) => DropdownMenuItem(
                        value: user['id'],
                        child: Text('${user['name']} (${user['role']})'),
                      )),
                    ],
                    onChanged: (value) => setState(() => _selectedUserId = value),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            if (!widget.isDistributor)
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            if (!widget.isDistributor) const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: const OutlineInputBorder(),
              ),
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
          onPressed: _isLoading ? null : _changePassword,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A68A)),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Change Password'),
        ),
      ],
    );
  }
}

// ==================== IMPORT MASTER DATA DIALOG ====================
class ImportMasterDataDialog extends StatefulWidget {
  final String distributorId;
  final String createdBy;
  final Function onImportComplete;

  const ImportMasterDataDialog({
    super.key,
    required this.distributorId,
    required this.createdBy,
    required this.onImportComplete,
  });

  @override
  State<ImportMasterDataDialog> createState() => _ImportMasterDataDialogState();
}

class _ImportMasterDataDialogState extends State<ImportMasterDataDialog> {
  String? _selectedMasterType;
  File? _selectedFile;
  bool _isImporting = false;
  String? _importMessage;
  bool _updateExisting = true;

  final List<Map<String, dynamic>> _masterTypes = [
    {'value': 'customer', 'label': 'Customers', 'icon': Icons.people},
    {'value': 'product', 'label': 'Products', 'icon': Icons.inventory_2},
  ];

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _importMessage = null;
        });
      }
    } catch (e) {
      showSafeSnackBar(context, 'Error picking file: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _importData() async {
    if (_selectedMasterType == null) {
      showSafeSnackBar(context, 'Please select master type', backgroundColor: Colors.red);
      return;
    }
    
    if (_selectedFile == null) {
      showSafeSnackBar(context, 'Please select an Excel file', backgroundColor: Colors.red);
      return;
    }
    
    setState(() {
      _isImporting = true;
      _importMessage = null;
    });
    
    try {
      Map<String, dynamic> result;
      
      if (_selectedMasterType == 'customer') {
        result = await ApiService.importCustomersFromExcel(
          filePath: _selectedFile!.path,
          distributorId: widget.distributorId,
          createdBy: widget.createdBy,
          updateExisting: _updateExisting,
        );
      } else {
        result = await ApiService.importProductsFromExcel(
          filePath: _selectedFile!.path,
          distributorId: widget.distributorId,
          createdBy: widget.createdBy,
          updateExisting: _updateExisting,
        );
      }
      
      if (result['success'] == true) {
        setState(() {
          _importMessage = result['message'];
        });
        widget.onImportComplete();
        
        showSafeSnackBar(
          context,
          result['message'],
          backgroundColor: Colors.green,
        );
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        setState(() {
          _importMessage = result['error'] ?? 'Import failed';
        });
        showSafeSnackBar(context, _importMessage!, backgroundColor: Colors.red);
      }
    } catch (e) {
      setState(() {
        _importMessage = 'Error: $e';
      });
      showSafeSnackBar(context, 'Error importing data: $e', backgroundColor: Colors.red);
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.upload_file, color: const Color(0xFF1A3B70)),
                  const SizedBox(width: 12),
                  const Text(
                    'Import Master Data',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3B70),
                    ),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              
              const Text(
                'Select Master Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _masterTypes.map((type) {
                  final isSelected = _selectedMasterType == type['value'];
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(type['icon'], size: 18, color: isSelected ? Colors.white : const Color(0xFF1A3B70)),
                        const SizedBox(width: 6),
                        Text(type['label']),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMasterType = selected ? type['value'] : null;
                        _importMessage = null;
                      });
                    },
                    selectedColor: const Color(0xFF00A68A),
                    backgroundColor: Colors.grey[200],
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  const Text(
                    'Update Existing Records:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _updateExisting,
                    onChanged: (value) => setState(() => _updateExisting = value),
                    activeColor: const Color(0xFF00A68A),
                  ),
                  Text(
                    _updateExisting ? 'Yes (Update)' : 'No (Skip)',
                    style: TextStyle(
                      color: _updateExisting ? const Color(0xFF00A68A) : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              const Text(
                'Excel File Format',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Customer Excel Columns:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Customer Code, Customer Name, Area, Route, Address, Distributor id',
                      style: TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '📦 Product Excel Columns:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'product name, Product code, MRP, Price, Category, Stock Quantity, Description, Distirbutor Id',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _selectedFile != null 
                      ? 'Selected: ${_selectedFile!.path.split('/').last}' 
                      : 'Choose Excel File',
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3B70),
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
              
              if (_selectedFile != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'File ready to import',
                          style: TextStyle(color: Colors.green[700], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (_importMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _importMessage!.contains('Error') ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _importMessage!.contains('Error') ? Colors.red[200]! : Colors.green[200]!,
                    ),
                  ),
                  child: Text(
                    _importMessage!,
                    style: TextStyle(
                      color: _importMessage!.contains('Error') ? Colors.red[700] : Colors.green[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isImporting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isImporting || _selectedMasterType == null || _selectedFile == null)
                          ? null
                          : _importData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A68A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isImporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Import'),
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
}

// ==================== COLLECTION HISTORY DIALOG ====================
class CollectionHistoryDialog extends StatefulWidget {
  final CollectionHistoryService collectionHistoryService;
  final List<SalesmanModel> salesmen;
  final bool isDistributor;

  const CollectionHistoryDialog({
    super.key,
    required this.collectionHistoryService,
    required this.salesmen,
    required this.isDistributor,
  });

  @override
  State<CollectionHistoryDialog> createState() => _CollectionHistoryDialogState();
}

class _CollectionHistoryDialogState extends State<CollectionHistoryDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedSalesmanId;
  bool _isLoading = false;
  List<CollectionHistoryModel> _collections = [];
  Map<String, dynamic> _summary = {};
  String? _reconciliationMessage;
  bool _showReconcile = false;
  final TextEditingController _expectedAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.collectionHistoryService.getCollectionHistory(
        startDate: _startDate,
        endDate: _endDate,
        salesmanId: _selectedSalesmanId,
      );
      setState(() {
        _collections = widget.collectionHistoryService.collections;
        _summary = widget.collectionHistoryService.summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      showSafeSnackBar(context, 'Error loading collections: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _reconcileCollections() async {
    if (_expectedAmountController.text.isEmpty) {
      showSafeSnackBar(context, 'Please enter expected amount', backgroundColor: Colors.red);
      return;
    }
    
    final expectedAmount = double.tryParse(_expectedAmountController.text);
    if (expectedAmount == null) {
      showSafeSnackBar(context, 'Please enter a valid amount', backgroundColor: Colors.red);
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final result = await widget.collectionHistoryService.reconcileCollections(
        expectedAmount: expectedAmount,
        date: DateTime.now(),
      );
      setState(() {
        _reconciliationMessage = result['message'];
        _isLoading = false;
      });
      
      showSafeSnackBar(
        context,
        result['message'],
        backgroundColor: result['is_matching'] == true ? Colors.green : Colors.orange,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      showSafeSnackBar(context, 'Error reconciling: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A3B70),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Collection History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.green),
                          const SizedBox(height: 4),
                          Text(
                            '₹${widget.collectionHistoryService.totalCollected.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text('Total Collected', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long, color: Colors.blue),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.collectionHistoryService.totalTransactions}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text('Transactions', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isDistributor)
                    DropdownButtonFormField<String>(
                      value: _selectedSalesmanId,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Salesman',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Salesmen')),
                        ...widget.salesmen.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSalesmanId = value);
                        _loadCollections();
                      },
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _startDate = date);
                              _loadCollections();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(_startDate != null
                                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                    : 'Start Date'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _endDate = date);
                              _loadCollections();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(_endDate != null
                                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                    : 'End Date'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (widget.isDistributor)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.compare_arrows, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Cash Reconciliation',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            _showReconcile ? Icons.expand_less : Icons.expand_more,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _showReconcile = !_showReconcile),
                        ),
                      ],
                    ),
                    if (_showReconcile) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _expectedAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Expected Cash Amount',
                          border: OutlineInputBorder(),
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _reconcileCollections,
                              icon: const Icon(Icons.calculate, size: 16),
                              label: const Text('Reconcile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_reconciliationMessage != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _reconciliationMessage!.contains('match')
                                ? Colors.green[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _reconciliationMessage!,
                            style: TextStyle(
                              color: _reconciliationMessage!.contains('match')
                                  ? Colors.green[800]
                                  : Colors.red[800],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _collections.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 50, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('No collection records found', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _collections.length,
                          itemBuilder: (context, index) {
                            final collection = _collections[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        collection.billNo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          collection.paymentMode,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    collection.customerName,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order Amount: ₹${collection.orderAmount.toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                          Text(
                                            'Collected: ₹${collection.amountCollected.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          if (collection.salesmanDetails != null)
                                            Text(
                                              'By: ${collection.salesmanDetails!['name']}',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          Text(
                                            'Date: ${collection.collectionDate.day}/${collection.collectionDate.month}/${collection.collectionDate.year}',
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (collection.chequeNumber != null && collection.chequeNumber!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Cheque: ${collection.chequeNumber} (${collection.bankName ?? ''})',
                                        style: const TextStyle(fontSize: 10, color: Colors.orange),
                                      ),
                                    ),
                                  if (collection.transactionNumber != null && collection.transactionNumber!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'UPI Transaction: ${collection.transactionNumber} (${collection.upiType ?? ''})',
                                        style: const TextStyle(fontSize: 10, color: Colors.purple),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
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

class _DistributorDashboardEnhancedState extends State<DistributorDashboardEnhanced> {
  static const Color primaryBlue = Color(0xFF1A3B70);
  static const Color accentTeal = Color(0xFF00A68A);
  static const Color secondaryBlue = Color(0xFF2C599D);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53935);
  static const Color cardPurple = Color(0xFF9B59B6);

  ThemeMode _themeMode = ThemeMode.light;

  int _selectedIndex = 0;
  bool _isSidebarOpen = false;

  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  final SalesmanService _salesmanService = SalesmanService();
  final NotificationService _notificationService = NotificationService();
  final CollectionHistoryService _collectionHistoryService = CollectionHistoryService();

  late UserModel _currentDistributor;

  List<CustomerModel> _customers = [];
  List<ProductModel> _products = [];
  List<OrderModel> _orders = [];
  List<SalesmanModel> _salesmen = [];
  List<OrderTemplateModel> _orderTemplates = [];
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  int _unreadNotificationCount = 0;

  final SyncService _syncService = SyncService();
  bool _isSyncing = false;
  final Map<String, CartItemData> _cart = {};

  int _orderStep = 1;
  String? _selectedCustomerId;
  String? _selectedSalesmanId;
  OrderType _selectedOrderType = OrderType.regular;
  DateTime? _scheduledDate;
  PaymentMode _selectedPaymentMode = PaymentMode.credit;
  String _orderNotes = '';
  String _internalNotes = '';

  final Set<String> _stockAlertShown = {};

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;

  String _searchType = 'All';
  final TextEditingController _orderSearchController = TextEditingController();
  String _orderSearchQuery = '';

  String? _selectedOrderSalesmanId;
  String _orderCustomerFilter = '';
  DateTime? _orderStartDate;
  DateTime? _orderEndDate;

  final Set<String> _selectedOrderIds = {};
  bool _isPostingToDesktop = false;

  final TextEditingController _customerSearchController = TextEditingController();
  String _customerSearchQuery = '';

  final TextEditingController _productSearchController = TextEditingController();
  String _productSearchQuery = '';

  final TextEditingController _salesmanSearchController = TextEditingController();
  String _salesmanSearchQuery = '';

  final TextEditingController _paymentAmountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _chequeNumberController = TextEditingController();
  final TextEditingController _chequeDateController = TextEditingController();
  final TextEditingController _chequeAmountController = TextEditingController();
  final TextEditingController _cashAmountController = TextEditingController();
  final TextEditingController _transactionNumberController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  String? _selectedUpiType;
  File? _paymentScreenshotPath;
  String? _selectedBankName;
  List<String> _banksList = [];
  List<String> _upiTypesList = [];

  String _analyticsTimeFilter = 'month';
  double _monthlyTarget = 500000;

  List<OrderModel> _draftOrders = [];

  List<String> _availableAreas = [];
  List<String> _availableRoutes = [];
  String? _selectedArea;
  String? _selectedRoute;
  bool _isLoadingAreas = false;
  final TextEditingController _areaSearchController = TextEditingController();
  final TextEditingController _routeSearchController = TextEditingController();

  List<Map<String, dynamic>> _usersUnderDistributor = [];
  bool _isLoadingUsers = false;

  bool _isDownloading = false;
  String? _downloadFilterType;

  List<dynamic> _globalSearchProducts = [];
  List<dynamic> _globalSearchCustomers = [];
  List<dynamic> _globalSearchOrders = [];
  bool _isGlobalSearching = false;

  OrderModel? _orderToEdit;
  bool _isEditingOrder = false;
  final Map<String, CartItemData> _editCart = {};

  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _salesmanPerformance = [];

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

  List<String> get categories {
    return _products.map((p) => p.category).toSet().toList();
  }

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

  List<OrderModel> get filteredOrders {
    var orders = _orders;
    if (_selectedOrderSalesmanId != null && _selectedOrderSalesmanId!.isNotEmpty && _selectedOrderSalesmanId != 'all') {
      orders = orders
          .where((o) => o.salesmanId == _selectedOrderSalesmanId)
          .toList();
    }
    if (_orderCustomerFilter.isNotEmpty) {
      final query = _orderCustomerFilter.toLowerCase();
      orders = orders
          .where((o) => o.customerName.toLowerCase().contains(query))
          .toList();
    }
    if (_orderStartDate != null) {
      orders = orders
          .where((o) => o.createdAt.isAfter(_orderStartDate!) || o.createdAt.isAtSameMomentAs(_orderStartDate!))
          .toList();
    }
    if (_orderEndDate != null) {
      orders = orders
          .where((o) => o.createdAt.isBefore(_orderEndDate!) || o.createdAt.isAtSameMomentAs(_orderEndDate!))
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
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
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

  Future<double> getCustomerOutstanding(String customerId) async {
    return await ApiService.getCustomerOutstanding(customerId);
  }

  Future<OrderModel?> getLastOrderForCustomer(String customerId) async {
    try {
      final response = await ApiService.getLastOrderByCustomer(customerId);
      if (response.isNotEmpty && response['orderNumber'] != null) {
        return OrderModel(
          id: response['_id']?.toString() ?? '',
          orderNumber: response['orderNumber'] ?? '',
          customerId: response['customerId'] ?? '',
          customerName: response['customerName'] ?? '',
          customerPhone: response['customerPhone'] ?? '',
          areaName: response['areaName'] ?? '',
          routeName: response['routeName'] ?? '',
          salesmanId: response['salesman_id'] ?? '',
          salesmanName: response['salesmanName'] ?? '',
          items: (response['items'] as List?)?.map((item) => OrderItemModel(
            id: item['id'] ?? '',
            productId: item['productId'] ?? '',
            productName: item['productName'] ?? '',
            sku: item['sku'] ?? '',
            quantity: item['quantity'] ?? 0,
            rate: (item['rate'] ?? 0).toDouble(),
            amount: (item['amount'] ?? 0).toDouble(),
            mrp: (item['mrp'] ?? 0).toDouble(),
          )).toList() ?? [],
          totalAmount: (response['grand_total'] ?? 0).toDouble(),
          paidAmount: (response['paidAmount'] ?? 0).toDouble(),
          dueAmount: (response['dueAmount'] ?? 0).toDouble(),
          status: _parseOrderStatus(response['status'] ?? 'pending'),
          orderType: _parseOrderType(response['orderType'] ?? 'regular'),
          paymentMode: null,
          scheduledDate: null,
          notes: response['notes'],
          internalNotes: response['internalNotes'],
          createdAt: response['createdAt'] != null ? DateTime.parse(response['createdAt']) : DateTime.now(),
          timeline: [],
        );
      }
      return null;
    } catch (e) {
      print('Error fetching last order: $e');
      return null;
    }
  }

  OrderStatus _parseOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return OrderStatus.pending;
      case 'taken': return OrderStatus.taken;
      case 'dispatched': return OrderStatus.dispatched;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  OrderType _parseOrderType(String type) {
    switch (type.toLowerCase()) {
      case 'regular': return OrderType.regular;
      case 'urgent': return OrderType.urgent;
      default: return OrderType.regular;
    }
  }

  OrderModel? getLastOrderForSalesman(String salesmanId) {
    final salesmanOrders = _orders
        .where((o) => o.salesmanId == salesmanId)
        .toList();
    if (salesmanOrders.isEmpty) return null;
    salesmanOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return salesmanOrders.first;
  }

  int getSalesmanOrderCount(String salesmanId) {
    return _orders.where((o) => o.salesmanId == salesmanId).length;
  }

  double getSalesmanRevenue(String salesmanId) {
    return _orders
        .where(
          (o) =>
              o.salesmanId == salesmanId && o.status != OrderStatus.cancelled,
        )
        .fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  double getSalesmanCollection(String salesmanId) {
    return _orders
        .where(
          (o) =>
              o.salesmanId == salesmanId && o.status != OrderStatus.cancelled,
        )
        .fold(0.0, (sum, o) => sum + o.paidAmount);
  }

  Future<Map<String, dynamic>?> getLastSaleForProduct(String productId) async {
    try {
      final response = await ApiService.getLastSaleForProduct(productId);
      if (response.isNotEmpty) {
        return response;
      }
      return null;
    } catch (e) {
      print('Error fetching last sale: $e');
      return null;
    }
  }

  Future<void> _applyOrderFilters() async {
    setState(() => _isLoading = true);
    await _loadOrders();
    setState(() => _isLoading = false);
  }

  Future<void> _loadOrders() async {
    if (_currentDistributor.distributorId != null) {
      final orders = await _orderService.getOrders(
        customerName: _orderCustomerFilter.isNotEmpty ? _orderCustomerFilter : null,
        salesmanId: _selectedOrderSalesmanId,
        startDate: _orderStartDate,
        endDate: _orderEndDate,
        search: _orderSearchQuery.isNotEmpty ? _orderSearchQuery : null,
      );
      setState(() {
        _orders = orders;
      });
    }
  }

  Future<void> _performGlobalSearch(String query) async {
    if (query.trim().isEmpty || query.trim().length < 2) {
      setState(() {
        _globalSearchProducts = [];
        _globalSearchCustomers = [];
        _globalSearchOrders = [];
      });
      return;
    }

    if (_currentDistributor.distributorId == null) return;

    setState(() => _isGlobalSearching = true);

    try {
      final result = await ApiService.searchGlobal(_currentDistributor.distributorId!, query);
      setState(() {
        _globalSearchProducts = result['products'] ?? [];
        _globalSearchCustomers = result['customers'] ?? [];
        _globalSearchOrders = result['orders'] ?? [];
        _isGlobalSearching = false;
      });
    } catch (e) {
      print('Error performing global search: $e');
      setState(() => _isGlobalSearching = false);
    }
  }

  Future<Directory> _getExcelSaveDirectory() async {
    if (kIsWeb) {
      return await getTemporaryDirectory();
    }
    
    Directory? targetDir;
    
    if (Platform.isAndroid) {
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          String path = externalDir.path;
          if (path.contains('/Android/')) {
            path = path.substring(0, path.indexOf('/Android/'));
          }
          targetDir = Directory('$path/TotalMobileExcel');
          if (!await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }
        }
      } catch (e) {
        print('Error accessing external storage: $e');
      }
    }
    
    if (targetDir == null || !await targetDir.exists()) {
      final appDir = await getApplicationDocumentsDirectory();
      targetDir = Directory('${appDir.path}/TotalMobileExcel');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
    }
    
    return targetDir;
  }

  Future<void> _downloadOrders({String? filterType, DateTime? startDate, DateTime? endDate}) async {
    if (_currentDistributor.distributorId == null) {
      showSafeSnackBar(context, 'Distributor ID not found', backgroundColor: errorRed);
      return;
    }

    setState(() => _isDownloading = true);

    try {
      String? startDateStr;
      String? endDateStr;
      
      if (filterType != null) {
        final now = DateTime.now();
        if (filterType == 'today') {
          startDateStr = DateTime(now.year, now.month, now.day).toIso8601String();
          endDateStr = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
        } else if (filterType == 'yesterday') {
          final yesterday = now.subtract(const Duration(days: 1));
          startDateStr = DateTime(yesterday.year, yesterday.month, yesterday.day).toIso8601String();
          endDateStr = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59).toIso8601String();
        } else if (filterType == 'lastWeek') {
          final lastWeek = now.subtract(const Duration(days: 7));
          startDateStr = DateTime(lastWeek.year, lastWeek.month, lastWeek.day).toIso8601String();
          endDateStr = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
        }
      } else if (startDate != null && endDate != null) {
        startDateStr = DateTime(startDate.year, startDate.month, startDate.day).toIso8601String();
        endDateStr = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).toIso8601String();
      }

      final result = await ApiService.downloadOrders(
        _currentDistributor.distributorId!,
        startDate: startDateStr,
        endDate: endDateStr,
        filterType: filterType,
      );

      if (result['success'] == true) {
        final bytes = result['data'] as List<int>;
        final saveDir = await _getExcelSaveDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'orders_$timestamp.xlsx';
        final file = File('${saveDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        showSafeSnackBar(
          context, 
          '✅ Orders saved to: ${file.path}',
          backgroundColor: successGreen,
        );
        
        await Share.shareXFiles(
          [XFile(file.path)], 
          text: 'Orders Report - ${DateTime.now().toString().split(' ')[0]}',
        );
      } else {
        showSafeSnackBar(context, result['error'] ?? 'Failed to download orders', backgroundColor: errorRed);
      }
    } catch (e) {
      showSafeSnackBar(context, 'Error downloading orders: $e', backgroundColor: errorRed);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showDownloadOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Orders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today, color: primaryBlue),
              title: const Text('Today'),
              onTap: () {
                Navigator.pop(context);
                _downloadOrders(filterType: 'today');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: primaryBlue),
              title: const Text('Yesterday'),
              onTap: () {
                Navigator.pop(context);
                _downloadOrders(filterType: 'yesterday');
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range, color: primaryBlue),
              title: const Text('Last Week'),
              onTap: () {
                Navigator.pop(context);
                _downloadOrders(filterType: 'lastWeek');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: accentTeal),
              title: const Text('Custom Date Range'),
              onTap: () async {
                Navigator.pop(context);
                final DateTimeRange? range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: DateTimeRange(
                    start: DateTime.now().subtract(const Duration(days: 7)),
                    end: DateTime.now(),
                  ),
                );
                if (range != null && mounted) {
                  _downloadOrders(startDate: range.start, endDate: range.end);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportMasterDataDialog() {
    showDialog(
      context: context,
      builder: (context) => ImportMasterDataDialog(
        distributorId: _currentDistributor.distributorId ?? '',
        createdBy: _currentDistributor.email,
        onImportComplete: () {
          _loadData();
        },
      ),
    );
  }

  void _showCollectionHistoryDialog() {
    _collectionHistoryService.setDistributorId(_currentDistributor.distributorId!);
    showDialog(
      context: context,
      builder: (context) => CollectionHistoryDialog(
        collectionHistoryService: _collectionHistoryService,
        salesmen: _salesmen,
        isDistributor: true,
      ),
    );
  }

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

  void _toggleOrderSelection(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

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

  void _showEditOrderDialog(OrderModel order) {
    setState(() {
      _orderToEdit = order;
      _isEditingOrder = true;
      _editCart.clear();
      
      for (var item in order.items) {
        final product = _products.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => ProductModel(
            id: item.productId,
            name: item.productName,
            sku: item.sku,
            price: item.rate,
            mrp: item.rate,
            category: '',
            stock: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        _editCart[item.productId] = CartItemData(
          productId: item.productId,
          productName: item.productName,
          sku: item.sku,
          quantity: item.quantity,
          rate: item.rate,
          mrp: item.mrp ?? item.rate,
          stock: product.stock,
          schEnabled: false,
        );
        _editCart[item.productId]!.calculate();
      }
      
      _selectedCustomerId = order.customerId;
      _selectedPaymentMode = order.paymentMode ?? PaymentMode.credit;
      _orderNotes = order.notes ?? '';
    });
    
    _showEditOrderDialogInternal();
  }

  void _showEditOrderDialogInternal() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Edit Order #${_orderToEdit?.orderNumber}'),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer: ${_orderToEdit?.customerName}'),
                        Text('Order Date: ${_orderToEdit?.createdAt.day}/${_orderToEdit?.createdAt.month}/${_orderToEdit?.createdAt.year}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Payment Mode:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Credit'),
                        selected: _selectedPaymentMode == PaymentMode.credit,
                        onSelected: (_) => setDialogState(() => _selectedPaymentMode = PaymentMode.credit),
                      ),
                      ChoiceChip(
                        label: const Text('Cash'),
                        selected: _selectedPaymentMode == PaymentMode.cash,
                        onSelected: (_) => setDialogState(() => _selectedPaymentMode = PaymentMode.cash),
                      ),
                      ChoiceChip(
                        label: const Text('UPI'),
                        selected: _selectedPaymentMode == PaymentMode.upi,
                        onSelected: (_) => setDialogState(() => _selectedPaymentMode = PaymentMode.upi),
                      ),
                      ChoiceChip(
                        label: const Text('Cheque'),
                        selected: _selectedPaymentMode == PaymentMode.cheque,
                        onSelected: (_) => setDialogState(() => _selectedPaymentMode = PaymentMode.cheque),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Order Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _editCart.length,
                      itemBuilder: (context, index) {
                        final productId = _editCart.keys.elementAt(index);
                        final cartItem = _editCart[productId]!;
                        final product = _products.firstWhere(
                          (p) => p.id == productId,
                          orElse: () => ProductModel(
                            id: productId,
                            name: cartItem.productName,
                            sku: cartItem.sku,
                            price: cartItem.rate,
                            mrp: cartItem.mrp,
                            category: '',
                            stock: cartItem.stock,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cartItem.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('MRP: ₹${cartItem.mrp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text('Rate: ₹${cartItem.rate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 20),
                                    onPressed: () {
                                      final newQty = cartItem.quantity - 1;
                                      if (newQty <= 0) {
                                        setDialogState(() {
                                          _editCart.remove(productId);
                                        });
                                      } else {
                                        setDialogState(() {
                                          _editCart[productId]!.quantity = newQty;
                                          _editCart[productId]!.calculate();
                                        });
                                      }
                                    },
                                  ),
                                  Text('${cartItem.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 20),
                                    onPressed: () {
                                      if (cartItem.quantity < product.stock) {
                                        setDialogState(() {
                                          _editCart[productId]!.quantity++;
                                          _editCart[productId]!.calculate();
                                        });
                                      } else {
                                        showSafeSnackBar(context, 'Not enough stock', backgroundColor: warningOrange);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Text('₹${cartItem.netAmt.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('₹${_getEditCartTotal().toStringAsFixed(0)}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentTeal)),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: _orderNotes),
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) => _orderNotes = value,
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
                  await _submitEditOrder();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  double _getEditCartTotal() {
    double total = 0;
    for (var item in _editCart.values) {
      total += item.netAmt;
    }
    return total;
  }

  Future<void> _submitEditOrder() async {
    if (_orderToEdit == null || _editCart.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final customer = _customers.firstWhere((c) => c.id == _selectedCustomerId);
      
      final updatedOrder = OrderModel(
        id: _orderToEdit!.id,
        orderNumber: _orderToEdit!.orderNumber,
        customerId: _selectedCustomerId!,
        customerName: customer.name,
        customerPhone: customer.phone ?? customer.mobile ?? '',
        areaName: customer.area,
        routeName: customer.route ?? '',
        salesmanId: _orderToEdit!.salesmanId,
        salesmanName: _orderToEdit!.salesmanName,
        items: _editCart.entries.map((entry) {
          final item = entry.value;
          return OrderItemModel(
            id: 'item_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
            productId: item.productId,
            productName: item.productName,
            sku: item.sku,
            quantity: item.quantity,
            rate: item.rate,
            amount: item.netAmt,
            mrp: item.mrp,
          );
        }).toList(),
        totalAmount: _getEditCartTotal(),
        paidAmount: _orderToEdit!.paidAmount,
        dueAmount: _getEditCartTotal() - _orderToEdit!.paidAmount,
        status: _orderToEdit!.status,
        orderType: _orderToEdit!.orderType,
        paymentMode: _selectedPaymentMode,
        scheduledDate: _orderToEdit!.scheduledDate,
        notes: _orderNotes,
        internalNotes: _orderToEdit!.internalNotes,
        createdAt: _orderToEdit!.createdAt,
        timeline: _orderToEdit!.timeline,
      );
      
      await _orderService.editOrder(updatedOrder);
      await _loadData();
      
      if (mounted) {
        showSafeSnackBar(context, '✅ Order updated successfully!', backgroundColor: successGreen);
        setState(() {
          _orderToEdit = null;
          _isEditingOrder = false;
          _editCart.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error updating order: $e', backgroundColor: errorRed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text('Are you sure you want to delete order #${order.orderNumber}?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _orderService.deleteOrder(order.id);
      await _loadData();
      
      if (mounted) {
        showSafeSnackBar(context, '✅ Order deleted successfully!', backgroundColor: successGreen);
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error deleting order: $e', backgroundColor: errorRed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCustomer(CustomerModel customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete customer ${customer.name}?\nThis will also delete all associated data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _customerService.deleteCustomer(customer.id);
      await _loadData();
      
      if (mounted) {
        showSafeSnackBar(context, '✅ Customer deleted successfully!', backgroundColor: successGreen);
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error deleting customer: $e', backgroundColor: errorRed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete product ${product.name}?\nThis will deactivate the product.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _productService.deleteProduct(product.id);
      await _loadData();
      
      if (mounted) {
        showSafeSnackBar(context, '✅ Product deleted successfully!', backgroundColor: successGreen);
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error deleting product: $e', backgroundColor: errorRed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSalesman(SalesmanModel salesman) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Salesman'),
        content: Text('Are you sure you want to deactivate salesman ${salesman.name}?\nThey will not be able to login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _salesmanService.deleteSalesman(salesman.id);
      await _loadData();
      
      if (mounted) {
        showSafeSnackBar(context, '✅ Salesman deactivated successfully!', backgroundColor: successGreen);
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error deactivating salesman: $e', backgroundColor: errorRed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
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
        distributorId: 'DIST_DEMO_001',
      );
    }
    
    if (_currentDistributor.distributorId != null) {
      _customerService.setDistributorId(_currentDistributor.distributorId!);
      _productService.setDistributorInfo(_currentDistributor.distributorId!, _currentDistributor.email);
      _salesmanService.setDistributorInfo(_currentDistributor.distributorId!, _currentDistributor.email);
      _orderService.setDistributorId(_currentDistributor.distributorId!);
      _collectionHistoryService.setDistributorId(_currentDistributor.distributorId!);
      
      _notificationService.init(_currentDistributor.distributorId!, onUnreadCountChanged: (count) {
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      });
      
      _loadUsersUnderDistributor();
      _loadDashboardStats();
    }
    
    _loadData();
    _loadBankAndUpiLists();
    _loadNotifications();
  }

  Future<void> _loadDashboardStats() async {
    if (_currentDistributor.distributorId == null) return;
    try {
      final stats = await ApiService.getDashboardStats(_currentDistributor.distributorId!);
      setState(() {
        _dashboardStats = stats;
        _salesmanPerformance = List<Map<String, dynamic>>.from(stats['salesman_performance'] ?? []);
      });
    } catch (e) {
      print('Error loading dashboard stats: $e');
    }
  }

  Future<void> _loadUsersUnderDistributor() async {
    if (_currentDistributor.distributorId == null) return;
    setState(() => _isLoadingUsers = true);
    try {
      final users = await ApiService.getUsersUnderDistributor(_currentDistributor.distributorId!);
      setState(() {
        _usersUnderDistributor = users.map((u) => Map<String, dynamic>.from(u)).toList();
        _isLoadingUsers = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    await _loadUsersUnderDistributor();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => ChangePasswordDialog(
        currentUser: _currentDistributor,
        isDistributor: true,
        users: _usersUnderDistributor,
      ),
    );
  }

  Future<void> _loadNotifications() async {
    if (_currentDistributor.distributorId != null) {
      final notifications = await _notificationService.getNotifications();
      setState(() {
        _notifications = notifications;
        _unreadNotificationCount = notifications.where((n) => !n.isRead).length;
      });
    }
  }

  Future<void> _loadBankAndUpiLists() async {
    final banks = await ApiService.getBanks();
    final upiTypes = await ApiService.getUpiTypes();
    setState(() {
      _banksList = banks.cast<String>();
      _upiTypesList = upiTypes.cast<String>();
    });
  }

  Future<void> _loadAreas() async {
    setState(() => _isLoadingAreas = true);
    try {
      final areas = await ApiService.getAreas();
      setState(() {
        _availableAreas = areas;
        _isLoadingAreas = false;
      });
    } catch (e) {
      setState(() => _isLoadingAreas = false);
    }
  }

  Future<void> _loadRoutesForArea(String area) async {
    setState(() => _isLoadingAreas = true);
    try {
      final routes = await ApiService.getSubAreas(area: area);
      setState(() {
        _availableRoutes = routes;
        _isLoadingAreas = false;
      });
    } catch (e) {
      setState(() => _isLoadingAreas = false);
    }
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
    
    _loadDashboardStats();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.logout();
    } catch (e) {
      print('Logout API error (ignored): $e');
    }
    
    _notificationService.dispose();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    Row(
                      children: [
                        if (_unreadNotificationCount > 0)
                          TextButton.icon(
                            onPressed: () async {
                              await _notificationService.markAllAsRead();
                              setDialogState(() {
                                _notifications = _notifications.map((n) => NotificationModel(
                                  id: n.id,
                                  distributorId: n.distributorId,
                                  orderId: n.orderId,
                                  orderNumber: n.orderNumber,
                                  customerName: n.customerName,
                                  salesmanName: n.salesmanName,
                                  amount: n.amount,
                                  message: n.message,
                                  type: n.type,
                                  isRead: true,
                                  createdAt: n.createdAt,
                                  readAt: DateTime.now(),
                                  orderData: n.orderData,
                                )).toList();
                              });
                              setState(() {
                                _unreadNotificationCount = 0;
                              });
                            },
                            icon: const Icon(Icons.done_all, size: 18),
                            label: const Text('Mark all read'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: _notifications.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none, size: 60, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('No notifications', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return GestureDetector(
                              onTap: () async {
                                if (!notification.isRead) {
                                  await _notificationService.markAsRead(notification.id);
                                  setDialogState(() {
                                    _notifications[index] = NotificationModel(
                                      id: notification.id,
                                      distributorId: notification.distributorId,
                                      orderId: notification.orderId,
                                      orderNumber: notification.orderNumber,
                                      customerName: notification.customerName,
                                      salesmanName: notification.salesmanName,
                                      amount: notification.amount,
                                      message: notification.message,
                                      type: notification.type,
                                      isRead: true,
                                      createdAt: notification.createdAt,
                                      readAt: DateTime.now(),
                                      orderData: notification.orderData,
                                    );
                                  });
                                  setState(() {
                                    _unreadNotificationCount--;
                                  });
                                }
                                
                                Navigator.pop(context);
                                final order = _orders.firstWhere(
                                  (o) => o.orderNumber == notification.orderNumber,
                                  orElse: () => _orders.first,
                                );
                                _showOrderDetailsDialog(order);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: notification.isRead
                                      ? Colors.white
                                      : accentTeal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: notification.isRead
                                        ? Colors.grey.shade200
                                        : accentTeal,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: notification.isRead
                                            ? Colors.grey.shade100
                                            : accentTeal.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.shopping_bag,
                                        color: notification.isRead ? Colors.grey : accentTeal,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notification.message,
                                            style: TextStyle(
                                              fontWeight: notification.isRead
                                                  ? FontWeight.normal
                                                  : FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Order: ${notification.orderNumber} | ₹${notification.amount.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'By: ${notification.salesmanName}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!notification.isRead)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: errorRed,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void addToCart(String productId, String productName, String sku, double price, int stock) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!.quantity++;
        _cart[productId]!.calculate();
      } else {
        final product = _products.firstWhere((p) => p.id == productId);
        _cart[productId] = CartItemData(
          productId: productId,
          productName: productName,
          sku: sku,
          quantity: 1,
          rate: price,
          mrp: product.mrp,
          stock: stock,
          schEnabled: false,
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
        final product = _products.firstWhere((p) => p.id == productId);
        _cart[productId]!.quantity = quantity;
        _cart[productId]!.calculate();
        
        if (quantity > product.stock && !_stockAlertShown.contains(productId)) {
          _stockAlertShown.add(productId);
          showSafeSnackBar(
            context,
            '⚠️ Note: Only ${product.stock} in stock for ${product.name}. Remaining quantity will be fulfilled when stock arrives.',
            backgroundColor: warningOrange,
          );
        }
      }
    });
  }

  void updateCartRate(String productId, double rate) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!.rate = rate;
        _cart[productId]!.calculate();
      }
    });
  }

  void updateCartScheme(String productId, double schPer) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!.schPer = schPer;
        _cart[productId]!.calculate();
      }
    });
  }

  void toggleCartScheme(String productId) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!.schEnabled = !_cart[productId]!.schEnabled;
        _cart[productId]!.calculate();
      }
    });
  }

  double get cartTotal {
    double total = 0;
    for (var item in _cart.values) {
      total += item.netAmt;
    }
    return total;
  }

  int get cartItemCount => _cart.values.fold(0, (a, b) => a + b.quantity);
  
  int get uniqueProductCount => _cart.length;

  Future<void> submitOrder() async {
    if (_selectedCustomerId == null || _cart.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final customer = _customers.firstWhere((c) => c.id == _selectedCustomerId);
      final salesman = _selectedSalesmanId != null
          ? _salesmen.firstWhere((s) => s.id == _selectedSalesmanId)
          : (_salesmen.isNotEmpty ? _salesmen.first : null);

      final orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      
      final order = OrderModel(
        id: 'order_${DateTime.now().millisecondsSinceEpoch}',
        orderNumber: orderNumber,
        customerId: _selectedCustomerId!,
        customerName: customer.name,
        customerPhone: customer.phone ?? customer.mobile ?? '',
        areaName: customer.area,
        routeName: customer.route ?? '',
        salesmanId: salesman?.id ?? _currentDistributor.id,
        salesmanName: salesman?.name ?? _currentDistributor.name,
        items: _cart.entries.map((entry) {
          final item = entry.value;
          return OrderItemModel(
            id: 'item_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
            productId: item.productId,
            productName: item.productName,
            sku: item.sku,
            quantity: item.quantity,
            rate: item.rate,
            amount: item.netAmt,
            mrp: item.mrp,
          );
        }).toList(),
        totalAmount: cartTotal,
        paidAmount: _selectedPaymentMode == PaymentMode.cash || _selectedPaymentMode == PaymentMode.upi ? cartTotal : 0,
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

      await _orderService.createOrder(order, _currentDistributor.distributorId, null);
      
      for (var entry in _cart.entries) {
        final productId = entry.key;
        final quantity = entry.value.quantity;
        await ApiService.updateProductStock(productId, quantity);
      }
      
      if (mounted) {
        showSafeSnackBar(context, '✅ Order submitted successfully! Order ID: ${order.orderNumber}', backgroundColor: successGreen);
        _clearCart();
        await _loadData();
        
        setState(() {
          _selectedIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error submitting order: $e', backgroundColor: errorRed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _stockAlertShown.clear();
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
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    
    _selectedArea = null;
    _selectedRoute = null;
    _availableAreas = [];
    _availableRoutes = [];
    _loadAreas();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_add, color: primaryBlue),
              const SizedBox(width: 8),
              const Text('Add New Customer'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    hintText: 'Enter full name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: 'Enter 10 digit mobile number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedArea,
                  decoration: const InputDecoration(
                    labelText: 'Area / City *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select Area')),
                    ..._availableAreas.map((area) => DropdownMenuItem(
                      value: area,
                      child: Text(area),
                    )),
                  ],
                  onChanged: (value) async {
                    setDialogState(() {
                      _selectedArea = value;
                      _selectedRoute = null;
                      _availableRoutes = [];
                    });
                    if (value != null && value.isNotEmpty) {
                      final routes = await ApiService.getSubAreas(area: value);
                      setDialogState(() {
                        _availableRoutes = routes;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedRoute,
                  decoration: const InputDecoration(
                    labelText: 'Route / Sub-Area',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.route),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select Route (Optional)')),
                    ..._availableRoutes.map((route) => DropdownMenuItem(
                      value: route,
                      child: Text(route),
                    )),
                  ],
                  onChanged: (value) => setDialogState(() => _selectedRoute = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter complete address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
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
                if (nameController.text.trim().isEmpty) {
                  showSafeSnackBar(context, 'Please enter customer name', backgroundColor: errorRed);
                  return;
                }
                if (phoneController.text.trim().isEmpty) {
                  showSafeSnackBar(context, 'Please enter phone number', backgroundColor: errorRed);
                  return;
                }
                if (phoneController.text.trim().length != 10) {
                  showSafeSnackBar(context, 'Phone number must be exactly 10 digits', backgroundColor: errorRed);
                  return;
                }
                if (_selectedArea == null || _selectedArea!.isEmpty) {
                  showSafeSnackBar(context, 'Please select area', backgroundColor: errorRed);
                  return;
                }
                
                final customer = CustomerModel(
                  id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  area: _selectedArea!,
                  route: _selectedRoute,
                  address: addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  customerId: 'GK${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 13)}',
                  createdBy: _currentDistributor.email,
                  distributorId: _currentDistributor.distributorId,
                );
                await _customerService.addCustomer(customer);
                await _loadData();
                if (mounted) {
                  Navigator.pop(context);
                  showSafeSnackBar(context, '✅ Customer added successfully!', backgroundColor: successGreen);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
              child: const Text('Add Customer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final mrpController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();
    final stockController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add, color: accentTeal),
            SizedBox(width: 8),
            const Text('Add New Product'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'Enter product name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU *',
                  hintText: 'Enter unique SKU',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mrpController,
                decoration: const InputDecoration(
                  labelText: 'MRP *',
                  hintText: 'Enter maximum retail price',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Selling Price *',
                  hintText: 'Enter selling price',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  hintText: 'Enter product category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  hintText: 'Enter available stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter product description',
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
              if (nameController.text.trim().isEmpty) {
                showSafeSnackBar(context, 'Please enter product name', backgroundColor: errorRed);
                return;
              }
              if (skuController.text.trim().isEmpty) {
                showSafeSnackBar(context, 'Please enter SKU', backgroundColor: errorRed);
                return;
              }
              if (priceController.text.trim().isEmpty) {
                showSafeSnackBar(context, 'Please enter selling price', backgroundColor: errorRed);
                return;
              }
              if (categoryController.text.trim().isEmpty) {
                showSafeSnackBar(context, 'Please enter category', backgroundColor: errorRed);
                return;
              }
              
              final product = ProductModel(
                id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                sku: skuController.text.trim(),
                price: double.tryParse(priceController.text) ?? 0,
                mrp: double.tryParse(mrpController.text) ?? double.tryParse(priceController.text) ?? 0,
                category: categoryController.text.trim(),
                stock: int.tryParse(stockController.text) ?? 0,
                description: descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : null,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                createdBy: _currentDistributor.email,
                distributorId: _currentDistributor.distributorId,
              );
              await _productService.addProduct(product);
              await _loadData();
              if (mounted) {
                Navigator.pop(context);
                showSafeSnackBar(context, '✅ Product added successfully!', backgroundColor: successGreen);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
            child: const Text('Add Product'),
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
        title: const Row(
          children: [
            Icon(Icons.person_add, color: accentTeal),
            SizedBox(width: 8),
            const Text('Add New Salesman'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone * (10 digits)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
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
              if (nameController.text.isEmpty) {
                showSafeSnackBar(context, 'Please enter name', backgroundColor: errorRed);
                return;
              }
              if (emailController.text.isEmpty) {
                showSafeSnackBar(context, 'Please enter email', backgroundColor: errorRed);
                return;
              }
              if (phoneController.text.isEmpty) {
                showSafeSnackBar(context, 'Please enter phone number', backgroundColor: errorRed);
                return;
              }
              if (phoneController.text.length != 10) {
                showSafeSnackBar(context, 'Phone number must be exactly 10 digits', backgroundColor: errorRed);
                return;
              }
              
              setState(() => _isLoading = true);
              Navigator.pop(context);
              
              final defaultPassword = '${nameController.text.substring(0, 3).toLowerCase()}${phoneController.text.substring(6)}';
              
              final salesman = SalesmanModel(
                id: 'salesman_${DateTime.now().millisecondsSinceEpoch}',
                salesmanId: 'SM${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 13)}',
                name: nameController.text,
                email: emailController.text,
                phone: phoneController.text,
                distributorId: _currentDistributor.distributorId!,
                createdBy: _currentDistributor.email,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                areaAssigned: areaController.text,
                address: addressController.text,
                targetAmount: double.tryParse(targetController.text) ?? 0,
                joiningDate: DateTime.now(),
              );
              
              final salesmanMap = salesman.toMap();
              salesmanMap['password'] = defaultPassword;
              salesmanMap['permissions'] = {
                'canAddProduct': false,
                'canEditProduct': false,
                'canDeleteProduct': false,
                'canAddCustomer': false,
                'canEditCustomer': false,
                'canDeleteCustomer': false,
                'canViewOrders': true,
                'canCreateOrder': true,
                'canCollectPayment': true,
                'canEditOrder': true,
                'canDeleteOrder': true,
              };
              
              try {
                final response = await ApiService.addSalesman(salesmanMap);
                final newSalesman = SalesmanModel.fromMap(response, response['_id']?.toString() ?? salesman.id);
                setState(() {
                  _salesmen.add(newSalesman);
                  _isLoading = false;
                });
                if (mounted) {
                  showSafeSnackBar(
                    context, 
                    '✅ Salesman added!\nPassword: $defaultPassword',
                    backgroundColor: successGreen,
                  );
                  await _loadUsersUnderDistributor();
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  showSafeSnackBar(context, 'Error adding salesman: $e', backgroundColor: errorRed);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showPermissionsDialog(SalesmanModel salesman) {
    final permissions = Map<String, bool>.from({
      'canAddProduct': false,
      'canEditProduct': false,
      'canDeleteProduct': false,
      'canAddCustomer': false,
      'canEditCustomer': false,
      'canDeleteCustomer': false,
      'canViewOrders': true,
      'canCreateOrder': true,
      'canCollectPayment': true,
      'canEditOrder': true,
      'canDeleteOrder': true,
    });
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Permissions for ${salesman.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Product Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
                CheckboxListTile(
                  title: const Text('Add Product'),
                  value: permissions['canAddProduct'],
                  onChanged: (val) => setDialogState(() => permissions['canAddProduct'] = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Edit Product'),
                  value: permissions['canEditProduct'],
                  onChanged: (val) => setDialogState(() => permissions['canEditProduct'] = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Delete Product'),
                  value: permissions['canDeleteProduct'],
                  onChanged: (val) => setDialogState(() => permissions['canDeleteProduct'] = val ?? false),
                ),
                const Divider(),
                const Text('Customer Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
                CheckboxListTile(
                  title: const Text('Add Customer'),
                  value: permissions['canAddCustomer'],
                  onChanged: (val) => setDialogState(() => permissions['canAddCustomer'] = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Edit Customer'),
                  value: permissions['canEditCustomer'],
                  onChanged: (val) => setDialogState(() => permissions['canEditCustomer'] = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Delete Customer'),
                  value: permissions['canDeleteCustomer'],
                  onChanged: (val) => setDialogState(() => permissions['canDeleteCustomer'] = val ?? false),
                ),
                const Divider(),
                const Text('Order Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
                CheckboxListTile(
                  title: const Text('Edit Order'),
                  value: permissions['canEditOrder'],
                  onChanged: (val) => setDialogState(() => permissions['canEditOrder'] = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Delete Order'),
                  value: permissions['canDeleteOrder'],
                  onChanged: (val) => setDialogState(() => permissions['canDeleteOrder'] = val ?? false),
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
                try {
                  await ApiService.updateSalesmanPermissions(salesman.salesmanId, permissions);
                  if (mounted) {
                    Navigator.pop(context);
                    showSafeSnackBar(context, 'Permissions updated successfully!', backgroundColor: successGreen);
                  }
                } catch (e) {
                  if (mounted) {
                    showSafeSnackBar(context, 'Error updating permissions: $e', backgroundColor: errorRed);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
              child: const Text('Save Permissions'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCustomerDialog(CustomerModel customer) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone ?? '');
    final addressController = TextEditingController(text: customer.address ?? '');
    
    String? selectedArea = customer.area;
    String? selectedRoute = customer.route;
    List<String> availableRoutes = [];

    _loadAreas().then((_) {
      if (selectedArea != null) {
        ApiService.getSubAreas(area: selectedArea!).then((routes) {
          if (mounted) {
            setState(() {
              availableRoutes = routes;
            });
          }
        });
      }
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: primaryBlue),
              const SizedBox(width: 8),
              const Text('Edit Customer'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedArea,
                  decoration: const InputDecoration(
                    labelText: 'Area / City *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select Area')),
                    ..._availableAreas.map((area) => DropdownMenuItem(
                      value: area,
                      child: Text(area),
                    )),
                  ],
                  onChanged: (value) async {
                    setDialogState(() {
                      selectedArea = value;
                      selectedRoute = null;
                      availableRoutes = [];
                    });
                    if (value != null && value.isNotEmpty) {
                      final routes = await ApiService.getSubAreas(area: value);
                      setDialogState(() {
                        availableRoutes = routes;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRoute,
                  decoration: const InputDecoration(
                    labelText: 'Route / Sub-Area',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.route),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select Route (Optional)')),
                    ...availableRoutes.map((route) => DropdownMenuItem(
                      value: route,
                      child: Text(route),
                    )),
                  ],
                  onChanged: (value) => setDialogState(() => selectedRoute = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _deleteCustomer(customer);
                  },
                  icon: const Icon(Icons.delete, color: errorRed),
                  label: const Text('Delete', style: TextStyle(color: errorRed)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      showSafeSnackBar(context, 'Please enter customer name', backgroundColor: errorRed);
                      return;
                    }
                    if (phoneController.text.trim().isEmpty) {
                      showSafeSnackBar(context, 'Please enter phone number', backgroundColor: errorRed);
                      return;
                    }
                    if (phoneController.text.trim().length != 10) {
                      showSafeSnackBar(context, 'Phone number must be exactly 10 digits', backgroundColor: errorRed);
                      return;
                    }
                    if (selectedArea == null || selectedArea!.isEmpty) {
                      showSafeSnackBar(context, 'Please select area', backgroundColor: errorRed);
                      return;
                    }
                    
                    final updatedCustomer = CustomerModel(
                      id: customer.id,
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      area: selectedArea!,
                      route: selectedRoute,
                      address: addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
                      createdAt: customer.createdAt,
                      updatedAt: DateTime.now(),
                      customerId: customer.customerId,
                      createdBy: customer.createdBy,
                      distributorId: customer.distributorId,
                    );
                    
                    try {
                      await _customerService.updateCustomer(updatedCustomer);
                      await _loadData();
                      if (mounted) {
                        Navigator.pop(context);
                        showSafeSnackBar(context, '✅ Customer updated successfully!', backgroundColor: successGreen);
                      }
                    } catch (e) {
                      showSafeSnackBar(context, 'Error updating customer: $e', backgroundColor: errorRed);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
                  child: const Text('Update Customer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(ProductModel product) {
    final nameController = TextEditingController(text: product.name);
    final skuController = TextEditingController(text: product.sku);
    final mrpController = TextEditingController(text: product.mrp.toStringAsFixed(0));
    final priceController = TextEditingController(text: product.price.toStringAsFixed(0));
    final categoryController = TextEditingController(text: product.category);
    final stockController = TextEditingController(text: product.stock.toString());
    final descriptionController = TextEditingController(text: product.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: accentTeal),
            SizedBox(width: 8),
            Text('Edit Product'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mrpController,
                decoration: const InputDecoration(
                  labelText: 'MRP *',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Selling Price *',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteProduct(product);
                },
                icon: const Icon(Icons.delete, color: errorRed),
                label: const Text('Delete', style: TextStyle(color: errorRed)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    showSafeSnackBar(context, 'Please enter product name', backgroundColor: errorRed);
                    return;
                  }
                  if (skuController.text.trim().isEmpty) {
                    showSafeSnackBar(context, 'Please enter SKU', backgroundColor: errorRed);
                    return;
                  }
                  if (priceController.text.trim().isEmpty) {
                    showSafeSnackBar(context, 'Please enter selling price', backgroundColor: errorRed);
                    return;
                  }
                  if (categoryController.text.trim().isEmpty) {
                    showSafeSnackBar(context, 'Please enter category', backgroundColor: errorRed);
                    return;
                  }
                  
                  final updatedProduct = ProductModel(
                    id: product.id,
                    name: nameController.text.trim(),
                    sku: skuController.text.trim(),
                    price: double.tryParse(priceController.text) ?? 0,
                    mrp: double.tryParse(mrpController.text) ?? double.tryParse(priceController.text) ?? 0,
                    category: categoryController.text.trim(),
                    stock: int.tryParse(stockController.text) ?? 0,
                    description: descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : null,
                    createdAt: product.createdAt,
                    updatedAt: DateTime.now(),
                    createdBy: product.createdBy,
                    distributorId: product.distributorId,
                  );
                  
                  try {
                    await _productService.updateProduct(updatedProduct);
                    await _loadData();
                    if (mounted) {
                      Navigator.pop(context);
                      showSafeSnackBar(context, '✅ Product updated successfully!', backgroundColor: successGreen);
                    }
                  } catch (e) {
                    showSafeSnackBar(context, 'Error updating product: $e', backgroundColor: errorRed);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
                child: const Text('Update Product'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateStockDialog(ProductModel product) {
    final stockController = TextEditingController(text: product.stock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.inventory, color: accentTeal),
            const SizedBox(width: 8),
            Text('Update Stock: ${product.name}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Stock: ${product.stock}'),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(
                labelText: 'New Stock Quantity',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStock = int.tryParse(stockController.text);
              if (newStock == null || newStock < 0) {
                showSafeSnackBar(context, 'Please enter a valid stock quantity', backgroundColor: errorRed);
                return;
              }
              
              try {
                await _productService.updateProductStock(product.id, newStock);
                await _loadData();
                if (mounted) {
                  Navigator.pop(context);
                  showSafeSnackBar(context, '✅ Stock updated to $newStock!', backgroundColor: successGreen);
                }
              } catch (e) {
                showSafeSnackBar(context, 'Error updating stock: $e', backgroundColor: errorRed);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
            child: const Text('Update Stock'),
          ),
        ],
      ),
    );
  }

  void _showEditSalesmanDialog(SalesmanModel salesman) {
    final nameController = TextEditingController(text: salesman.name);
    final emailController = TextEditingController(text: salesman.email);
    final phoneController = TextEditingController(text: salesman.phone);
    final areaController = TextEditingController(text: salesman.areaAssigned);
    final addressController = TextEditingController(text: salesman.address);
    final targetController = TextEditingController(text: salesman.targetAmount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: accentTeal),
            SizedBox(width: 8),
            Text('Edit Salesman'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone * (10 digits)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteSalesman(salesman);
                },
                icon: const Icon(Icons.delete, color: errorRed),
                label: const Text('Deactivate', style: TextStyle(color: errorRed)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) {
                    showSafeSnackBar(context, 'Please enter name', backgroundColor: errorRed);
                    return;
                  }
                  if (emailController.text.isEmpty) {
                    showSafeSnackBar(context, 'Please enter email', backgroundColor: errorRed);
                    return;
                  }
                  if (phoneController.text.isEmpty) {
                    showSafeSnackBar(context, 'Please enter phone number', backgroundColor: errorRed);
                    return;
                  }
                  if (phoneController.text.length != 10) {
                    showSafeSnackBar(context, 'Phone number must be exactly 10 digits', backgroundColor: errorRed);
                    return;
                  }
                  
                  final updatedSalesman = SalesmanModel(
                    id: salesman.id,
                    salesmanId: salesman.salesmanId,
                    name: nameController.text,
                    email: emailController.text,
                    phone: phoneController.text,
                    distributorId: salesman.distributorId,
                    createdBy: salesman.createdBy,
                    createdAt: salesman.createdAt,
                    updatedAt: DateTime.now(),
                    status: salesman.status,
                    targetAmount: double.tryParse(targetController.text) ?? 0,
                    achievedAmount: salesman.achievedAmount,
                    commissionRate: salesman.commissionRate,
                    areaAssigned: areaController.text,
                    address: addressController.text,
                    joiningDate: salesman.joiningDate,
                    performanceMetrics: salesman.performanceMetrics,
                    bankDetails: salesman.bankDetails,
                    documents: salesman.documents,
                    notes: salesman.notes,
                  );
                  
                  try {
                    await _salesmanService.updateSalesman(updatedSalesman);
                    await _loadData();
                    if (mounted) {
                      Navigator.pop(context);
                      showSafeSnackBar(context, '✅ Salesman updated successfully!', backgroundColor: successGreen);
                      await _loadUsersUnderDistributor();
                    }
                  } catch (e) {
                    showSafeSnackBar(context, 'Error updating salesman: $e', backgroundColor: errorRed);
                  }
                },
                child: const Text('Update Salesman'),
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
                                Icons.history,
                                'Collection History',
                                12,
                              ),
                              _buildSidebarItem(
                                Icons.download,
                                'Download Order',
                                10,
                              ),
                              _buildSidebarItem(
                                Icons.upload_file,
                                'Import Master Data',
                                11,
                              ),
                              const Divider(height: 32),
                              _buildSidebarItem(
                                Icons.lock_reset,
                                'Change Password',
                                -2,
                              ),
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
        } else if (index == -2) {
          setState(() => _isSidebarOpen = false);
          _showChangePasswordDialog();
        } else if (index == 11) {
          setState(() => _isSidebarOpen = false);
          _showImportMasterDataDialog();
        } else if (index == 12) {
          setState(() => _isSidebarOpen = false);
          _showCollectionHistoryDialog();
        } else {
          setState(() {
            _selectedIndex = index;
            _isSidebarOpen = false;
          });
        }
      },
    );
  }

  Widget _buildDownloadOrderSection() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download, size: 80, color: primaryBlue),
            const SizedBox(height: 20),
            const Text(
              'Download Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Export your orders to Excel file',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Select Date Range',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDownloadButton(
                    'Today\'s Orders',
                    Icons.today,
                    () => _downloadOrders(filterType: 'today'),
                    primaryBlue,
                  ),
                  const SizedBox(height: 12),
                  _buildDownloadButton(
                    'Yesterday\'s Orders',
                    Icons.calendar_today,
                    () => _downloadOrders(filterType: 'yesterday'),
                    primaryBlue,
                  ),
                  const SizedBox(height: 12),
                  _buildDownloadButton(
                    'Last 7 Days',
                    Icons.date_range,
                    () => _downloadOrders(filterType: 'lastWeek'),
                    primaryBlue,
                  ),
                  const SizedBox(height: 12),
                  _buildDownloadButton(
                    'Custom Date Range',
                    Icons.calendar_month,
                    () async {
                      final DateTimeRange? range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: DateTimeRange(
                          start: DateTime.now().subtract(const Duration(days: 7)),
                          end: DateTime.now(),
                        ),
                      );
                      if (range != null && mounted) {
                        _downloadOrders(startDate: range.start, endDate: range.end);
                      }
                    },
                    accentTeal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isDownloading)
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(String title, IconData icon, VoidCallback onTap, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isDownloading ? null : onTap,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: primaryBlue),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditOrderDialog(order);
                        },
                        tooltip: 'Edit Order',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: errorRed),
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteOrder(order);
                        },
                        tooltip: 'Delete Order',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
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
                                  'MRP: ₹${item.mrp?.toStringAsFixed(0) ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                Text(
                                  'SKU: ${item.sku}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
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
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                    onPressed: _showNotificationsDialog,
                    tooltip: 'Alerts',
                  ),
                  if (_unreadNotificationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_unreadNotificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
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
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search products, customers, orders...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.white70),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _performGlobalSearch(value);
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_searchQuery.isNotEmpty && _searchQuery.trim().length >= 2)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isGlobalSearching
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_globalSearchProducts.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Products', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
                            ),
                            ..._globalSearchProducts.take(5).map((product) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.inventory_2, size: 18),
                              title: Text(product['productName'] ?? product['name'] ?? ''),
                              subtitle: Text('SKU: ${product['sku']} | ₹${product['price']} | MRP: ₹${product['mrp'] ?? product['price']}'),
                              onTap: () {
                                setState(() {
                                  _selectedIndex = 3;
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            )),
                            const Divider(),
                          ],
                          if (_globalSearchCustomers.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Customers', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
                            ),
                            ..._globalSearchCustomers.take(5).map((customer) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.person, size: 18),
                              title: Text(customer['name'] ?? ''),
                              subtitle: Text('Area: ${customer['area']}'),
                              onTap: () {
                                setState(() {
                                  _selectedIndex = 2;
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            )),
                            const Divider(),
                          ],
                          if (_globalSearchOrders.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Orders', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
                            ),
                            ..._globalSearchOrders.take(5).map((order) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.receipt, size: 18),
                              title: Text(order['orderNumber'] ?? ''),
                              subtitle: Text('Customer: ${order['customerName']} | ₹${order['grand_total']}'),
                              onTap: () {
                                setState(() {
                                  _selectedIndex = 5;
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            )),
                            const Divider(),
                          ],
                          if (_globalSearchProducts.isEmpty && _globalSearchCustomers.isEmpty && _globalSearchOrders.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: Text('No results found')),
                            ),
                        ],
                      ),
                    ),
            ),
        ],
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
      case 10:
        return _buildDownloadOrderSection();
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
                    _showAddCustomerDialog,
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
                    _showAddProductDialog,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionCard(
                    'Add Salesman',
                    Icons.person_add_alt,
                    cardPurple,
                    _showAddSalesmanDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Import Master Data',
                    Icons.upload_file,
                    primaryBlue,
                    _showImportMasterDataDialog,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionCard(
                    'Download Orders',
                    Icons.download,
                    successGreen,
                    _showDownloadOptionsDialog,
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
          child: Row(
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
              IconButton(
                icon: const Icon(Icons.person_add, color: accentTeal),
                tooltip: 'Add Customer',
                onPressed: _showAddCustomerDialog,
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
                      SizedBox(height: 10),
                      Text(
                        'Click "+" to get started',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    return FutureBuilder<double>(
                      future: getCustomerOutstanding(customer.id),
                      builder: (context, outstandingSnapshot) {
                        final outstanding = outstandingSnapshot.data ?? 0.0;
                        return _buildCustomerCard(customer, outstanding);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(
    CustomerModel customer,
    double outstanding,
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
            if (outstanding > 0)
              Text(
                'Outstanding: ₹${outstanding.toStringAsFixed(0)}',
                style: const TextStyle(color: errorRed, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditCustomerDialog(customer),
              color: primaryBlue,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: errorRed),
              onPressed: () => _deleteCustomer(customer),
              tooltip: 'Delete Customer',
            ),
            if (outstanding > 0)
              Container(
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
            else
              const Icon(Icons.check_circle, color: successGreen),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<OrderModel?>(
                  future: getLastOrderForCustomer(customer.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final lastOrder = snapshot.data!;
                      return Column(
                        children: [
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
                      );
                    }
                    return const SizedBox();
                  },
                ),
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
          child: Row(
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
              IconButton(
                icon: const Icon(Icons.add, color: accentTeal),
                tooltip: 'Add Product',
                onPressed: _showAddProductDialog,
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
                icon: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download),
                tooltip: 'Sync from Desktop',
                onPressed: _isSyncing ? null : _syncProductsFromDesktop,
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredProducts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        'No products yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Click "+" to get started',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(product);
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

  Widget _buildProductCard(ProductModel product) {
    bool _isExpanded = false;
    
    return StatefulBuilder(
      builder: (context, setCardState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            onExpansionChanged: (expanded) {
              setCardState(() {
                _isExpanded = expanded;
              });
            },
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
                Text('MRP: ₹${product.mrp.toStringAsFixed(0)} | Stock: ${product.stock}'),
                Text('Price: ₹${product.price.toStringAsFixed(0)} | Category: ${product.category}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product.stock < 10)
                  const Icon(Icons.warning, color: errorRed, size: 16),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: errorRed),
                  onPressed: () => _deleteProduct(product),
                  tooltip: 'Delete Product',
                ),
                Column(
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
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isExpanded)
                      FutureBuilder<Map<String, dynamic>?>(
                        future: getLastSaleForProduct(product.id),
                        builder: (context, snapshot) {
                          final lastSale = snapshot.data;
                          if (lastSale != null && lastSale['order'] != null) {
                            return Column(
                              children: [
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
                                            lastSale['customerName'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Order ID:'),
                                          Text(
                                            lastSale['orderNumber'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Qty Sold:'),
                                          Text(
                                            (lastSale['quantity'] ?? 0).toString(),
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
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      Text('Description: ${product.description}'),
                      const Divider(),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showEditProductDialog(product),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showUpdateStockDialog(product),
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
      },
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
          child: Row(
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
              IconButton(
                icon: const Icon(Icons.person_add, color: accentTeal),
                tooltip: 'Add Salesman',
                onPressed: _showAddSalesmanDialog,
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
                  '${filteredSalesmen.length} Salesmen',
                  style: const TextStyle(
                    color: accentTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                      SizedBox(height: 10),
                      Text(
                        'Click "+" to get started',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.security, color: primaryBlue, size: 20),
              onPressed: () => _showPermissionsDialog(salesman),
              tooltip: 'Set Permissions',
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: primaryBlue, size: 20),
              onPressed: () => _showEditSalesmanDialog(salesman),
              tooltip: 'Edit Salesman',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: errorRed),
              onPressed: () => _deleteSalesman(salesman),
              tooltip: 'Deactivate Salesman',
            ),
            Container(
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
          ],
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
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedOrderSalesmanId = salesman.id;
                          _selectedIndex = 5;
                        });
                      },
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

  void _showOrderFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Orders'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    hintText: 'Search by customer name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      _orderCustomerFilter = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _selectedOrderSalesmanId,
                  decoration: const InputDecoration(
                    labelText: 'Salesman',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: 'all',
                      child: Text('All Salesmen'),
                    ),
                    ..._salesmen.map((salesman) => DropdownMenuItem<String?>(
                      value: salesman.id,
                      child: Text(salesman.name),
                    )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedOrderSalesmanId = value == 'all' ? null : value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _orderStartDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _orderStartDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _orderStartDate != null
                                      ? '${_orderStartDate!.day}/${_orderStartDate!.month}/${_orderStartDate!.year}'
                                      : 'Start Date',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _orderEndDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _orderEndDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _orderEndDate != null
                                      ? '${_orderEndDate!.day}/${_orderEndDate!.month}/${_orderEndDate!.year}'
                                      : 'End Date',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _orderCustomerFilter = '';
                  _selectedOrderSalesmanId = null;
                  _orderStartDate = null;
                  _orderEndDate = null;
                });
              },
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyOrderFilters();
              },
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersSection() {
    final todayOrders = _orders.where((o) => 
      o.createdAt.day == DateTime.now().day &&
      o.createdAt.month == DateTime.now().month &&
      o.createdAt.year == DateTime.now().year
    ).toList();
    
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
                  IconButton(
                    icon: const Icon(Icons.download, color: primaryBlue),
                    onPressed: _isDownloading ? null : _showDownloadOptionsDialog,
                    tooltip: 'Download Orders',
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: primaryBlue),
                    onPressed: _showOrderFilterDialog,
                    tooltip: 'Filter Orders',
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
              const SizedBox(height: 8),
              if (todayOrders.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.today, color: accentTeal, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Today\'s Orders: ${todayOrders.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: accentTeal,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${todayOrders.fold<double>(0, (sum, o) => sum + o.totalAmount).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: accentTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
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
          if (_orderStep == 2) _buildProductSelectionStepWithScheme(),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Customer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              TextButton.icon(
                onPressed: _showAddCustomerDialog,
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add New Customer'),
              ),
            ],
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
              return FutureBuilder<double>(
                future: getCustomerOutstanding(customer.id),
                builder: (context, outstandingSnapshot) {
                  final outstanding = outstandingSnapshot.data ?? 0.0;
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
              );
            },
          ),
        ],
      ),
    );
  }

Widget _buildProductSelectionStepWithScheme() {
  final Map<String, TextEditingController> quantityControllers = {};
  final Map<String, TextEditingController> rateControllers = {};
  final Map<String, TextEditingController> schemeControllers = {};

  for (var product in filteredProducts) {
    if (_cart.containsKey(product.id)) {
      quantityControllers[product.id] =
          TextEditingController(text: _cart[product.id]!.quantity.toString());
      rateControllers[product.id] =
          TextEditingController(text: _cart[product.id]!.rate.toString());
      schemeControllers[product.id] =
          TextEditingController(text: _cart[product.id]!.schPer.toString());
    } else {
      quantityControllers[product.id] = TextEditingController(text: '');
      rateControllers[product.id] =
          TextEditingController(text: product.price.toString());
      schemeControllers[product.id] = TextEditingController(text: '0');
    }
  }

  return StatefulBuilder(
    builder: (context, setDialogState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// CART SUMMARY
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
                  'Total: ₹${cartTotal.toStringAsFixed(2)}',
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
          
          /// SEARCH
          TextField(
            controller: _productSearchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) => setState(() => _productSearchQuery = value),
          ),
          const SizedBox(height: 16),
          
          /// PRODUCT LIST
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                final inCart = _cart.containsKey(product.id);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: inCart ? accentTeal.withOpacity(0.1) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: inCart ? accentTeal : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// PRODUCT DETAILS (Now including Rate field)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'MRP: ₹${product.mrp} | Stock: ${product.stock}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('Rate: '),
                                    SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        controller: rateControllers[product.id],
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        ),
                                        onChanged: (value) {
                                          final rate = double.tryParse(value);
                                          if (rate != null && rate > 0 && inCart) {
                                            updateCartRate(product.id, rate);
                                          }
                                          setDialogState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          /// QUANTITY INPUT (MOVED HERE - in front of rate field)
                          SizedBox(
                            width: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Qty:',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: quantityControllers[product.id],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter qty',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  ),
                                  onChanged: (value) {
                                    setDialogState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      /// CART INFO
                      if (inCart && _cart[product.id]!.quantity > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Text(
                                'In cart: ${_cart[product.id]!.quantity} × ₹${_cart[product.id]!.rate}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: accentTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '= ₹${_cart[product.id]!.netAmt}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: accentTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          
          /// NAVIGATION
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _orderStep = 1;
                      _cart.clear();
                      _stockAlertShown.clear();
                      // Clear search controllers
                      _productSearchQuery = '';
                      _productSearchController.clear();
                    });
                  },
                  child: const Text('← Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Process all products with quantity entered
                    bool hasItems = false;
                    
                    for (var product in filteredProducts) {
                      final qtyText = quantityControllers[product.id]?.text ?? '';
                      final qty = int.tryParse(qtyText);
                      
                      if (qty != null && qty > 0) {
                        hasItems = true;
                        final rate = double.tryParse(rateControllers[product.id]?.text ?? product.price.toString()) ?? product.price;
                        
                        // Add or update item in cart
                        if (_cart.containsKey(product.id)) {
                          updateCartQuantity(product.id, qty);
                          updateCartRate(product.id, rate);
                        } else {
                          addToCart(product.id, product.name, product.sku, rate, product.stock);
                          updateCartQuantity(product.id, qty);
                          updateCartRate(product.id, rate);
                        }
                      }
                    }
                    
                    if (hasItems && _cart.isNotEmpty) {
                      setState(() => _orderStep = 3);
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Items added to cart successfully'),
                          backgroundColor: successGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else if (!hasItems) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter quantity for at least one product'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
                  child: const Text('Submit →'),
                ),
              ),
            ],
          ),
        ],
      );
    },
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
                  ChoiceChip(
                    label: const Text('Cheque'),
                    selected: _selectedPaymentMode == PaymentMode.cheque,
                    onSelected: (_) =>
                        setState(() => _selectedPaymentMode = PaymentMode.cheque),
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
                    '${uniqueProductCount} unique products',
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
              const SizedBox(height: 8),
              Text(
                'Total Quantity: ${cartItemCount}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                    return FutureBuilder<double>(
                      future: getCustomerOutstanding(order.customerId),
                      builder: (context, outstandingSnapshot) {
                        final customerOutstanding = outstandingSnapshot.data ?? 0.0;
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
                              const SizedBox(height: 8),
                              Text(
                                'Customer Outstanding Balance: ₹${customerOutstanding.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: errorRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _showEnhancedPaymentDialog(order, customerOutstanding),
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
                    );
                  },
                ),
        ),
      ],
    );
  }

  // FIXED: Enhanced payment dialog with proper cheque and UPI details
  void _showEnhancedPaymentDialog(OrderModel order, double customerOutstanding) {
    final paymentAmountController = TextEditingController(text: order.dueAmount.toStringAsFixed(0));
    PaymentMode selectedMode = PaymentMode.cash;
    String? selectedBank;
    String? selectedUpiApp;
    final chequeNumberController = TextEditingController();
    final chequeDateController = TextEditingController();
    final transactionNumberController = TextEditingController();
    final remarkController = TextEditingController();
    File? paymentPhoto;
    double balanceAfterPayment = order.dueAmount;
    
    Future<void> selectDate(BuildContext context, TextEditingController controller) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        controller.text = picked.toIso8601String().split('T')[0];
      }
    }

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
                const SizedBox(height: 8),
                Text(
                  'Customer Outstanding: ₹${customerOutstanding.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: errorRed,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: paymentAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount to Collect',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final amount = double.tryParse(value) ?? 0;
                    setDialogState(() {
                      balanceAfterPayment = order.dueAmount - amount;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Balance after payment: ₹${balanceAfterPayment.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: balanceAfterPayment <= 0 ? successGreen : warningOrange,
                    fontWeight: FontWeight.bold,
                  ),
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
                      onSelected: (_) => setDialogState(() => selectedMode = PaymentMode.cash),
                    ),
                    ChoiceChip(
                      label: const Text('UPI'),
                      selected: selectedMode == PaymentMode.upi,
                      onSelected: (_) => setDialogState(() => selectedMode = PaymentMode.upi),
                    ),
                    ChoiceChip(
                      label: const Text('Cheque'),
                      selected: selectedMode == PaymentMode.cheque,
                      onSelected: (_) => setDialogState(() => selectedMode = PaymentMode.cheque),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (selectedMode == PaymentMode.cheque) ...[
                  const Text(
                    'Cheque Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: chequeNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Cheque Number *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => selectDate(context, chequeDateController),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: chequeDateController,
                        decoration: const InputDecoration(
                          labelText: 'Cheque Date *',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedBank,
                    decoration: const InputDecoration(
                      labelText: 'Bank Name *',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select Bank')),
                      ..._banksList.map((bank) => DropdownMenuItem(
                        value: bank,
                        child: Text(bank),
                      )),
                    ],
                    onChanged: (value) => setDialogState(() => selectedBank = value),
                  ),
                ],
                if (selectedMode == PaymentMode.upi) ...[
                  const Text(
                    'UPI Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedUpiApp,
                    decoration: const InputDecoration(
                      labelText: 'UPI App *',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select UPI App')),
                      ..._upiTypesList.map((app) => DropdownMenuItem(
                        value: app,
                        child: Text(app),
                      )),
                    ],
                    onChanged: (value) => setDialogState(() => selectedUpiApp = value),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: transactionNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Number *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          paymentPhoto == null ? 'No photo selected' : 'Photo selected',
                          style: TextStyle(color: paymentPhoto == null ? Colors.grey : successGreen),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            setDialogState(() => paymentPhoto = File(image.path));
                          }
                        },
                        icon: const Icon(Icons.photo_camera, size: 16),
                        label: const Text('Add Photo'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: remarkController,
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
                final amount = double.tryParse(paymentAmountController.text);
                if (amount == null || amount <= 0) {
                  showSafeSnackBar(context, 'Please enter valid amount', backgroundColor: errorRed);
                  return;
                }
                
                if (amount > order.dueAmount) {
                  showSafeSnackBar(context, 'Amount cannot exceed due amount', backgroundColor: errorRed);
                  return;
                }
                
                if (selectedMode == PaymentMode.cheque) {
                  if (chequeNumberController.text.isEmpty) {
                    showSafeSnackBar(context, 'Please enter cheque number', backgroundColor: errorRed);
                    return;
                  }
                  if (chequeDateController.text.isEmpty) {
                    showSafeSnackBar(context, 'Please select cheque date', backgroundColor: errorRed);
                    return;
                  }
                  if (selectedBank == null) {
                    showSafeSnackBar(context, 'Please select bank name', backgroundColor: errorRed);
                    return;
                  }
                } else if (selectedMode == PaymentMode.upi) {
                  if (selectedUpiApp == null) {
                    showSafeSnackBar(context, 'Please select UPI app', backgroundColor: errorRed);
                    return;
                  }
                  if (transactionNumberController.text.isEmpty) {
                    showSafeSnackBar(context, 'Please enter transaction number', backgroundColor: errorRed);
                    return;
                  }
                }
                
                setState(() => _isLoading = true);
                Navigator.pop(context);
                
                try {
                  await _orderService.recordPayment(
                    order.id,
                    amount,
                    selectedMode,
                    collectedBy: _currentDistributor.email,
                    salesmanId: order.salesmanId,
                    chequeNumber: selectedMode == PaymentMode.cheque ? chequeNumberController.text : null,
                    chequeDate: selectedMode == PaymentMode.cheque ? chequeDateController.text : null,
                    bankName: selectedMode == PaymentMode.cheque ? selectedBank : null,
                    upiType: selectedMode == PaymentMode.upi ? selectedUpiApp : null,
                    transactionNumber: selectedMode == PaymentMode.upi ? transactionNumberController.text : null,
                    remark: remarkController.text.isNotEmpty ? remarkController.text : null,
                    paymentPhoto: paymentPhoto,
                  );
                  await _loadData();
                  if (mounted) {
                    showSafeSnackBar(context, 'Payment collected successfully! Outstanding balance updated.', backgroundColor: successGreen);
                  }
                } catch (e) {
                  if (mounted) {
                    showSafeSnackBar(context, 'Error collecting payment: $e', backgroundColor: errorRed);
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
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
  
  late UserModel _currentSalesman;

  List<CustomerModel> _customers = [];
  List<ProductModel> _products = [];
  List<OrderModel> _orders = [];
  Map<String, dynamic> _permissions = {};
  List<CollectionHistoryModel> _collectionHistory = [];

  final Map<String, CartItemData> _cart = {};

  int _orderStep = 1;
  String? _selectedCustomerId;
  PaymentMode _selectedPaymentMode = PaymentMode.credit;
  String _orderNotes = '';

  final TextEditingController _productSearchController = TextEditingController();
  String _productSearchQuery = '';
  
  // ==================== ADDED: Customer search controller for salesman create order ====================
  final TextEditingController _customerSearchController = TextEditingController();
  String _customerSearchQuery = '';
  
  List<String> _banksList = [];
  List<String> _upiTypesList = [];

  final OrderService _orderService = OrderService();
  final CollectionHistoryService _collectionHistoryService = CollectionHistoryService();
  final Map<String, Map<String, dynamic>> _lastSaleCache = {};
  
  final Set<String> _stockAlertShown = {};

  OrderModel? _orderToEdit;
  bool _isEditingOrder = false;
  final Map<String, CartItemData> _editCart = {};

  // ==================== ADDED: Filtered customers for salesman create order ====================
  List<CustomerModel> get orderFilteredCustomers {
    if (_customerSearchQuery.isEmpty) return _customers;
    final query = _customerSearchQuery.toLowerCase();
    return _customers.where((c) =>
      c.name.toLowerCase().contains(query) ||
      c.area.toLowerCase().contains(query) ||
      (c.phone?.toLowerCase().contains(query) ?? false) ||
      (c.mobile?.toLowerCase().contains(query) ?? false)
    ).toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.loggedInUser != null) {
      _currentSalesman = widget.loggedInUser!;
      _orderService.setSalesmanId(_currentSalesman.salesmanId ?? _currentSalesman.id);
      _collectionHistoryService.setSalesmanId(_currentSalesman.salesmanId ?? _currentSalesman.id);
    } else {
      _currentSalesman = UserModel(
        id: 'salesman_001',
        email: 'salesman@demo.com',
        name: 'John Salesman',
        phone: '+91 9876543211',
        role: UserRole.salesman,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        isActive: true,
        salesmanId: 'SM0001',
      );
      _orderService.setSalesmanId('SM0001');
      _collectionHistoryService.setSalesmanId('SM0001');
    }
    _loadData();
    _loadBankAndUpiLists();
    _loadCollectionHistory();
  }

  Future<void> _loadBankAndUpiLists() async {
    final banks = await ApiService.getBanks();
    final upiTypes = await ApiService.getUpiTypes();
    setState(() {
      _banksList = banks.cast<String>();
      _upiTypesList = upiTypes.cast<String>();
    });
  }

  Future<void> _loadCollectionHistory() async {
    try {
      await _collectionHistoryService.getCollectionHistory();
      setState(() {
        _collectionHistory = _collectionHistoryService.collections;
      });
    } catch (e) {
      print('Error loading collection history: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      if (_currentSalesman.salesmanId != null) {
        final data = await ApiService.getSalesmanData(_currentSalesman.salesmanId!);
        
        print('Salesman data loaded: ${data['customers']?.length ?? 0} customers, ${data['products']?.length ?? 0} products');
        
        setState(() {
          _customers = (data['customers'] as List?)?.map((c) {
            final id = c['_id']?.toString() ?? '';
            return CustomerModel.fromMap(c, id);
          }).toList() ?? [];
          
          _products = (data['products'] as List?)?.map((p) {
            final id = p['_id']?.toString() ?? '';
            return ProductModel.fromMap(p, id);
          }).toList() ?? [];
          
          print('Loaded ${_products.length} products for salesman');
          
          _orders = (data['orders'] as List?)?.map((o) {
            final id = o['_id']?.toString() ?? '';
            return OrderModel(
              id: id,
              orderNumber: o['orderNumber'] ?? '',
              customerId: o['customerId'] ?? '',
              customerName: o['customerName'] ?? '',
              customerPhone: o['customerPhone'] ?? '',
              areaName: o['areaName'] ?? '',
              routeName: o['routeName'] ?? '',
              salesmanId: o['salesman_id'] ?? o['salesmanId'] ?? '',
              salesmanName: o['salesmanName'] ?? '',
              items: (o['items'] as List?)?.map((item) => OrderItemModel(
                id: item['id'] ?? '',
                productId: item['productId'] ?? '',
                productName: item['productName'] ?? '',
                sku: item['sku'] ?? '',
                quantity: item['quantity'] ?? 0,
                rate: (item['rate'] ?? 0).toDouble(),
                amount: (item['amount'] ?? 0).toDouble(),
                mrp: (item['mrp'] ?? 0).toDouble(),
              )).toList() ?? [],
              totalAmount: (o['grand_total'] ?? o['totalAmount'] ?? 0).toDouble(),
              paidAmount: (o['paidAmount'] ?? 0).toDouble(),
              dueAmount: (o['dueAmount'] ?? 0).toDouble(),
              status: _parseOrderStatus(o['status'] ?? 'pending'),
              orderType: _parseOrderType(o['orderType'] ?? 'regular'),
              paymentMode: o['paymentMode'] != null ? _parsePaymentMode(o['paymentMode']) : null,
              scheduledDate: o['scheduledDate'] != null ? DateTime.tryParse(o['scheduledDate']) : null,
              notes: o['notes'],
              internalNotes: o['internalNotes'],
              createdAt: o['createdAt'] != null ? DateTime.parse(o['createdAt']) : DateTime.now(),
              timeline: [],
            );
          }).toList() ?? [];
          
          _collectionHistory = (data['collectionHistory'] as List?)?.map((c) {
            final id = c['_id']?.toString() ?? '';
            return CollectionHistoryModel.fromMap(c, id);
          }).toList() ?? [];
          
          _permissions = data['permissions'] ?? {
            'canAddProduct': false,
            'canEditProduct': false,
            'canDeleteProduct': false,
            'canAddCustomer': false,
            'canEditCustomer': false,
            'canDeleteCustomer': false,
            'canViewOrders': true,
            'canCreateOrder': true,
            'canCollectPayment': true,
            'canEditOrder': false,
            'canDeleteOrder': false,
          };
        });
      }
    } catch (e) {
      print('Error loading salesman data: $e');
      setState(() {
        _customers = [];
        _products = [];
        _orders = [];
        _permissions = {
          'canAddProduct': false,
          'canEditProduct': false,
          'canDeleteProduct': false,
          'canAddCustomer': false,
          'canEditCustomer': false,
          'canDeleteCustomer': false,
          'canViewOrders': true,
          'canCreateOrder': true,
          'canCollectPayment': true,
          'canEditOrder': false,
          'canDeleteOrder': false,
        };
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  OrderStatus _parseOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return OrderStatus.pending;
      case 'taken': return OrderStatus.taken;
      case 'dispatched': return OrderStatus.dispatched;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  OrderType _parseOrderType(String type) {
    switch (type.toLowerCase()) {
      case 'regular': return OrderType.regular;
      case 'urgent': return OrderType.urgent;
      default: return OrderType.regular;
    }
  }

  PaymentMode _parsePaymentMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash': return PaymentMode.cash;
      case 'upi': return PaymentMode.upi;
      case 'banktransfer': return PaymentMode.bankTransfer;
      case 'credit': return PaymentMode.credit;
      case 'partial': return PaymentMode.partial;
      case 'cheque': return PaymentMode.cheque;
      case 'chequewithcash': return PaymentMode.chequeWithCash;
      default: return PaymentMode.credit;
    }
  }

  bool get canEditOrder => _permissions['canEditOrder'] ?? false;
  bool get canDeleteOrder => _permissions['canDeleteOrder'] ?? false;

  Future<Map<String, dynamic>?> getLastSaleForProduct(String productId) async {
    if (_lastSaleCache.containsKey(productId)) {
      return _lastSaleCache[productId];
    }
    try {
      final response = await ApiService.getLastSaleForProduct(productId);
      if (response.isNotEmpty) {
        _lastSaleCache[productId] = response;
        return response;
      }
      return null;
    } catch (e) {
      print('Error fetching last sale: $e');
      return null;
    }
  }

  Future<OrderModel?> getLastOrderForCustomer(String customerId) async {
    try {
      final response = await ApiService.getLastOrderByCustomer(customerId);
      if (response.isNotEmpty && response['orderNumber'] != null) {
        return OrderModel(
          id: response['_id']?.toString() ?? '',
          orderNumber: response['orderNumber'] ?? '',
          customerId: response['customerId'] ?? '',
          customerName: response['customerName'] ?? '',
          customerPhone: response['customerPhone'] ?? '',
          areaName: response['areaName'] ?? '',
          routeName: response['routeName'] ?? '',
          salesmanId: response['salesman_id'] ?? '',
          salesmanName: response['salesmanName'] ?? '',
          items: (response['items'] as List?)?.map((item) => OrderItemModel(
            id: item['id'] ?? '',
            productId: item['productId'] ?? '',
            productName: item['productName'] ?? '',
            sku: item['sku'] ?? '',
            quantity: item['quantity'] ?? 0,
            rate: (item['rate'] ?? 0).toDouble(),
            amount: (item['amount'] ?? 0).toDouble(),
            mrp: (item['mrp'] ?? 0).toDouble(),
          )).toList() ?? [],
          totalAmount: (response['grand_total'] ?? 0).toDouble(),
          paidAmount: (response['paidAmount'] ?? 0).toDouble(),
          dueAmount: (response['dueAmount'] ?? 0).toDouble(),
          status: _parseOrderStatus(response['status'] ?? 'pending'),
          orderType: _parseOrderType(response['orderType'] ?? 'regular'),
          paymentMode: null,
          scheduledDate: null,
          notes: response['notes'],
          internalNotes: response['internalNotes'],
          createdAt: response['createdAt'] != null ? DateTime.parse(response['createdAt']) : DateTime.now(),
          timeline: [],
        );
      }
      return null;
    } catch (e) {
      print('Error fetching last order: $e');
      return null;
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.logout();
    } catch (e) {
      print('Logout API error (ignored): $e');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => ChangePasswordDialog(
        currentUser: _currentSalesman,
        isDistributor: false,
      ),
    );
  }

  void _showCollectionHistoryDialog() {
    _collectionHistoryService.setSalesmanId(_currentSalesman.salesmanId ?? _currentSalesman.id);
    showDialog(
      context: context,
      builder: (context) => CollectionHistoryDialog(
        collectionHistoryService: _collectionHistoryService,
        salesmen: [],
        isDistributor: false,
      ),
    );
  }

  double get cartTotal {
    double total = 0;
    for (var item in _cart.values) {
      total += item.netAmt;
    }
    return total;
  }

  int get cartItemCount => _cart.values.fold(0, (a, b) => a + b.quantity);
  
  int get uniqueProductCount => _cart.length;

  bool get canAddProduct => _permissions['canAddProduct'] ?? false;
  bool get canEditProduct => _permissions['canEditProduct'] ?? false;
  bool get canDeleteProduct => _permissions['canDeleteProduct'] ?? false;
  bool get canAddCustomer => _permissions['canAddCustomer'] ?? false;
  bool get canEditCustomer => _permissions['canEditCustomer'] ?? false;
  bool get canDeleteCustomer => _permissions['canDeleteCustomer'] ?? false;
  bool get canViewOrders => _permissions['canViewOrders'] ?? true;
  bool get canCreateOrder => _permissions['canCreateOrder'] ?? true;
  bool get canCollectPayment => _permissions['canCollectPayment'] ?? true;

  List<ProductModel> get filteredProducts {
    if (_productSearchQuery.isEmpty) return _products;
    final query = _productSearchQuery.toLowerCase();
    return _products.where((p) => 
      p.name.toLowerCase().contains(query) || 
      p.sku.toLowerCase().contains(query)
    ).toList();
  }

  void addToCart(String productId, String productName, String sku, double price, int stock) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!.quantity++;
        _cart[productId]!.calculate();
      } else {
        final product = _products.firstWhere((p) => p.id == productId);
        _cart[productId] = CartItemData(
          productId: productId,
          productName: productName,
          sku: sku,
          quantity: 1,
          rate: price,
          mrp: product.mrp,
          stock: stock,
          schEnabled: false,
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
      final product = _products.firstWhere((p) => p.id == productId);
      if (quantity > product.stock && !_stockAlertShown.contains(productId)) {
        _stockAlertShown.add(productId);
        // Warning completely removed - no snackbar shown
      }
      _cart[productId]!.quantity = quantity;
      _cart[productId]!.calculate();
    }
  });
}

  void updateCartRate(String productId, double rate) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!.rate = rate;
        _cart[productId]!.calculate();
      }
    });
  }

  void updateCartScheme(String productId, double schPer) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!.schPer = schPer;
        _cart[productId]!.calculate();
      }
    });
  }

  void toggleCartScheme(String productId) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!.schEnabled = !_cart[productId]!.schEnabled;
        _cart[productId]!.calculate();
      }
    });
  }

  void clearCart() {
    setState(() {
      _cart.clear();
      _stockAlertShown.clear();
      _selectedCustomerId = null;
      _orderStep = 1;
      _selectedPaymentMode = PaymentMode.credit;
      _orderNotes = '';
    });
  }

void _showEditOrderDialog(OrderModel order) {
  setState(() {
    _orderToEdit = order;
    _isEditingOrder = true;
    _editCart.clear();
    
    for (var item in order.items) {
      final product = _products.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => ProductModel(
          id: item.productId,
          name: item.productName,
          sku: item.sku,
          price: item.rate,
          mrp: item.rate,
          category: '',
          stock: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      _editCart[item.productId] = CartItemData(
        productId: item.productId,
        productName: item.productName,
        sku: item.sku,
        quantity: item.quantity,
        rate: item.rate,
        mrp: item.mrp ?? item.rate,
        stock: product.stock,
        schEnabled: false,
      );
      _editCart[item.productId]!.calculate();
    }
    
    _selectedCustomerId = order.customerId;
    _selectedPaymentMode = order.paymentMode ?? PaymentMode.credit;
    _orderNotes = order.notes ?? '';
  });
  
  _showEditOrderDialogInternal();
}

void _showEditOrderDialogInternal() {
  final TextEditingController _productSearchEditController = TextEditingController();
  String _productSearchEditQuery = '';
  Map<String, TextEditingController> _editQuantityControllers = {};
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        // Get filtered products for adding new items
        List<ProductModel> getEditFilteredProducts() {
          if (_productSearchEditQuery.isEmpty) return _products;
          final query = _productSearchEditQuery.toLowerCase();
          return _products.where((p) => 
            p.name.toLowerCase().contains(query) || 
            p.sku.toLowerCase().contains(query)
          ).toList();
        }
        
        // Initialize quantity controllers for edit cart items
        for (var entry in _editCart.entries) {
          if (!_editQuantityControllers.containsKey(entry.key)) {
            _editQuantityControllers[entry.key] = TextEditingController(
              text: entry.value.quantity.toString()
            );
          }
        }
        
        return AlertDialog(
          title: Text('Edit Order #${_orderToEdit?.orderNumber}'),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer: ${_orderToEdit?.customerName}'),
                      Text('Order Date: ${_orderToEdit?.createdAt.day}/${_orderToEdit?.createdAt.month}/${_orderToEdit?.createdAt.year}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('Payment Mode:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Credit'),
                      selected: _selectedPaymentMode == PaymentMode.credit,
                      onSelected: (_) => setDialogState(() => _selectedPaymentMode = PaymentMode.credit),
                    ),
                    ChoiceChip(
                      label: const Text('Cash'),
                      selected: _selectedPaymentMode == PaymentMode.cash,
                      onSelected: (_) => setDialogState(() => _selectedPaymentMode = PaymentMode.cash),
                    ),
                    ChoiceChip(
                      label: const Text('UPI'),
                      selected: _selectedPaymentMode == PaymentMode.upi,
                      onSelected: (_) => setDialogState(() => _selectedPaymentMode = PaymentMode.upi),
                    ),
                    ChoiceChip(
                      label: const Text('Cheque'),
                      selected: _selectedPaymentMode == PaymentMode.cheque,
                      onSelected: (_) => setDialogState(() => _selectedPaymentMode = PaymentMode.cheque),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search bar to add new products
                const Text('Add New Products:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _productSearchEditController,
                  decoration: InputDecoration(
                    hintText: 'Search products to add...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: _productSearchEditQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setDialogState(() {
                                _productSearchEditQuery = '';
                                _productSearchEditController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setDialogState(() {
                    _productSearchEditQuery = value;
                  }),
                ),
                
                // Available products list for adding
                if (_productSearchEditQuery.isNotEmpty)
                  Container(
                    height: 200,
                    margin: const EdgeInsets.only(top: 8),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: getEditFilteredProducts().length,
                      itemBuilder: (context, index) {
                        final product = getEditFilteredProducts()[index];
                        final isAlreadyInCart = _editCart.containsKey(product.id);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isAlreadyInCart ? Colors.grey[200] : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('SKU: ${product.sku} | Stock: ${product.stock}'),
                                    Text('MRP: ₹${product.mrp} | Price: ₹${product.price}'),
                                  ],
                                ),
                              ),
                              if (!isAlreadyInCart)
                                ElevatedButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      _editCart[product.id] = CartItemData(
                                        productId: product.id,
                                        productName: product.name,
                                        sku: product.sku,
                                        quantity: 1,
                                        rate: product.price,
                                        mrp: product.mrp,
                                        stock: product.stock,
                                        schEnabled: false,
                                      );
                                      _editCart[product.id]!.calculate();
                                      _editQuantityControllers[product.id] = TextEditingController(text: '1');
                                      _productSearchEditQuery = '';
                                      _productSearchEditController.clear();
                                    });
                                  },
                                  child: const Text('Add to Order'),
                                ),
                              if (isAlreadyInCart)
                                const Text('Already in order', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                
                const SizedBox(height: 16),
                const Text('Order Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _editCart.length,
                    itemBuilder: (context, index) {
                      final productId = _editCart.keys.elementAt(index);
                      final cartItem = _editCart[productId]!;
                      final product = _products.firstWhere(
                        (p) => p.id == productId,
                        orElse: () => ProductModel(
                          id: productId,
                          name: cartItem.productName,
                          sku: cartItem.sku,
                          price: cartItem.rate,
                          mrp: cartItem.mrp,
                          category: '',
                          stock: cartItem.stock,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(cartItem.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text('MRP: ₹${cartItem.mrp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text('Rate: ₹${cartItem.rate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                                    ],
                                  ),
                                ),
                                // Remove button
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () {
                                    setDialogState(() {
                                      _editCart.remove(productId);
                                      _editQuantityControllers.remove(productId);
                                    });
                                  },
                                  tooltip: 'Remove item',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 20),
                                      onPressed: () {
                                        final newQty = cartItem.quantity - 1;
                                        if (newQty <= 0) {
                                          setDialogState(() {
                                            _editCart.remove(productId);
                                            _editQuantityControllers.remove(productId);
                                          });
                                        } else {
                                          setDialogState(() {
                                            _editCart[productId]!.quantity = newQty;
                                            _editCart[productId]!.calculate();
                                            _editQuantityControllers[productId]?.text = newQty.toString();
                                          });
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      width: 50,
                                      child: TextField(
                                        controller: _editQuantityControllers[productId],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        onChanged: (value) {
                                          final qty = int.tryParse(value);
                                          if (qty != null && qty > 0) {
                                            setDialogState(() {
                                              _editCart[productId]!.quantity = qty;
                                              _editCart[productId]!.calculate();
                                            });
                                          } else if (qty == 0) {
                                            setDialogState(() {
                                              _editCart.remove(productId);
                                              _editQuantityControllers.remove(productId);
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 20),
                                      onPressed: () {
                                        if (cartItem.quantity < product.stock) {
                                          setDialogState(() {
                                            _editCart[productId]!.quantity++;
                                            _editCart[productId]!.calculate();
                                            _editQuantityControllers[productId]?.text = _editCart[productId]!.quantity.toString();
                                          });
                                        } else {
                                          showSafeSnackBar(context, 'Not enough stock', backgroundColor: warningOrange);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                Text('₹${cartItem.netAmt.toStringAsFixed(0)}', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            // Rate edit field
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Text('Rate: ₹', style: TextStyle(fontSize: 12)),
                                  SizedBox(
                                    width: 100,
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: cartItem.rate.toStringAsFixed(0)
                                      ),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      onChanged: (value) {
                                        final rate = double.tryParse(value);
                                        if (rate != null && rate > 0) {
                                          setDialogState(() {
                                            _editCart[productId]!.rate = rate;
                                            _editCart[productId]!.calculate();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
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
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('₹${_getEditCartTotal().toStringAsFixed(0)}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentTeal)),
                  ],
                ),
                
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: _orderNotes),
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (value) => _orderNotes = value,
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
                if (_editCart.isEmpty) {
                  showSafeSnackBar(context, 'Order must have at least one item', backgroundColor: warningOrange);
                  return;
                }
                await _submitEditOrder();
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    ),
  );
}
  double _getEditCartTotal() {
    double total = 0;
    for (var item in _editCart.values) {
      total += item.netAmt;
    }
    return total;
  }

  Future<void> _submitEditOrder() async {
    if (_orderToEdit == null || _editCart.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final customer = _customers.firstWhere((c) => c.id == _selectedCustomerId);
      
      final updatedOrder = OrderModel(
        id: _orderToEdit!.id,
        orderNumber: _orderToEdit!.orderNumber,
        customerId: _selectedCustomerId!,
        customerName: customer.name,
        customerPhone: customer.phone ?? customer.mobile ?? '',
        areaName: customer.area,
        routeName: customer.route ?? '',
        salesmanId: _orderToEdit!.salesmanId,
        salesmanName: _orderToEdit!.salesmanName,
        items: _editCart.entries.map((entry) {
          final item = entry.value;
          return OrderItemModel(
            id: 'item_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
            productId: item.productId,
            productName: item.productName,
            sku: item.sku,
            quantity: item.quantity,
            rate: item.rate,
            amount: item.netAmt,
            mrp: item.mrp,
          );
        }).toList(),
        totalAmount: _getEditCartTotal(),
        paidAmount: _orderToEdit!.paidAmount,
        dueAmount: _getEditCartTotal() - _orderToEdit!.paidAmount,
        status: _orderToEdit!.status,
        orderType: _orderToEdit!.orderType,
        paymentMode: _selectedPaymentMode,
        scheduledDate: _orderToEdit!.scheduledDate,
        notes: _orderNotes,
        internalNotes: _orderToEdit!.internalNotes,
        createdAt: _orderToEdit!.createdAt,
        timeline: _orderToEdit!.timeline,
      );
      
      await _orderService.editOrder(updatedOrder);
      await _loadData();
      
      if (mounted) {
        showSafeSnackBar(context, '✅ Order updated successfully!', backgroundColor: successGreen);
        setState(() {
          _orderToEdit = null;
          _isEditingOrder = false;
          _editCart.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error updating order: $e', backgroundColor: errorRed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text('Are you sure you want to delete order #${order.orderNumber}?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _orderService.deleteOrder(order.id);
      await _loadData();
      
      if (mounted) {
        showSafeSnackBar(context, '✅ Order deleted successfully!', backgroundColor: successGreen);
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error deleting order: $e', backgroundColor: errorRed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> submitOrder() async {
    if (_selectedCustomerId == null || _cart.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final customer = _customers.firstWhere((c) => c.id == _selectedCustomerId);

      final orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      
      final order = OrderModel(
        id: 'order_${DateTime.now().millisecondsSinceEpoch}',
        orderNumber: orderNumber,
        customerId: _selectedCustomerId!,
        customerName: customer.name,
        customerPhone: customer.phone ?? customer.mobile ?? '',
        areaName: customer.area,
        routeName: customer.route ?? '',
        salesmanId: _currentSalesman.salesmanId ?? _currentSalesman.id,
        salesmanName: _currentSalesman.name,
        items: _cart.entries.map((entry) {
          final item = entry.value;
          return OrderItemModel(
            id: 'item_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
            productId: item.productId,
            productName: item.productName,
            sku: item.sku,
            quantity: item.quantity,
            rate: item.rate,
            amount: item.netAmt,
            mrp: item.mrp,
          );
        }).toList(),
        totalAmount: cartTotal,
        paidAmount: _selectedPaymentMode == PaymentMode.cash || _selectedPaymentMode == PaymentMode.upi ? cartTotal : 0,
        dueAmount: _selectedPaymentMode == PaymentMode.credit ? cartTotal : 0,
        status: OrderStatus.pending,
        orderType: OrderType.regular,
        paymentMode: _selectedPaymentMode,
        scheduledDate: null,
        notes: _orderNotes,
        internalNotes: null,
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

      await _orderService.createOrder(order, _currentSalesman.distributorId, _currentSalesman.salesmanId ?? _currentSalesman.id);
      
      for (var entry in _cart.entries) {
        final productId = entry.key;
        final quantity = entry.value.quantity;
        await ApiService.updateProductStock(productId, quantity);
      }
      
      if (mounted) {
        showSafeSnackBar(context, '✅ Order submitted successfully! Order ID: ${order.orderNumber}', backgroundColor: successGreen);
        clearCart();
        await _loadData();
        
        setState(() {
          _selectedIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        showSafeSnackBar(context, 'Error submitting order: $e', backgroundColor: errorRed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddCustomerDialog() {
    if (!canAddCustomer) {
      showSafeSnackBar(context, 'You don\'t have permission to add customers', backgroundColor: errorRed);
      return;
    }
    
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final areaController = TextEditingController();
    final routeController = TextEditingController();
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
                  labelText: 'Customer Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number * (10 digits)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: areaController,
                decoration: const InputDecoration(
                  labelText: 'Area *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: routeController,
                decoration: const InputDecoration(
                  labelText: 'Route',
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
              if (nameController.text.trim().isEmpty) {
                showSafeSnackBar(context, 'Please enter customer name', backgroundColor: errorRed);
                return;
              }
              if (phoneController.text.trim().isEmpty) {
                showSafeSnackBar(context, 'Please enter phone number', backgroundColor: errorRed);
                return;
              }
              if (phoneController.text.trim().length != 10) {
                showSafeSnackBar(context, 'Phone number must be exactly 10 digits', backgroundColor: errorRed);
                return;
              }
              if (areaController.text.trim().isEmpty) {
                showSafeSnackBar(context, 'Please enter area', backgroundColor: errorRed);
                return;
              }
              
              final customer = CustomerModel(
                id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                area: areaController.text.trim(),
                route: routeController.text.trim().isNotEmpty ? routeController.text.trim() : null,
                address: addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                customerId: 'GK${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 13)}',
                createdBy: _currentSalesman.email,
                distributorId: _currentSalesman.distributorId,
              );
              
              try {
                await ApiService.addCustomer(customer.toMap());
                await _loadData();
                if (mounted) {
                  Navigator.pop(context);
                  showSafeSnackBar(context, '✅ Customer added successfully!', backgroundColor: successGreen);
                }
              } catch (e) {
                showSafeSnackBar(context, 'Error adding customer: $e', backgroundColor: errorRed);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
            child: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    if (!canAddProduct) {
      showSafeSnackBar(context, 'You don\'t have permission to add products', backgroundColor: errorRed);
      return;
    }
    
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final mrpController = TextEditingController();
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
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mrpController,
                decoration: const InputDecoration(
                  labelText: 'MRP *',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Selling Price *',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
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
              if (nameController.text.trim().isEmpty) {
                showSafeSnackBar(context, 'Please enter product name', backgroundColor: errorRed);
                return;
              }
              if (skuController.text.trim().isEmpty) {
                showSafeSnackBar(context, 'Please enter SKU', backgroundColor: errorRed);
                return;
              }
              if (priceController.text.trim().isEmpty) {
                showSafeSnackBar(context, 'Please enter selling price', backgroundColor: errorRed);
                return;
              }
              if (categoryController.text.trim().isEmpty) {
                showSafeSnackBar(context, 'Please enter category', backgroundColor: errorRed);
                return;
              }
              
              final product = ProductModel(
                id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                sku: skuController.text.trim(),
                price: double.tryParse(priceController.text) ?? 0,
                mrp: double.tryParse(mrpController.text) ?? double.tryParse(priceController.text) ?? 0,
                category: categoryController.text.trim(),
                stock: int.tryParse(stockController.text) ?? 0,
                description: null,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                createdBy: _currentSalesman.email,
                distributorId: _currentSalesman.distributorId,
              );
              
              try {
                await ApiService.addProduct(product.toMap());
                await _loadData();
                if (mounted) {
                  Navigator.pop(context);
                  showSafeSnackBar(context, '✅ Product added successfully!', backgroundColor: successGreen);
                }
              } catch (e) {
                showSafeSnackBar(context, 'Error adding product: $e', backgroundColor: errorRed);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
            child: const Text('Add Product'),
          ),
        ],
      ),
    );
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
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search products, customers...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.white70),
                    ),
                    onChanged: (value) => setState(() {}),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentSalesman.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Text(
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
                              if (canViewOrders)
                                _buildSidebarItem(
                                  Icons.receipt_long,
                                  'My Orders',
                                  1,
                                ),
                              if (canCreateOrder)
                                _buildSidebarItem(
                                  Icons.add_shopping_cart,
                                  'Create Order',
                                  2,
                                ),
                              if (canCollectPayment)
                                _buildSidebarItem(
                                  Icons.payment,
                                  'Collect Payment',
                                  3,
                                ),
                              _buildSidebarItem(
                                Icons.history,
                                'Collection History',
                                6,
                              ),
                              _buildSidebarItem(
                                Icons.inventory_2,
                                'Products',
                                4,
                              ),
                              _buildSidebarItem(
                                Icons.people,
                                'Customers',
                                5,
                              ),
                              const Divider(height: 32),
                              _buildSidebarItem(
                                Icons.lock_reset,
                                'Change Password',
                                -2,
                              ),
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
        } else if (index == -2) {
          setState(() => _isSidebarOpen = false);
          _showChangePasswordDialog();
        } else if (index == 6) {
          setState(() => _isSidebarOpen = false);
          _showCollectionHistoryDialog();
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
        return _buildOrdersSection();
      case 2:
        return _buildCreateOrderSection();
      case 3:
        return _buildPaymentsSection();
      case 4:
        return _buildProductsSection();
      case 5:
        return _buildCustomersSection();
      case 6:
        return _buildCollectionHistorySection();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final totalRevenue = _orders
        .where((o) => o.status == OrderStatus.delivered)
        .fold<double>(0, (sum, o) => sum + o.totalAmount);
    final totalCollection = _orders.fold<double>(0, (sum, o) => sum + o.paidAmount);
    final totalPending = _orders.fold<double>(0, (sum, o) => sum + o.dueAmount);
    final totalCollectedByMe = _collectionHistory.fold<double>(0, (sum, c) => sum + c.amountCollected);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
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
                    'Total Orders',
                    '${_orders.length}',
                    Icons.shopping_bag,
                    primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Total Sales',
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
                  child: _buildStatCard(
                    'My Collection',
                    '₹${(totalCollectedByMe / 1000).toStringAsFixed(1)}K',
                    Icons.account_balance_wallet,
                    accentTeal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Pending Dues',
                    '₹${(totalPending / 1000).toStringAsFixed(1)}K',
                    Icons.pending_actions,
                    warningOrange,
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
                if (canCreateOrder)
                  Expanded(
                    child: _buildActionCard(
                      'New Order',
                      Icons.add_shopping_cart,
                      Colors.orange,
                      () => setState(() => _selectedIndex = 2),
                    ),
                  ),
                if (canCollectPayment) ...[
                  if (canCreateOrder) const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionCard(
                      'Collect Payment',
                      Icons.payment,
                      successGreen,
                      () => setState(() => _selectedIndex = 3),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            _buildRecentOrders(),
          ],
        ),
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
            if (canViewOrders)
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
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
                  Text(
                    order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                  Row(
                    children: [
                      if (canEditOrder)
                        IconButton(
                          icon: const Icon(Icons.edit, color: primaryBlue),
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditOrderDialog(order);
                          },
                          tooltip: 'Edit Order',
                        ),
                      if (canDeleteOrder)
                        IconButton(
                          icon: const Icon(Icons.delete, color: errorRed),
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteOrder(order);
                          },
                          tooltip: 'Delete Order',
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
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
                                  'MRP: ₹${item.mrp?.toStringAsFixed(0) ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                Text(
                                  'SKU: ${item.sku}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return warningOrange;
      case OrderStatus.taken:
        return Colors.blue;
      case OrderStatus.dispatched:
        return Colors.purple;
      case OrderStatus.delivered:
        return successGreen;
      case OrderStatus.cancelled:
        return errorRed;
    }
  }

  Widget _buildOrdersSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: const Text(
            'My Orders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
        Expanded(
          child: _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('No orders yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(_orders[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
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
              if (canAddProduct)
                IconButton(
                  icon: const Icon(Icons.add, color: accentTeal),
                  tooltip: 'Add Product',
                  onPressed: _showAddProductDialog,
                ),
            ],
          ),
        ),
        Expanded(
          child: _products.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('No products available', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 10),
                      Text('Contact your distributor to add products', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return _buildProductCard(product);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    bool _isExpanded = false;
    
    return StatefulBuilder(
      builder: (context, setCardState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            onExpansionChanged: (expanded) {
              setCardState(() {
                _isExpanded = expanded;
              });
            },
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
                Text(
                  'MRP: ₹${product.mrp.toStringAsFixed(0)} | Stock: ${product.stock}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  'Price: ₹${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            trailing: canCreateOrder
                ? ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedIndex = 2);
                    },
                    child: const Text('Order'),
                  )
                : null,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isExpanded)
                      FutureBuilder<Map<String, dynamic>?>(
                        future: getLastSaleForProduct(product.id),
                        builder: (context, snapshot) {
                          final lastSale = snapshot.data;
                          if (lastSale != null && lastSale['order'] != null) {
                            return Column(
                              children: [
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
                                            lastSale['customerName'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Order ID:'),
                                          Text(
                                            lastSale['orderNumber'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Qty Sold:'),
                                          Text(
                                            (lastSale['quantity'] ?? 0).toString(),
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
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomersSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
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
              if (canAddCustomer)
                IconButton(
                  icon: const Icon(Icons.person_add, color: accentTeal),
                  tooltip: 'Add Customer',
                  onPressed: _showAddCustomerDialog,
                ),
            ],
          ),
        ),
        Expanded(
          child: _customers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('No customers available', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    final outstanding = _orders
                        .where((o) => o.customerId == customer.id && o.status != OrderStatus.cancelled)
                        .fold(0.0, (sum, o) => sum + o.dueAmount);
                    return FutureBuilder<OrderModel?>(
                      future: getLastOrderForCustomer(customer.id),
                      builder: (context, snapshot) {
                        final lastOrder = snapshot.data;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                          customer.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Area: ${customer.area}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          'Phone: ${customer.phone ?? "N/A"}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        if (outstanding > 0)
                                          Text(
                                            'Outstanding: ₹${outstanding.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: errorRed,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (canCreateOrder)
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedCustomerId = customer.id;
                                          _selectedIndex = 2;
                                        });
                                      },
                                      child: const Text('Order'),
                                    ),
                                ],
                              ),
                              if (lastOrder != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Last Order:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Order ID:', style: TextStyle(fontSize: 11)),
                                          Text(
                                            lastOrder.orderNumber,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Amount:', style: TextStyle(fontSize: 11)),
                                          Text(
                                            '₹${lastOrder.totalAmount.toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Date:', style: TextStyle(fontSize: 11)),
                                          Text(
                                            '${lastOrder.createdAt.day}/${lastOrder.createdAt.month}/${lastOrder.createdAt.year}',
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==================== MODIFIED: Customer selection step with search bar ====================
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Customer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              if (canAddCustomer)
                TextButton.icon(
                  onPressed: _showAddCustomerDialog,
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Add New Customer'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // ==================== ADDED: Search bar for customers ====================
          TextField(
            controller: _customerSearchController,
            decoration: InputDecoration(
              hintText: 'Search by name, area, or phone...',
              prefixIcon: const Icon(Icons.search, color: primaryBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _customerSearchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // Display search results count
          if (_customerSearchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Found ${orderFilteredCustomers.length} customer(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: orderFilteredCustomers.isEmpty ? errorRed : successGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          // ==================== MODIFIED: Use filtered customers list ====================
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orderFilteredCustomers.length,
            itemBuilder: (context, index) {
              final customer = orderFilteredCustomers[index];
              final isSelected = _selectedCustomerId == customer.id;
              final outstanding = _orders
                  .where((o) => o.customerId == customer.id && o.status != OrderStatus.cancelled)
                  .fold(0.0, (sum, o) => sum + o.dueAmount);
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
                            Text(
                              'Phone: ${customer.phone ?? "N/A"}',
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
          // Show message when no customers match search
          if (_customerSearchQuery.isNotEmpty && orderFilteredCustomers.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'No customers found matching your search.\nTry a different name or area.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
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
          if (_orderStep == 2) _buildProductSelectionStepWithScheme(),
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

Widget _buildProductSelectionStepWithScheme() {
  final Map<String, TextEditingController> quantityControllers = {};
  final Map<String, TextEditingController> rateControllers = {};
  final Map<String, TextEditingController> schemeControllers = {};
  final Map<String, Timer> debounceTimers = {};

  for (var product in filteredProducts) {
    if (_cart.containsKey(product.id)) {
      quantityControllers[product.id] =
          TextEditingController(text: _cart[product.id]!.quantity.toString());
      rateControllers[product.id] =
          TextEditingController(text: _cart[product.id]!.rate.toString());
      schemeControllers[product.id] =
          TextEditingController(text: _cart[product.id]!.schPer.toString());
    } else {
      quantityControllers[product.id] = TextEditingController(text: '');
      rateControllers[product.id] =
          TextEditingController(text: product.price.toString());
      schemeControllers[product.id] = TextEditingController(text: '0');
    }
  }

  return StatefulBuilder(
    builder: (context, setDialogState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// CART SUMMARY
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
                  'Total: ₹${cartTotal.toStringAsFixed(2)}',
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
          
          /// SEARCH
          TextField(
            controller: _productSearchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) => setState(() => _productSearchQuery = value),
          ),
          const SizedBox(height: 16),
          
          /// PRODUCT LIST
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                final inCart = _cart.containsKey(product.id);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: inCart ? accentTeal.withOpacity(0.1) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: inCart ? accentTeal : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// PRODUCT DETAILS (Now including Rate field)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'MRP: ₹${product.mrp} | Stock: ${product.stock}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('Rate: '),
                                    SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        controller: rateControllers[product.id],
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        ),
                                        onChanged: (value) {
                                          final rate = double.tryParse(value);
                                          if (rate != null && rate > 0 && inCart) {
                                            updateCartRate(product.id, rate);
                                          }
                                          setDialogState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          /// QUANTITY INPUT (MOVED HERE - in front of rate field)
                          SizedBox(
                            width: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Qty:',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: quantityControllers[product.id],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter qty',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  ),
                                  onChanged: (value) {
                                    // Cancel any existing timer for this product
                                    if (debounceTimers[product.id] != null) {
                                      debounceTimers[product.id]!.cancel();
                                    }
                                    
                                    // Set a new timer that will execute after 500ms of no typing
                                    debounceTimers[product.id] = Timer(const Duration(milliseconds: 500), () {
                                      final qty = int.tryParse(value);
                                      
                                      if (qty != null && qty > 0) {
                                        final rate = double.tryParse(rateControllers[product.id]?.text ?? product.price.toString()) ?? product.price;
                                        
                                        // Add or update item in cart automatically
                                        if (_cart.containsKey(product.id)) {
                                          updateCartQuantity(product.id, qty);
                                          updateCartRate(product.id, rate);
                                        } else {
                                          addToCart(product.id, product.name, product.sku, rate, product.stock);
                                          updateCartQuantity(product.id, qty);
                                          updateCartRate(product.id, rate);
                                        }
                                        
                                        setDialogState(() {});
                                      } else if (qty == 0 && _cart.containsKey(product.id)) {
                                        // Remove item if quantity is set to 0
                                        removeFromCart(product.id);
                                        quantityControllers[product.id]?.text = '';
                                        setDialogState(() {});
                                      } else if ((qty == null || qty <= 0) && value.isNotEmpty && !_cart.containsKey(product.id)) {
                                        // Clear invalid input if not in cart
                                        quantityControllers[product.id]?.text = '';
                                        setDialogState(() {});
                                      } else if ((qty == null || qty <= 0) && value.isEmpty && _cart.containsKey(product.id)) {
                                        // Remove from cart if quantity field is cleared
                                        removeFromCart(product.id);
                                        quantityControllers[product.id]?.text = '';
                                        setDialogState(() {});
                                      }
                                    });
                                    
                                    setDialogState(() {});
                                  },
                                  onEditingComplete: () {
                                    // Cancel any pending timer
                                    if (debounceTimers[product.id] != null) {
                                      debounceTimers[product.id]!.cancel();
                                    }
                                    
                                    final qtyText = quantityControllers[product.id]?.text ?? '';
                                    final qty = int.tryParse(qtyText);
                                    
                                    if (qty != null && qty > 0) {
                                      final rate = double.tryParse(rateControllers[product.id]?.text ?? product.price.toString()) ?? product.price;
                                      
                                      if (_cart.containsKey(product.id)) {
                                        updateCartQuantity(product.id, qty);
                                        updateCartRate(product.id, rate);
                                      } else {
                                        addToCart(product.id, product.name, product.sku, rate, product.stock);
                                        updateCartQuantity(product.id, qty);
                                        updateCartRate(product.id, rate);
                                      }
                                    } else if (qty == 0 && _cart.containsKey(product.id)) {
                                      removeFromCart(product.id);
                                      quantityControllers[product.id]?.text = '';
                                    } else if ((qty == null || qty <= 0) && quantityControllers[product.id]?.text?.isNotEmpty == true) {
                                      quantityControllers[product.id]?.text = '';
                                      if (_cart.containsKey(product.id)) {
                                        removeFromCart(product.id);
                                      }
                                    }
                                    
                                    // Remove focus from the field
                                    FocusScope.of(context).unfocus();
                                    setDialogState(() {});
                                  },
                                  onTapOutside: (event) {
                                    // Cancel any pending timer
                                    if (debounceTimers[product.id] != null) {
                                      debounceTimers[product.id]!.cancel();
                                    }
                                    
                                    final qtyText = quantityControllers[product.id]?.text ?? '';
                                    final qty = int.tryParse(qtyText);
                                    
                                    if (qty != null && qty > 0) {
                                      final rate = double.tryParse(rateControllers[product.id]?.text ?? product.price.toString()) ?? product.price;
                                      
                                      if (_cart.containsKey(product.id)) {
                                        updateCartQuantity(product.id, qty);
                                        updateCartRate(product.id, rate);
                                      } else {
                                        addToCart(product.id, product.name, product.sku, rate, product.stock);
                                        updateCartQuantity(product.id, qty);
                                        updateCartRate(product.id, rate);
                                      }
                                    } else if (qty == 0 && _cart.containsKey(product.id)) {
                                      removeFromCart(product.id);
                                      quantityControllers[product.id]?.text = '';
                                    } else if ((qty == null || qty <= 0) && quantityControllers[product.id]?.text?.isNotEmpty == true) {
                                      quantityControllers[product.id]?.text = '';
                                      if (_cart.containsKey(product.id)) {
                                        removeFromCart(product.id);
                                      }
                                    }
                                    
                                    setDialogState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      /// CART INFO (Removed stock warning message)
                      if (inCart && _cart[product.id]!.quantity > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Text(
                                'In cart: ${_cart[product.id]!.quantity} × ₹${_cart[product.id]!.rate}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: accentTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '= ₹${_cart[product.id]!.netAmt}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: accentTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          
          /// NAVIGATION
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _orderStep = 1;
                      _cart.clear();
                      _stockAlertShown.clear();
                      // Clear search controllers
                      _productSearchQuery = '';
                      _productSearchController.clear();
                    });
                  },
                  child: const Text('← Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_cart.isNotEmpty) {
                      setState(() => _orderStep = 3);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Proceeding to next step'),
                          backgroundColor: successGreen,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please add at least one item to cart'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
                  child: const Text('Next →'),
                ),
              ),
            ],
          ),
        ],
      );
    },
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
                  ChoiceChip(
                    label: const Text('Cheque'),
                    selected: _selectedPaymentMode == PaymentMode.cheque,
                    onSelected: (_) =>
                        setState(() => _selectedPaymentMode = PaymentMode.cheque),
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
                    '${uniqueProductCount} unique products',
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
              const SizedBox(height: 8),
              Text(
                'Total Quantity: ${cartItemCount}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildPaymentsSection() {
    final ordersWithDue = _orders
        .where((o) => o.dueAmount > 0 && o.status != OrderStatus.cancelled)
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: const Text(
            'Collect Payment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
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
                    final customerOutstanding = _orders
                        .where((o) => o.customerId == order.customerId && o.status != OrderStatus.cancelled)
                        .fold(0.0, (sum, o) => sum + o.dueAmount);
                    final paymentAmountController = TextEditingController();
                    paymentAmountController.text = order.dueAmount.toStringAsFixed(0);
                    
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
                          const SizedBox(height: 8),
                          Text(
                            'Customer Outstanding: ₹${customerOutstanding.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: errorRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showEnhancedPaymentDialogForSalesman(order, paymentAmountController, customerOutstanding),
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

  // FIXED: Enhanced payment dialog for salesman with proper cheque and UPI details
  void _showEnhancedPaymentDialogForSalesman(OrderModel order, TextEditingController paymentAmountController, double customerOutstanding) {
    PaymentMode selectedMode = PaymentMode.cash;
    String? selectedBank;
    String? selectedUpiApp;
    final chequeNumberController = TextEditingController();
    final chequeDateController = TextEditingController();
    final transactionNumberController = TextEditingController();
    final remarkController = TextEditingController();
    File? paymentPhoto;
    double balanceAfterPayment = order.dueAmount;
    
    Future<void> selectDate(BuildContext context, TextEditingController controller) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        controller.text = picked.toIso8601String().split('T')[0];
      }
    }

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
                const SizedBox(height: 8),
                Text(
                  'Customer Outstanding: ₹${customerOutstanding.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: errorRed,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: paymentAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount to Collect',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final amount = double.tryParse(value) ?? 0;
                    setDialogState(() {
                      balanceAfterPayment = order.dueAmount - amount;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Balance after payment: ₹${balanceAfterPayment.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: balanceAfterPayment <= 0 ? successGreen : warningOrange,
                    fontWeight: FontWeight.bold,
                  ),
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
                      onSelected: (_) => setDialogState(() => selectedMode = PaymentMode.cash),
                    ),
                    ChoiceChip(
                      label: const Text('UPI'),
                      selected: selectedMode == PaymentMode.upi,
                      onSelected: (_) => setDialogState(() => selectedMode = PaymentMode.upi),
                    ),
                    ChoiceChip(
                      label: const Text('Cheque'),
                      selected: selectedMode == PaymentMode.cheque,
                      onSelected: (_) => setDialogState(() => selectedMode = PaymentMode.cheque),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (selectedMode == PaymentMode.cheque) ...[
                  const Text(
                    'Cheque Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: chequeNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Cheque Number *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => selectDate(context, chequeDateController),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: chequeDateController,
                        decoration: const InputDecoration(
                          labelText: 'Cheque Date *',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedBank,
                    decoration: const InputDecoration(
                      labelText: 'Bank Name *',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select Bank')),
                      ..._banksList.map((bank) => DropdownMenuItem(
                        value: bank,
                        child: Text(bank),
                      )),
                    ],
                    onChanged: (value) => setDialogState(() => selectedBank = value),
                  ),
                ],
                if (selectedMode == PaymentMode.upi) ...[
                  const Text(
                    'UPI Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedUpiApp,
                    decoration: const InputDecoration(
                      labelText: 'UPI App *',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select UPI App')),
                      ..._upiTypesList.map((app) => DropdownMenuItem(
                        value: app,
                        child: Text(app),
                      )),
                    ],
                    onChanged: (value) => setDialogState(() => selectedUpiApp = value),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: transactionNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Number *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          paymentPhoto == null ? 'No photo selected' : 'Photo selected',
                          style: TextStyle(color: paymentPhoto == null ? Colors.grey : successGreen),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            setDialogState(() => paymentPhoto = File(image.path));
                          }
                        },
                        icon: const Icon(Icons.photo_camera, size: 16),
                        label: const Text('Add Photo'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: remarkController,
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
                final amount = double.tryParse(paymentAmountController.text);
                if (amount == null || amount <= 0) {
                  showSafeSnackBar(context, 'Please enter valid amount', backgroundColor: errorRed);
                  return;
                }
                
                if (amount > order.dueAmount) {
                  showSafeSnackBar(context, 'Amount cannot exceed due amount', backgroundColor: errorRed);
                  return;
                }
                
                if (selectedMode == PaymentMode.cheque) {
                  if (chequeNumberController.text.isEmpty) {
                    showSafeSnackBar(context, 'Please enter cheque number', backgroundColor: errorRed);
                    return;
                  }
                  if (chequeDateController.text.isEmpty) {
                    showSafeSnackBar(context, 'Please select cheque date', backgroundColor: errorRed);
                    return;
                  }
                  if (selectedBank == null) {
                    showSafeSnackBar(context, 'Please select bank name', backgroundColor: errorRed);
                    return;
                  }
                } else if (selectedMode == PaymentMode.upi) {
                  if (selectedUpiApp == null) {
                    showSafeSnackBar(context, 'Please select UPI app', backgroundColor: errorRed);
                    return;
                  }
                  if (transactionNumberController.text.isEmpty) {
                    showSafeSnackBar(context, 'Please enter transaction number', backgroundColor: errorRed);
                    return;
                  }
                }
                
                setState(() => _isLoading = true);
                Navigator.pop(context);
                
                try {
                  await _orderService.recordPayment(
                    order.id,
                    amount,
                    selectedMode,
                    collectedBy: _currentSalesman.email,
                    salesmanId: _currentSalesman.salesmanId ?? _currentSalesman.id,
                    chequeNumber: selectedMode == PaymentMode.cheque ? chequeNumberController.text : null,
                    chequeDate: selectedMode == PaymentMode.cheque ? chequeDateController.text : null,
                    bankName: selectedMode == PaymentMode.cheque ? selectedBank : null,
                    upiType: selectedMode == PaymentMode.upi ? selectedUpiApp : null,
                    transactionNumber: selectedMode == PaymentMode.upi ? transactionNumberController.text : null,
                    remark: remarkController.text.isNotEmpty ? remarkController.text : null,
                    paymentPhoto: paymentPhoto,
                  );
                  await _loadData();
                  await _loadCollectionHistory();
                  if (mounted) {
                    showSafeSnackBar(context, 'Payment collected successfully!', backgroundColor: successGreen);
                  }
                } catch (e) {
                  if (mounted) {
                    showSafeSnackBar(context, 'Error collecting payment: $e', backgroundColor: errorRed);
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('Collect'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionHistorySection() {
    final totalCollected = _collectionHistory.fold<double>(0, (sum, c) => sum + c.amountCollected);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'My Collection History',
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
                  'Total: ₹${totalCollected.toStringAsFixed(0)}',
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
          child: _collectionHistory.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        'No collection records yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _collectionHistory.length,
                  itemBuilder: (context, index) {
                    final collection = _collectionHistory[index];
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
                                collection.billNo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  collection.paymentMode,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                collection.customerName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Date: ${collection.collectionDate.day}/${collection.collectionDate.month}/${collection.collectionDate.year}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order Amount: ₹${collection.orderAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                'Collected: ₹${collection.amountCollected.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: successGreen,
                                ),
                              ),
                            ],
                          ),
                          if (collection.chequeNumber != null && collection.chequeNumber!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Cheque: ${collection.chequeNumber} (${collection.bankName ?? ''})',
                                style: const TextStyle(fontSize: 10, color: Colors.orange),
                              ),
                            ),
                          if (collection.transactionNumber != null && collection.transactionNumber!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'UPI Transaction: ${collection.transactionNumber} (${collection.upiType ?? ''})',
                                style: const TextStyle(fontSize: 10, color: Colors.purple),
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
                      setState(() => _selectedIndex = 2);
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

  static const String _remoteBaseUrl = 'https://totalmobileapp.onrender.com/api';
  
  static String get apiUrl {
    return _remoteBaseUrl;
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

  bool _isValidName(String name) {
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    return nameRegex.hasMatch(name);
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
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_email', userData['email'] ?? '');
          await prefs.setString('user_role', backendRoleStr);
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('user_json', json.encode(userData));
          
          final user = UserModel.fromMap(userData, userData['_id'] ?? userData['id'] ?? '');
          
          if (mounted) {
            setState(() {
              _successMessage = data['message'] ?? 'Login successful!';
            });
          }

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
    final name = _regNameController.text.trim();

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

    if (!_isValidName(name)) {
      setState(() {
        _errorMessage = 'Name should contain only alphabets and spaces';
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
        'fullName': name,
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
            child: kIsWeb
                ? Image.network(
                    'https://totalmobileapp.onrender.com/isset/image/TotalSolution.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.white,
                      child: const Icon(Icons.business, size: 80, color: primaryBlue),
                    ),
                  )
                : Image.asset(
                    'assets/images/TotalSolution.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.white,
                      child: const Icon(Icons.business, size: 80, color: primaryBlue),
                    ),
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
                if (!_isValidName(value)) {
                  return 'Name should contain only alphabets and spaces';
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