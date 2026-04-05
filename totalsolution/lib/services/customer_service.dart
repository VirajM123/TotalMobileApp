import 'package:flutter/material.dart';
import '../models/models.dart';

// Mock Customer Service - Works without Firebase for immediate testing
class CustomerService extends ChangeNotifier {
  List<CustomerModel> _customers = [];
  bool _isLoading = false;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;

  CustomerService() {
    _loadMockCustomers();
  }

  void _loadMockCustomers() {
    _customers = [
      CustomerModel(
        id: 'cust_001',
        name: 'Mohan Stores',
        phone: '+91 9876543210',
        mobile: '+91 9876543210',
        address: '123 Main Market, Shop No. 5',
        area: 'North Sector A',
        route: 'Route 1',
        salesmanId: 'salesman_001',
        company: 'Total Solution',
        outstanding: 12450.0,
        lastVisit: '24 Oct',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now(),
      ),
      CustomerModel(
        id: 'cust_002',
        name: 'Sharma Supermarket',
        phone: '+91 9876543211',
        mobile: '+91 9876543211',
        address: '456 Shopping Complex, Block B',
        area: 'South Sector B',
        route: 'Route 2',
        salesmanId: 'salesman_001',
        company: 'Total Solution',
        outstanding: 8500.0,
        lastVisit: '22 Oct',
        createdAt: DateTime.now().subtract(const Duration(days: 55)),
        updatedAt: DateTime.now(),
      ),
      CustomerModel(
        id: 'cust_003',
        name: 'Gupta General Store',
        phone: '+91 9876543212',
        mobile: '+91 9876543212',
        address: '789 Local Market',
        area: 'East Sector C',
        route: 'Route 3',
        salesmanId: 'salesman_001',
        company: 'Total Solution',
        outstanding: 0.0,
        lastVisit: '20 Oct',
        createdAt: DateTime.now().subtract(const Duration(days: 50)),
        updatedAt: DateTime.now(),
      ),
      CustomerModel(
        id: 'cust_004',
        name: 'Patel Provisions',
        phone: '+91 9876543213',
        mobile: '+91 9876543213',
        address: '321 Corner Shop',
        area: 'West Sector D',
        route: 'Route 4',
        salesmanId: 'salesman_001',
        company: 'Total Solution',
        outstanding: 3200.0,
        lastVisit: '19 Oct',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now(),
      ),
      CustomerModel(
        id: 'cust_005',
        name: 'Singh Kirana Shop',
        phone: '+91 9876543214',
        mobile: '+91 9876543214',
        address: '567 Market Road',
        area: 'Central Sector E',
        route: 'Route 1',
        salesmanId: 'salesman_001',
        company: 'Total Solution',
        outstanding: 5600.0,
        lastVisit: '25 Oct',
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  Future<List<CustomerModel>> getCustomers() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    _isLoading = false;
    notifyListeners();
    return _customers;
  }

  Future<CustomerModel?> getCustomerById(String id) async {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<CustomerModel>> getCustomersBySalesman(String salesmanId) async {
    return _customers.where((c) => c.salesmanId == salesmanId).toList();
  }

  Future<void> addCustomer(CustomerModel customer) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    _customers.add(customer);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    _customers.removeWhere((c) => c.id == id);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> syncCustomers(List<CustomerModel> customers) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    // Idempotent sync: update if exists, add if not
    for (final customer in customers) {
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
      } else {
        _customers.add(customer);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  List<CustomerModel> searchCustomers(String query) {
    if (query.isEmpty) return _customers;

    final lowerQuery = query.toLowerCase();
    return _customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(lowerQuery) ||
              c.area.toLowerCase().contains(lowerQuery) ||
              (c.phone?.contains(lowerQuery) ?? false) ||
              (c.mobile?.contains(lowerQuery) ?? false),
        )
        .toList();
  }

  int get totalCustomers => _customers.length;

  double get totalOutstanding =>
      _customers.fold(0.0, (sum, c) => sum + c.outstanding);
}
