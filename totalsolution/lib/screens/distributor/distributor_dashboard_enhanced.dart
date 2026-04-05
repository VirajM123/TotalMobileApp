import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../auth/login_screen.dart';

// Enhanced Distributor Dashboard with All Modern Features
class DistributorDashboardEnhanced extends StatefulWidget {
  const DistributorDashboardEnhanced({super.key});

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

  // Current distributor
  final UserModel _currentDistributor = UserModel(
    id: 'dist_001',
    email: 'distributor@demo.com',
    name: 'Admin Distributor',
    phone: '+91 9876543210',
    role: UserRole.distributor,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    isActive: true,
  );

  // Data
  List<CustomerModel> _customers = [];
  List<ProductModel> _products = [];
  List<OrderModel> _orders = [];
  List<UserModel> _salesmen = [];
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
  String _searchType = 'All'; // 'All', 'Customer', 'Product', 'Order'
  final TextEditingController _orderSearchController = TextEditingController();
  String _orderSearchQuery = '';

  // Order filter by salesman
  String? _selectedOrderSalesmanId; // null means 'All Salesmen'

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
  List<UserModel> get filteredSalesmen {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one order to post'),
          backgroundColor: warningOrange,
        ),
      );
      return;
    }

    setState(() => _isPostingToDesktop = true);

    try {
      // Get selected orders
      final selectedOrders = _orders
          .where((o) => _selectedOrderIds.contains(o.id))
          .toList();

      // Show confirmation dialog
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
        // Here you would integrate with your desktop API
        // For now, we'll simulate a successful post
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Successfully posted ${selectedOrders.length} order(s) to desktop!',
              ),
              backgroundColor: successGreen,
            ),
          );

          // Clear selections
          setState(() {
            _selectedOrderIds.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting orders: $e'),
            backgroundColor: errorRed,
          ),
        );
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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load mock salesmen
    _salesmen = [
      UserModel(
        id: 'salesman_001',
        email: 'john@demo.com',
        name: 'John Salesman',
        phone: '+91 9876543211',
        role: UserRole.salesman,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        isActive: true,
      ),
      UserModel(
        id: 'salesman_002',
        email: 'raj@demo.com',
        name: 'Raj Sharma',
        phone: '+91 9876543212',
        role: UserRole.salesman,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        isActive: true,
      ),
      UserModel(
        id: 'salesman_003',
        email: 'amit@demo.com',
        name: 'Amit Patel',
        phone: '+91 9876543213',
        role: UserRole.salesman,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        isActive: false,
      ),
    ];

    final results = await Future.wait([
      _customerService.getCustomers(),
      _productService.getProducts(),
      _orderService.getOrders(),
    ]);

    setState(() {
      _customers = results[0] as List<CustomerModel>;
      _products = results[1] as List<ProductModel>;
      _orders = results[2] as List<OrderModel>;
      _draftOrders = _orderService.getDraftOrders();
      _isLoading = false;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Order submitted successfully!'),
          backgroundColor: successGreen,
        ),
      );
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

  // Import products from CSV
  Future<void> _importProducts() async {
    try {
      final products = await ImportService.importProductsFromCsv();
      if (products != null && products.isNotEmpty) {
        await _productService.syncProducts(products);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Imported ${products.length} products successfully!',
              ),
              backgroundColor: successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing products: $e'),
            backgroundColor: errorRed,
          ),
        );
      }
    }
  }

  // Import customers from CSV
  Future<void> _importCustomers() async {
    try {
      final customers = await ImportService.importCustomersFromCsv();
      if (customers != null && customers.isNotEmpty) {
        await _customerService.syncCustomers(customers);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Imported ${customers.length} customers successfully!',
              ),
              backgroundColor: successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing customers: $e'),
            backgroundColor: errorRed,
          ),
        );
      }
    }
  }

  // Sync customers from desktop
  Future<void> _syncCustomersFromDesktop() async {
    setState(() => _isSyncing = true);
    try {
      final result = await SyncService.syncCustomersFromDesktop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? successGreen : errorRed,
          ),
        );
        if (result.success) {
          await _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // Sync products from desktop
  Future<void> _syncProductsFromDesktop() async {
    setState(() => _isSyncing = true);
    try {
      final result = await SyncService.syncProductsFromDesktop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? successGreen : errorRed,
          ),
        );
        if (result.success) {
          await _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // Show add customer dialog
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
                );
                await _customerService.addCustomer(customer);
                await _loadData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Customer added successfully!'),
                      backgroundColor: successGreen,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Show add product dialog
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
                );
                await _productService.addProduct(product);
                await _loadData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product added successfully!'),
                      backgroundColor: successGreen,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Show add salesman dialog
  void _showAddSalesmanDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  emailController.text.isNotEmpty) {
                final salesman = UserModel(
                  id: 'salesman_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  role: UserRole.salesman,
                  createdAt: DateTime.now(),
                  isActive: true,
                );
                setState(() {
                  _salesmen.add(salesman);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Salesman added successfully!'),
                    backgroundColor: successGreen,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Build sidebar overlay - Fixed to work like salesman dashboard
  Widget _buildSidebarOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _isSidebarOpen = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Stack(
          children: [
            // Semi-transparent background
            Container(color: Colors.black54),
            // Sidebar panel
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {}, // Prevent tap from closing when clicking sidebar
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
                        // Header
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
                                    const Text(
                                      'Distributor',
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
                        // Menu items
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

  // Build templates section (placeholder)
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

  // Build analytics section (placeholder)
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

  // Show order details with PDF download and WhatsApp share
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
              // Order Info
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
              // Items
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
              // Totals
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
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final path = await PdfService.downloadOrderPdf(order);
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  path != null
                                      ? 'PDF saved to: $path'
                                      : 'Failed to download PDF',
                                ),
                                backgroundColor: path != null
                                    ? successGreen
                                    : errorRed,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: errorRed,
                              ),
                            );
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error sharing: $e'),
                                backgroundColor: errorRed,
                              ),
                            );
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

  // ==================== DASHBOARD ====================
  Widget _buildDashboard() {
    final totalRevenue = _orders
        .where((o) => o.status == OrderStatus.delivered)
        .fold<double>(0, (sum, o) => sum + o.totalAmount);
    final pendingOrders = _orders
        .where((o) => o.status == OrderStatus.pending)
        .length;
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
            // Welcome Card
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

            // Target Achievement Card
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

            // Quick Stats Cards
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

            // Quick Actions
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

            // Recent Orders
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

  // ==================== OVERVIEW SECTION ====================
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

          // Revenue & Orders Cards
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

          // Order Status Distribution
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

          // Top Salesmen
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
    final salesmanPerformance = <UserModel, Map<String, dynamic>>{};

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

  // ==================== CUSTOMERS SECTION ====================
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
              // Search bar for customers
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
                // Last Billing Status
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

  // ==================== PRODUCTS SECTION ====================
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
              // Search bar for products
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
                // Last Sale Info
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

  // ==================== SALESMEN SECTION ====================
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
              // Search bar for salesmen
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

  Widget _buildSalesmanCard(UserModel salesman) {
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
          backgroundColor: salesman.isActive
              ? accentTeal.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: salesman.isActive ? accentTeal : Colors.grey,
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
            color: salesman.isActive
                ? successGreen.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            salesman.isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: salesman.isActive ? successGreen : Colors.grey,
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
                // Last Order Details
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

  // ==================== ORDERS SECTION ====================
  // Helper to get payment mode display text
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

  // Check if payment is done at delivery (paid upfront)
  bool _isPaidAtDelivery(OrderModel order) {
    return order.paymentMode == PaymentMode.cash ||
        order.paymentMode == PaymentMode.upi ||
        order.paymentMode == PaymentMode.bankTransfer;
  }

  // Get UPI type display name
  String _getUpiTypeName(UpiType type) {
    switch (type) {
      case UpiType.gpay:
        return 'Google Pay (GPay)';
      case UpiType.phonepe:
        return 'PhonePe';
      case UpiType.paytm:
        return 'Paytm';
      case UpiType.other:
        return 'Other UPI App';
    }
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
              // Search bar for orders
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
              // Salesman filter dropdown
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
              // Post to Desktop button and selection controls
              Row(
                children: [
                  // Select All checkbox
                  Checkbox(
                    value:
                        _selectedOrderIds.length == filteredOrders.length &&
                        filteredOrders.isNotEmpty,
                    onChanged: (_) => _selectAllOrders(),
                  ),
                  const Text('Select All'),
                  const Spacer(),
                  // Post to Desktop button
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
        // Table Header
        Container(
          color: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              // Checkbox column
              const SizedBox(width: 40),
              // Order Date column
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
              // Order ID column
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
              // Customer Name column
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
              // Salesman Name column
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
              // Amount column
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
              // Payment Mode column
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
        // Table Body
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

  // Order table row
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
              // Checkbox column
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleOrderSelection(order.id),
                  activeColor: accentTeal,
                ),
              ),
              // Sr No
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
              // Order Date
              Expanded(
                flex: 2,
                child: Text(
                  '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              // Order ID
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
              // Customer Name
              Expanded(
                flex: 3,
                child: Text(
                  order.customerName,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Salesman Name
              Expanded(
                flex: 3,
                child: Text(
                  order.salesmanName,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Amount
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
              // Payment Mode
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

  // ==================== CREATE ORDER SECTION ====================
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
        Expanded(
          child: ListView.builder(
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

  // ==================== PAYMENT COLLECTION SECTION ====================
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
    UpiType? dialogSelectedUpiType;

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
                    ChoiceChip(
                      label: const Text('Cheque'),
                      selected: selectedMode == PaymentMode.cheque,
                      onSelected: (_) => setDialogState(
                        () => selectedMode = PaymentMode.cheque,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Cheque + Cash'),
                      selected: selectedMode == PaymentMode.chequeWithCash,
                      onSelected: (_) => setDialogState(
                        () => selectedMode = PaymentMode.chequeWithCash,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Show UPI type dropdown when UPI is selected
                if (selectedMode == PaymentMode.upi) ...[
                  const Text(
                    'UPI Type:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UpiType>(
                    value: dialogSelectedUpiType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select UPI App',
                    ),
                    items: UpiType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getUpiTypeName(type)),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() {
                      dialogSelectedUpiType = value;
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _transactionNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Show Cheque fields when Cheque is selected
                if (selectedMode == PaymentMode.cheque) ...[
                  TextField(
                    controller: _chequeNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Cheque Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _chequeDateController,
                    decoration: const InputDecoration(
                      labelText: 'Cheque Date',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() {
                          _chequeDateController.text =
                              '${date.day}/${date.month}/${date.year}';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _chequeAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Cheque Amount',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                ],
                // Show Cheque + Cash fields
                if (selectedMode == PaymentMode.chequeWithCash) ...[
                  TextField(
                    controller: _chequeNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Cheque Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _chequeDateController,
                    decoration: const InputDecoration(
                      labelText: 'Cheque Date',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() {
                          _chequeDateController.text =
                              '${date.day}/${date.month}/${date.year}';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _chequeAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Cheque Amount',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cashAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Cash Amount',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                ],
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment collected successfully!'),
                        backgroundColor: successGreen,
                      ),
                    );
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
