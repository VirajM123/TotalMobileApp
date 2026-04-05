cd totflutter --versionflutter --versionimport 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../auth/login_screen.dart';

// Enhanced Salesman Dashboard with Advanced Features
class SalesmanDashboard extends StatefulWidget {
  const SalesmanDashboard({super.key});

  @override
  State<SalesmanDashboard> createState() => _SalesmanDashboardState();
}

class _SalesmanDashboardState extends State<SalesmanDashboard> {
  // Color constants
  static const Color primaryBlue = Color(0xFF1A3B70);
  static const Color accentTeal = Color(0xFF00A68A);
  static const Color secondaryBlue = Color(0xFF2C599D);

  // Theme mode
  ThemeMode _themeMode = ThemeMode.light;

  int _selectedIndex = 0;
  bool _isSidebarOpen = false;

  // Services
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();

  // Current salesman
  final UserModel _currentSalesman = UserModel(
    id: 'salesman_001',
    email: 'salesman@demo.com',
    name: 'John Salesman',
    phone: '+91 9876543211',
    role: UserRole.salesman,
    createdAt: DateTime.now().subtract(const Duration(days: 15)),
    isActive: true,
  );

  // Data
  List<CustomerModel> _customers = [];
  List<ProductModel> _products = [];
  List<OrderModel> _orders = [];
  List<OrderTemplateModel> _orderTemplates = [];
  bool _isLoading = true;

  // Cart as map with full order item details
  final Map<String, CartItemData> _cart = {};

  // Order creation state
  int _orderStep = 1;
  String? _selectedCustomerId;
  String? _editingOrderId; // Track if editing existing order
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

  // Customer search for Create Order
  final TextEditingController _customerSearchController =
      TextEditingController();
  String _customerSearchQuery = '';

  // Product search for Create Order
  final TextEditingController _productSearchController =
      TextEditingController();
  String _productSearchQuery = '';

  // Scheme toggle for Create Order (per customer)
  bool _showSchemeOptions = false;

  // Product search for order step 2 (separate from general product search)
  final TextEditingController _orderProductSearchController =
      TextEditingController();
  String _orderProductSearchQuery = '';

  // Quick reorder
  OrderModel? _selectedOrderForReorder;

  // Product search for Products section
  final TextEditingController _productSectionSearchController =
      TextEditingController();
  String _productSectionSearchQuery = '';

  // Customer search for Customers section
  final TextEditingController _customerSectionSearchController =
      TextEditingController();
  String _customerSectionSearchQuery = '';

  // Order search for Orders section
  final TextEditingController _orderSectionSearchController =
      TextEditingController();
  String _orderSectionSearchQuery = '';

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

  // Visit notes
  final TextEditingController _visitNoteController = TextEditingController();

  // Draft orders
  List<OrderModel> _draftOrders = [];

  // Monthly target
  double _monthlyTarget = 100000;

  // Filtered products
  List<ProductModel> get filteredProducts {
    var products = _products;

    // Search filter - use product section search if available, otherwise use general search
    final searchQuery = _productSectionSearchQuery.isNotEmpty
        ? _productSectionSearchQuery
        : _searchQuery;

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      products = products
          .where(
            (p) =>
                p.name.toLowerCase().contains(query) ||
                p.sku.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query),
          )
          .toList();
    }

    // Category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      products = products
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    // Price range filter
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

  // Filtered products for Create Order (Step 2)
  List<ProductModel> get _filteredOrderProducts {
    if (_orderProductSearchQuery.isEmpty) return _products;
    final query = _orderProductSearchQuery.toLowerCase();
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(query) ||
              p.sku.toLowerCase().contains(query) ||
              p.category.toLowerCase().contains(query),
        )
        .toList();
  }

  // Filtered customers for Create Order
  List<CustomerModel> get filteredCustomers {
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

  // Get last order for a customer
  OrderModel? getLastOrderForCustomer(String customerId) {
    final customerOrders = _orders
        .where((o) => o.customerId == customerId)
        .toList();
    if (customerOrders.isEmpty) return null;
    customerOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return customerOrders.first;
  }

  // Get frequent items for customer
  List<OrderItemModel> getFrequentItemsForCustomer(String customerId) {
    final customerOrders = _orders
        .where((o) => o.customerId == customerId)
        .toList();
    if (customerOrders.isEmpty) return [];

    // Count product occurrences
    final Map<String, int> productCounts = {};
    final Map<String, OrderItemModel> productItems = {};

    for (var order in customerOrders) {
      for (var item in order.items) {
        productCounts[item.productId] =
            (productCounts[item.productId] ?? 0) + item.quantity;
        if (!productItems.containsKey(item.productId)) {
          productItems[item.productId] = item;
        }
      }
    }

    // Sort by count and return top items
    final sortedKeys = productCounts.keys.toList()
      ..sort((a, b) => productCounts[b]!.compareTo(productCounts[a]!));

    return sortedKeys.take(5).map((key) => productItems[key]!).toList();
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _customerService.getCustomers(),
      _productService.getProducts(),
      _orderService.getOrdersBySalesman(_currentSalesman.id),
    ]);

    setState(() {
      _customers = results[0] as List<CustomerModel>;
      _products = results[1] as List<ProductModel>;
      _orders = results[2] as List<OrderModel>;
      _draftOrders = _orderService.getDraftOrders();
      // Add default order templates
      _orderTemplates = [
        OrderTemplateModel(
          id: 'template_1',
          name: 'Weekly Essentials',
          salesmanId: _currentSalesman.id,
          items: [
            OrderItemModel(
              id: 'item_1_1',
              productId: 'prod_001',
              productName: 'Milk Pack',
              sku: 'MLK001',
              quantity: 10,
              rate: 50,
              amount: 500,
            ),
            OrderItemModel(
              id: 'item_1_2',
              productId: 'prod_002',
              productName: 'Bread',
              sku: 'BRD001',
              quantity: 5,
              rate: 40,
              amount: 200,
            ),
          ],
          estimatedAmount: 700,
          createdAt: DateTime.now(),
        ),
        OrderTemplateModel(
          id: 'template_2',
          name: 'Monthly Groceries',
          salesmanId: _currentSalesman.id,
          items: [
            OrderItemModel(
              id: 'item_2_1',
              productId: 'prod_003',
              productName: 'Rice Bag',
              sku: 'RICE01',
              quantity: 2,
              rate: 800,
              amount: 1600,
            ),
            OrderItemModel(
              id: 'item_2_2',
              productId: 'prod_004',
              productName: 'Sugar',
              sku: 'SGR001',
              quantity: 5,
              rate: 45,
              amount: 225,
            ),
          ],
          estimatedAmount: 1825,
          createdAt: DateTime.now(),
        ),
        OrderTemplateModel(
          id: 'template_3',
          name: 'Party Pack',
          salesmanId: _currentSalesman.id,
          items: [
            OrderItemModel(
              id: 'item_3_1',
              productId: 'prod_005',
              productName: 'Chips',
              sku: 'CHP001',
              quantity: 10,
              rate: 30,
              amount: 300,
            ),
            OrderItemModel(
              id: 'item_3_2',
              productId: 'prod_006',
              productName: 'Soft Drinks',
              sku: 'DRK001',
              quantity: 6,
              rate: 80,
              amount: 480,
            ),
          ],
          estimatedAmount: 780,
          createdAt: DateTime.now(),
        ),
        OrderTemplateModel(
          id: 'template_4',
          name: 'Daily Dairy',
          salesmanId: _currentSalesman.id,
          items: [
            OrderItemModel(
              id: 'item_4_1',
              productId: 'prod_001',
              productName: 'Milk Pack',
              sku: 'MLK001',
              quantity: 20,
              rate: 50,
              amount: 1000,
            ),
            OrderItemModel(
              id: 'item_4_2',
              productId: 'prod_007',
              productName: 'Curd',
              sku: 'CRD001',
              quantity: 5,
              rate: 60,
              amount: 300,
            ),
          ],
          estimatedAmount: 1300,
          createdAt: DateTime.now(),
        ),
        OrderTemplateModel(
          id: 'template_5',
          name: 'Office Supplies',
          salesmanId: _currentSalesman.id,
          items: [
            OrderItemModel(
              id: 'item_5_1',
              productId: 'prod_008',
              productName: 'Tea Pack',
              sku: 'TEA001',
              quantity: 2,
              rate: 200,
              amount: 400,
            ),
            OrderItemModel(
              id: 'item_5_2',
              productId: 'prod_009',
              productName: 'Coffee Pack',
              sku: 'COF001',
              quantity: 1,
              rate: 350,
              amount: 350,
            ),
          ],
          estimatedAmount: 750,
          createdAt: DateTime.now(),
        ),
      ];
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // Cart method for ProductModel
  void addToCart(
    ProductModel product, {
    int quantity = 1,
    double rate = 0,
    double schPer = 0,
    double schAmt = 0,
  }) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        // Update existing item
        _cart[product.id]!.quantity = quantity;
        _cart[product.id]!.rate = rate > 0 ? rate : product.price;
        _cart[product.id]!.schPer = schPer;
        _cart[product.id]!.schAmt = schAmt;
        _cart[product.id]!.calculate();
      } else {
        // Add new item
        _cart[product.id] = CartItemData(
          productId: product.id,
          productName: product.name,
          sku: product.sku,
          quantity: quantity,
          rate: rate > 0 ? rate : product.price,
          schPer: schPer,
          schAmt: schAmt,
        );
        _cart[product.id]!.calculate();
      }
    });
  }

  // Cart method for String (productId) - for backward compatibility
  void addToCartById(String productId, {int quantity = 1}) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!.quantity += quantity;
        _cart[productId]!.calculate();
      } else {
        final product = _products.firstWhere(
          (p) => p.id == productId,
          orElse: () => ProductModel(
            id: '',
            name: 'Unknown',
            category: '',
            sku: '',
            price: 0,
            stock: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        _cart[productId] = CartItemData(
          productId: productId,
          productName: product.name,
          sku: product.sku,
          quantity: quantity,
          rate: product.price,
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

  double get cartTotal {
    double total = 0;
    _cart.forEach((productId, cartItem) {
      total += cartItem.netAmt;
    });
    return total;
  }

  double get cartGrossTotal {
    double total = 0;
    _cart.forEach((productId, cartItem) {
      total += cartItem.grossAmt;
    });
    return total;
  }

  double get cartSchemeTotal {
    double total = 0;
    _cart.forEach((productId, cartItem) {
      total += cartItem.schAmt;
    });
    return total;
  }

  int get cartItemCount => _cart.length;

  // Quick reorder - add all items from a previous order
  void quickReorder(OrderModel order) {
    setState(() {
      for (var item in order.items) {
        if (_cart.containsKey(item.productId)) {
          // Update existing item
          _cart[item.productId]!.quantity += item.quantity;
          _cart[item.productId]!.calculate();
        } else {
          // Add new item - find the product to get details
          final product = _products.firstWhere(
            (p) => p.id == item.productId,
            orElse: () => ProductModel(
              id: item.productId,
              name: item.productName,
              category: '',
              sku: item.sku,
              price: item.rate,
              stock: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          _cart[item.productId] = CartItemData(
            productId: item.productId,
            productName: item.productName,
            sku: item.sku,
            quantity: item.quantity,
            rate: item.rate,
          );
          _cart[item.productId]!.calculate();
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${order.items.length} items to cart'),
        backgroundColor: accentTeal,
      ),
    );
  }

  // Save order as draft
  Future<void> saveAsDraft() async {
    if (_selectedCustomerId == null || _cart.isEmpty) return;

    final customer = _customers.firstWhere((c) => c.id == _selectedCustomerId);

    final order = OrderModel(
      id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      orderNumber:
          'DRAFT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      customerId: _selectedCustomerId!,
      customerName: customer.name,
      customerPhone: customer.phone ?? customer.mobile ?? '',
      areaName: customer.area,
      salesmanId: _currentSalesman.id,
      salesmanName: _currentSalesman.name,
      items: _cart.entries.map((entry) {
        final product = _products.firstWhere((p) => p.id == entry.key);
        final cartItem = entry.value;
        return OrderItemModel(
          id: 'item_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
          productId: product.id,
          productName: product.name,
          sku: product.sku,
          quantity: cartItem.quantity,
          rate: cartItem.rate,
          amount: cartItem.netAmt, // Use net amount after scheme
          schPer: cartItem.schPer,
          schAmt: cartItem.schAmt,
          grossAmt: cartItem.grossAmt,
          netAmt: cartItem.netAmt,
        );
      }).toList(),
      totalAmount: cartTotal,
      paidAmount: 0,
      dueAmount: cartTotal,
      status: OrderStatus.pending,
      orderType: OrderType.draft,
      notes: _orderNotes,
      internalNotes: _internalNotes,
      createdAt: DateTime.now(),
    );

    await _orderService.saveAsDraft(order);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order saved as draft'),
          backgroundColor: accentTeal,
        ),
      );
      _clearCart();
    }
  }

  // Create order from template
  Future<void> createFromTemplate(
    OrderTemplateModel template,
    String customerId,
  ) async {
    final customer = _customers.firstWhere((c) => c.id == customerId);
    await _orderService.createFromTemplate(
      template,
      customerId,
      customer.name,
      customer.phone ?? customer.mobile ?? '',
      customer.area,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order created from template: ${template.name}'),
          backgroundColor: accentTeal,
        ),
      );
      _loadData();
    }
  }

  // Record payment
  Future<void> recordPayment(
    String orderId,
    double amount,
    PaymentMode mode,
  ) async {
    await _orderService.recordPayment(
      orderId,
      amount,
      mode,
      reference: _referenceController.text.isNotEmpty
          ? _referenceController.text
          : null,
    );
    _referenceController.clear();
    _loadData();
  }

  // Submit order
  Future<void> submitOrder() async {
    if (_selectedCustomerId == null || _cart.isEmpty) return;

    final customer = _customers.firstWhere((c) => c.id == _selectedCustomerId);

    final order = OrderModel(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}',
      orderNumber:
          'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      customerId: _selectedCustomerId!,
      customerName: customer.name,
      customerPhone: customer.phone ?? customer.mobile ?? '',
      areaName: customer.area,
      routeName: customer.route ?? '',
      salesmanId: _currentSalesman.id,
      salesmanName: _currentSalesman.name,
      items: _cart.entries.map((entry) {
        final product = _products.firstWhere((p) => p.id == entry.key);
        final cartItem = entry.value;
        return OrderItemModel(
          id: 'item_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
          productId: product.id,
          productName: product.name,
          sku: product.sku,
          quantity: cartItem.quantity,
          rate: cartItem.rate,
          amount: cartItem.netAmt,
          schPer: cartItem.schPer,
          schAmt: cartItem.schAmt,
          grossAmt: cartItem.grossAmt,
          netAmt: cartItem.netAmt,
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
          backgroundColor: accentTeal,
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
      _editingOrderId = null;
      _orderStep = 1;
      _orderNotes = '';
      _internalNotes = '';
      _selectedOrderType = OrderType.regular;
      _scheduledDate = null;
      _selectedPaymentMode = PaymentMode.credit;
    });
  }

  // Load an existing order back into the cart for editing
  // FIXED: Now properly loads quantity, schPer, schAmt and recalculates
  void loadOrderToCart(OrderModel order) {
    setState(() {
      _cart.clear();
      _editingOrderId = order.id;
      _selectedCustomerId = order.customerId;

      // Load each item from the order into the cart
      for (final item in order.items) {
        // Create cart item with all values from order item
        final cartItem = CartItemData(
          productId: item.productId,
          productName: item.productName,
          sku: item.sku,
          quantity: item.quantity, // FIXED: Load actual quantity
          rate: item.rate,
          schPer: item.schPer ?? 0, // Load scheme percentage if available
          schAmt: item.schAmt ?? 0, // Load scheme amount if available
        );
        // Recalculate to ensure all amounts are correct based on loaded values
        cartItem.calculate();

        // Store in cart
        _cart[item.productId] = cartItem;
      }

      // Navigate to create order section
      _selectedIndex = 3;
      _orderStep = 2; // Go to product selection step
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order ${order.orderNumber} loaded for editing - ${order.items.length} items',
        ),
        backgroundColor: accentTeal,
      ),
    );
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salesman Dashboard',
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
              // Theme Toggle
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: _toggleTheme,
                tooltip: isDark ? 'Light Mode' : 'Dark Mode',
              ),
              _headerIcon(Icons.notifications_none, "Alerts"),
              _headerIcon(
                Icons.shopping_cart,
                "Cart",
                count: cartItemCount.toString(),
                onTap: () => _showCartDialog(),
              ),
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
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search products, customers...',
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

  Widget _headerIcon(
    IconData icon,
    String label, {
    String? count,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                if (count != null && count != '0')
                  Positioned(
                    right: -2,
                    top: -2,
                    child: CircleAvatar(
                      radius: 7,
                      backgroundColor: Colors.orange,
                      child: Text(
                        count,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
        return _buildProductsSection();
      case 2:
        return _buildCustomersSection();
      case 3:
        return _buildCreateOrderSection();
      case 4:
        return _buildOrderHistorySection();
      case 5:
        return _buildPaymentCollectionSection();
      case 6:
        return _buildTemplatesSection();
      case 7:
        return _buildAnalyticsSection();
      default:
        return _buildDashboard();
    }
  }

  // ==================== DASHBOARD ====================
  Widget _buildDashboard() {
    final totalOrderAmount = _orders.fold<double>(
      0,
      (sum, o) => sum + o.totalAmount,
    );
    final achievementPercentage = _monthlyTarget > 0
        ? (totalOrderAmount / _monthlyTarget * 100).clamp(0, 100)
        : 0.0;
    final todayCollection = _orderService.todayCollection;
    final pendingAmount = _orderService.totalPendingAmount;

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
                          _currentSalesman.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Let\'s crush your targets! 💪',
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

            // Quick Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    'Today\'s Orders',
                    '${_orderService.todayOrders}',
                    Icons.shopping_bag,
                    primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickStatCard(
                    'Today Collection',
                    '₹${todayCollection.toStringAsFixed(0)}',
                    Icons.currency_rupee,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    'Pending Dues',
                    '₹${pendingAmount.toStringAsFixed(0)}',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickStatCard(
                    'Draft Orders',
                    '${_draftOrders.length}',
                    Icons.drafts,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Target vs Achievement
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
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${achievementPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: achievementPercentage >= 100
                                ? Colors.green
                                : Colors.orange,
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
                            ? Colors.green
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
                        'Achievement: ₹${(totalOrderAmount / 1000).toStringAsFixed(1)}K',
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
                    () => setState(() => _selectedIndex = 3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionCard(
                    'Collect Payment',
                    Icons.payment,
                    Colors.green,
                    () => setState(() => _selectedIndex = 5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Templates',
                    Icons.copy,
                    Colors.purple,
                    () => setState(() => _selectedIndex = 6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionCard(
                    'Analytics',
                    Icons.analytics,
                    Colors.blue,
                    () => setState(() => _selectedIndex = 7),
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
              onPressed: () => setState(() => _selectedIndex = 4),
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
          ...recentOrders.map(
            (order) => _buildOrderCard(order, showQuickReorder: true),
          ),
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order, {bool showQuickReorder = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Row(
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
                              color: Colors.red,
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
                        if (order.orderType == OrderType.scheduled)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SCHEDULED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                      ),
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
          if (showQuickReorder) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showOrderPreview(order),
                  icon: const Icon(Icons.preview, size: 16),
                  label: const Text('Preview'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final path = await PdfService.downloadOrderPdf(order);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              path != null
                                  ? 'PDF saved to: $path'
                                  : 'Failed to download PDF',
                            ),
                            backgroundColor: path != null
                                ? Colors.green
                                : Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await PdfService.shareOrderPdf(order);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error sharing: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => quickReorder(order),
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('Quick Reorder'),
                  style: TextButton.styleFrom(foregroundColor: accentTeal),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.taken:
        return Colors.blue;
      case OrderStatus.dispatched:
        return Colors.purple;
      case OrderStatus.delivered:
        return accentTeal;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  // ==================== PRODUCTS SECTION ====================
  Widget _buildProductsSection() {
    return Column(
      children: [
        // Filter Bar
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
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => _showFilterDialog(),
                  ),
                ],
              ),
              // Category chips
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
              const SizedBox(height: 8),
              // Search bar for products
              TextField(
                controller: _productSectionSearchController,
                decoration: InputDecoration(
                  hintText: 'Search products by name, SKU...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: _productSectionSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _productSectionSearchController.clear();
                            setState(() => _productSectionSearchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) =>
                    setState(() => _productSectionSearchQuery = value),
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
              final inCart = _cart[product.id]?.quantity ?? 0;
              return _buildProductCard(product, inCart);
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

  Widget _buildProductCard(ProductModel product, int inCart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2, color: primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'SKU: ${product.sku} | Stock: ${product.stock}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    'Category: ${product.category}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (inCart > 0)
              Container(
                decoration: BoxDecoration(
                  color: accentTeal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => removeFromCart(product.id),
                      icon: const Icon(
                        Icons.remove,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$inCart',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => addToCartById(product.id),
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: () => addToCartById(product.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
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

  // ==================== CUSTOMERS SECTION ====================
  // Filtered customers for Customers section
  List<CustomerModel> get filteredCustomersForSection {
    if (_customerSectionSearchQuery.isEmpty) return _customers;
    final query = _customerSectionSearchQuery.toLowerCase();
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

  Widget _buildCustomersSection() {
    return Column(
      children: [
        // Header with Search Bar
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
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredCustomersForSection.length} Customers',
                      style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Search bar for customers
              TextField(
                controller: _customerSectionSearchController,
                decoration: InputDecoration(
                  hintText: 'Search customers by name, area, phone...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: _customerSectionSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _customerSectionSearchController.clear();
                            setState(() => _customerSectionSearchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) =>
                    setState(() => _customerSectionSearchQuery = value),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredCustomersForSection.length,
            itemBuilder: (context, index) {
              final customer = filteredCustomersForSection[index];
              final outstanding = getCustomerOutstanding(customer.id);
              final lastOrder =
                  _orders.where((o) => o.customerId == customer.id).toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              return _buildCustomerCard(
                customer,
                outstanding,
                lastOrder.isNotEmpty ? lastOrder.first : null,
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
    OrderModel? lastOrder,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${outstanding.toStringAsFixed(0)} due',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            : const Icon(Icons.check_circle, color: Colors.green),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lastOrder != null) ...[
                  const Text(
                    'Last Order:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${lastOrder.orderNumber} - ₹${lastOrder.totalAmount.toStringAsFixed(0)}',
                  ),
                  Text(
                    '${lastOrder.items.length} items - ${lastOrder.statusDisplay}',
                    style: TextStyle(color: _getStatusColor(lastOrder.status)),
                  ),
                  const Divider(),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _selectedCustomerId = customer.id);
                        setState(() => _selectedIndex = 3);
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text('New Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentTeal,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showVisitNoteDialog(customer),
                      icon: const Icon(Icons.note_add, size: 16),
                      label: const Text('Add Note'),
                    ),
                  ],
                ),
                // Frequent items
                if (getFrequentItemsForCustomer(customer.id).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Frequently Ordered:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children: getFrequentItemsForCustomer(customer.id)
                        .map(
                          (item) => ActionChip(
                            label: Text(
                              '${item.productName} (${item.quantity})',
                            ),
                            onPressed: () {
                              addToCartById(
                                item.productId,
                                quantity: item.quantity,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added ${item.productName}'),
                                ),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVisitNoteDialog(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Visit Note'),
        content: TextField(
          controller: _visitNoteController,
          decoration: const InputDecoration(
            hintText: 'Enter note...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save note logic here
              Navigator.pop(context);
              _visitNoteController.clear();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Note saved')));
            },
            child: const Text('Save'),
          ),
        ],
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
          const SizedBox(height: 8),
          const Text(
            'Choose a customer for this order',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Customer Search Field
          TextField(
            controller: _customerSearchController,
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
              suffixIcon: _customerSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _customerSearchController.clear();
                        setState(() => _customerSearchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _customerSearchQuery = value),
          ),
          const SizedBox(height: 16),
          // Results count
          Text(
            'Showing ${filteredCustomers.length} of ${_customers.length} customers',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredCustomers.length,
            itemBuilder: (context, index) {
              final customer = filteredCustomers[index];
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
                                  color: Colors.red,
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
        // Order Options
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              const SizedBox(height: 12),
              // Order Type Selection
              const Text(
                'Order Type:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Regular'),
                    selected: _selectedOrderType == OrderType.regular,
                    onSelected: (_) =>
                        setState(() => _selectedOrderType = OrderType.regular),
                  ),
                  ChoiceChip(
                    label: const Text('Urgent'),
                    selected: _selectedOrderType == OrderType.urgent,
                    onSelected: (_) =>
                        setState(() => _selectedOrderType = OrderType.urgent),
                  ),
                  ChoiceChip(
                    label: const Text('Scheduled'),
                    selected: _selectedOrderType == OrderType.scheduled,
                    onSelected: (_) => setState(
                      () => _selectedOrderType = OrderType.scheduled,
                    ),
                  ),
                ],
              ),
              if (_selectedOrderType == OrderType.scheduled) ...[
                const SizedBox(height: 12),
                ListTile(
                  title: Text(
                    _scheduledDate != null
                        ? 'Scheduled: ${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                        : 'Select Date',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) setState(() => _scheduledDate = date);
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Reorder from last order
        if (_selectedCustomerId != null &&
            getFrequentItemsForCustomer(_selectedCustomerId!).isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Quick Add - Frequently Ordered',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: getFrequentItemsForCustomer(_selectedCustomerId!)
                      .map(
                        (item) => ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: Text(item.productName),
                          onPressed: () => addToCartById(
                            item.productId,
                            quantity: item.quantity,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Products with Search
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
                  const Text(
                    'Select Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  // Scheme Toggle
                  Row(
                    children: [
                      const Text(
                        'Scheme',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: _showSchemeOptions,
                        onChanged: (value) =>
                            setState(() => _showSchemeOptions = value),
                        activeColor: accentTeal,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Product Search Field
              TextField(
                controller: _orderProductSearchController,
                decoration: InputDecoration(
                  hintText: 'Search products by name, SKU...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: _orderProductSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _orderProductSearchController.clear();
                            setState(() => _orderProductSearchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) =>
                    setState(() => _orderProductSearchQuery = value),
              ),
              const SizedBox(height: 8),
              // Filtered products count
              Text(
                'Showing ${_filteredOrderProducts.length} of ${_products.length} products',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredOrderProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredOrderProducts[index];
                  final inCart = _cart[product.id] != null ? 1 : 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: inCart > 0
                          ? accentTeal.withOpacity(0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: inCart > 0 ? accentTeal : Colors.grey[300]!,
                        width: inCart > 0 ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'SKU: ${product.sku}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
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
                                icon: const Icon(Icons.edit, size: 16),
                                onPressed: () => _showAddProductDialog(product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: () => removeFromCart(product.id),
                              ),
                              Text(
                                '${_cart[product.id]?.quantity ?? 0}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: () => _showAddProductDialog(product),
                              ),
                            ],
                          )
                        else
                          ElevatedButton(
                            onPressed: () => _showAddProductDialog(product),
                            child: const Text('Add'),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _orderStep = 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('← Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _cart.isNotEmpty
                    ? () => setState(() => _orderStep = 3)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentTeal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
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
        // Customer Info
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
                  fontSize: 16,
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
              if (getCustomerOutstanding(customer.id) > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Previous Outstanding: ₹${getCustomerOutstanding(customer.id).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payment Mode
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
                  fontSize: 16,
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
                    label: const Text('Bank Transfer'),
                    selected: _selectedPaymentMode == PaymentMode.bankTransfer,
                    onSelected: (_) => setState(
                      () => _selectedPaymentMode = PaymentMode.bankTransfer,
                    ),
                  ),
                ],
              ),
              if (_selectedPaymentMode != PaymentMode.credit) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference Number (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Transaction ID, Cheque number, etc.',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Notes
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Order Notes (for customer)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _orderNotes = v,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Internal Notes (private)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _internalNotes = v,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Order Items
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
                  const Text(
                    'Order Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  Text(
                    '$cartItemCount items',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const Divider(),
              ...(_cart.entries.map((entry) {
                final product = _products.firstWhere((p) => p.id == entry.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
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
              })),
              const Divider(),
              // Scheme Breakdown
              if (cartSchemeTotal > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gross Total',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      '₹${cartGrossTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Scheme Discount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '-₹${cartSchemeTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Net Total',
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

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _orderStep = 2),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('← Edit'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: saveAsDraft,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save Draft'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentTeal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Submit ✅'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== ORDER HISTORY ====================
  Widget _buildOrderHistorySection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'My Orders',
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_orders.length} Orders',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        'No orders yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) =>
                      _buildOrderCard(_orders[index], showQuickReorder: true),
                ),
        ),
      ],
    );
  }

  // ==================== PAYMENT COLLECTION ====================
  Widget _buildPaymentCollectionSection() {
    final ordersWithDue = _orders
        .where((o) => o.dueAmount > 0 && o.status != OrderStatus.cancelled)
        .toList();

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
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹${_orderService.totalPendingAmount.toStringAsFixed(0)} Due',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // View Collection History Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCustomerCollectionHistoryDialog(),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('View Customer Collection History'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: const BorderSide(color: primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                      Icon(Icons.check_circle, size: 60, color: Colors.green),
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
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '₹${order.dueAmount.toStringAsFixed(0)} due',
                                  style: const TextStyle(
                                    color: Colors.orange,
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
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showPaymentDialog(order),
                                  icon: const Icon(Icons.payment, size: 16),
                                  label: const Text('Collect Payment'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
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
      ],
    );
  }

  // Show customer collection history dialog
  void _showCustomerCollectionHistoryDialog() {
    if (_customers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No customers found')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                    'Select Customer',
                    style: TextStyle(
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
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    final customerOrders = _orders
                        .where((o) => o.customerId == customer.id)
                        .toList();
                    final totalPaid = customerOrders.fold<double>(
                      0,
                      (sum, o) => sum + o.paidAmount,
                    );
                    final totalDue = customerOrders.fold<double>(
                      0,
                      (sum, o) => sum + o.dueAmount,
                    );

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryBlue.withOpacity(0.1),
                        child: const Icon(Icons.person, color: primaryBlue),
                      ),
                      title: Text(customer.name),
                      subtitle: Text(
                        'Paid: ₹${totalPaid.toStringAsFixed(0)} | Due: ₹${totalDue.toStringAsFixed(0)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _showCustomerPaymentHistory(customer);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show payment history for a specific customer
  void _showCustomerPaymentHistory(CustomerModel customer) {
    // Get all orders for this customer
    final customerOrders = _orders
        .where((o) => o.customerId == customer.id)
        .toList();

    // Collect all payments from all orders
    final List<Map<String, dynamic>> allPayments = [];
    for (var order in customerOrders) {
      for (var payment in order.payments) {
        allPayments.add({'orderNumber': order.orderNumber, 'payment': payment});
      }
    }

    // Sort by date (newest first)
    allPayments.sort((a, b) {
      final paymentA = a['payment'] as PaymentCollectionModel;
      final paymentB = b['payment'] as PaymentCollectionModel;
      return paymentB.collectedAt.compareTo(paymentA.collectedAt);
    });

    // Calculate totals
    final totalPaid = customerOrders.fold<double>(
      0,
      (sum, o) => sum + o.paidAmount,
    );
    final totalDue = customerOrders.fold<double>(
      0,
      (sum, o) => sum + o.dueAmount,
    );
    final totalOrders = customerOrders.length;

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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        Text(
                          'Area: ${customer.area}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildHistorySummaryCard(
                      'Total Orders',
                      '$totalOrders',
                      Icons.receipt,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHistorySummaryCard(
                      'Total Paid',
                      '₹${totalPaid.toStringAsFixed(0)}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHistorySummaryCard(
                      'Total Due',
                      '₹${totalDue.toStringAsFixed(0)}',
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const Divider(),
              if (allPayments.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No payments yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: allPayments.length,
                    itemBuilder: (context, index) {
                      final data = allPayments[index];
                      final payment = data['payment'] as PaymentCollectionModel;
                      final orderNumber = data['orderNumber'] as String;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
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
                                  '₹${payment.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPaymentModeColor(
                                      payment.mode,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    payment.paymentModeDisplay,
                                    style: TextStyle(
                                      color: _getPaymentModeColor(payment.mode),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Order: $orderNumber',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${payment.collectedAt.day}/${payment.collectedAt.month}/${payment.collectedAt.year} ${payment.collectedAt.hour}:${payment.collectedAt.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            // Show cheque details if applicable
                            if (payment.paymentDetails.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  payment.paymentDetails,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                            // Show remark if available
                            if (payment.remark != null &&
                                payment.remark!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Remark: ${payment.remark}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getPaymentModeColor(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return Colors.green;
      case PaymentMode.upi:
        return Colors.purple;
      case PaymentMode.cheque:
        return Colors.orange;
      case PaymentMode.chequeWithCash:
        return Colors.blue;
      case PaymentMode.bankTransfer:
        return Colors.teal;
      case PaymentMode.credit:
        return Colors.grey;
      case PaymentMode.partial:
        return Colors.amber;
    }
  }

  void _showPaymentDialog(OrderModel order) {
    _paymentAmountController.text = order.dueAmount.toStringAsFixed(0);
    _chequeNumberController.clear();
    _chequeDateController.clear();
    _chequeAmountController.clear();
    _cashAmountController.clear();
    _remarkController.clear();
    PaymentMode selectedMode = PaymentMode.cash;
    bool showChequeFields = false;
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
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Balance Due: ₹${order.dueAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
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
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Cash'),
                      selected: selectedMode == PaymentMode.cash,
                      onSelected: (_) => setDialogState(() {
                        selectedMode = PaymentMode.cash;
                        showChequeFields = false;
                      }),
                    ),
                    ChoiceChip(
                      label: const Text('Cheque'),
                      selected: selectedMode == PaymentMode.cheque,
                      onSelected: (_) => setDialogState(() {
                        selectedMode = PaymentMode.cheque;
                        showChequeFields = true;
                      }),
                    ),
                    ChoiceChip(
                      label: const Text('Cheque+Cash'),
                      selected: selectedMode == PaymentMode.chequeWithCash,
                      onSelected: (_) => setDialogState(() {
                        selectedMode = PaymentMode.chequeWithCash;
                        showChequeFields = true;
                      }),
                    ),
                    ChoiceChip(
                      label: const Text('UPI'),
                      selected: selectedMode == PaymentMode.upi,
                      onSelected: (_) => setDialogState(() {
                        selectedMode = PaymentMode.upi;
                        showChequeFields = false;
                      }),
                    ),
                  ],
                ),
                // Show UPI dropdown when UPI is selected
                if (selectedMode == PaymentMode.upi) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Select UPI App:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UpiType>(
                    value: dialogSelectedUpiType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text('Select UPI App'),
                    items: const [
                      DropdownMenuItem(
                        value: UpiType.gpay,
                        child: Text('Google Pay'),
                      ),
                      DropdownMenuItem(
                        value: UpiType.phonepe,
                        child: Text('PhonePe'),
                      ),
                      DropdownMenuItem(
                        value: UpiType.paytm,
                        child: Text('Paytm'),
                      ),
                      DropdownMenuItem(
                        value: UpiType.other,
                        child: Text('Other UPI'),
                      ),
                    ],
                    onChanged: (value) => setDialogState(() {
                      dialogSelectedUpiType = value;
                    }),
                  ),
                  // Transaction Number field for UPI
                  const SizedBox(height: 12),
                  TextField(
                    controller: _transactionNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Number / UPI Ref ID',
                      border: OutlineInputBorder(),
                      hintText: 'Enter UPI transaction reference',
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                  ),
                  // Screenshot attachment button
                  const SizedBox(height: 12),
                  _buildScreenshotButton(),
                ],
                if (showChequeFields) ...[
                  const SizedBox(height: 16),
                  Text(
                    selectedMode == PaymentMode.chequeWithCash
                        ? 'Cheque Details:'
                        : 'Cheque Details:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _chequeNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Cheque Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _chequeDateController,
                    decoration: const InputDecoration(
                      labelText: 'Cheque Date',
                      border: OutlineInputBorder(),
                      hintText: 'DD/MM/YYYY',
                      suffixIcon: Icon(Icons.calendar_today),
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
                        _chequeDateController.text =
                            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _chequeAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Cheque Amount',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
                // Show cash amount field for Cheque+Cash
                if (selectedMode == PaymentMode.chequeWithCash) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Cash Amount:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cashAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Cash Amount',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _remarkController,
                  decoration: const InputDecoration(
                    labelText: 'Remark (Optional)',
                    border: OutlineInputBorder(),
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
              onPressed: () {
                final amount =
                    double.tryParse(_paymentAmountController.text) ?? 0;
                if (amount > 0) {
                  // Build reference/remark string
                  String? ref = _remarkController.text.isNotEmpty
                      ? _remarkController.text
                      : null;

                  // Prepare payment data
                  double? chequeAmt;
                  double? cashAmt;
                  String? chequeNo;
                  DateTime? chequeDt;

                  if (showChequeFields) {
                    chequeNo = _chequeNumberController.text.isNotEmpty
                        ? _chequeNumberController.text
                        : null;
                    if (_chequeDateController.text.isNotEmpty) {
                      final parts = _chequeDateController.text.split('/');
                      if (parts.length == 3) {
                        chequeDt = DateTime(
                          int.parse(parts[2]),
                          int.parse(parts[1]),
                          int.parse(parts[0]),
                        );
                      }
                    }
                    chequeAmt = double.tryParse(_chequeAmountController.text);
                  }

                  if (selectedMode == PaymentMode.chequeWithCash) {
                    cashAmt = double.tryParse(_cashAmountController.text);
                  }

                  _orderService.recordPayment(
                    order.id,
                    amount,
                    selectedMode,
                    upiType: selectedMode == PaymentMode.upi
                        ? dialogSelectedUpiType
                        : null,
                    transactionNumber:
                        selectedMode == PaymentMode.upi &&
                            _transactionNumberController.text.isNotEmpty
                        ? _transactionNumberController.text
                        : null,
                    paymentScreenshot: _paymentScreenshotPath,
                    chequeNumber: chequeNo,
                    chequeDate: chequeDt,
                    chequeAmount: chequeAmt,
                    cashAmount: cashAmt,
                    remark: ref,
                  );

                  // Clear controllers
                  _remarkController.clear();
                  _chequeNumberController.clear();
                  _chequeDateController.clear();
                  _chequeAmountController.clear();
                  _cashAmountController.clear();

                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment of ₹$amount recorded!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TEMPLATES ====================
  Widget _buildTemplatesSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Order Templates',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateTemplateDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Template'),
                style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
              ),
            ],
          ),
        ),
        if (_orderTemplates.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.copy, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'No templates yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  Text(
                    'Create templates for frequently ordered items',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orderTemplates.length,
              itemBuilder: (context, index) {
                final template = _orderTemplates[index];
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
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${template.items.length} items • Est. ₹${template.estimatedAmount.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: template.items
                            .take(3)
                            .map(
                              (item) => Chip(
                                label: Text(
                                  '${item.productName} x${item.quantity}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _showUseTemplateDialog(template),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentTeal,
                        ),
                        child: const Text('Use Template'),
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

  void _showCreateTemplateDialog() {
    // Implementation for creating templates
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template creation - coming soon!')),
    );
  }

  void _showUseTemplateDialog(OrderTemplateModel template) {
    if (_customers.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use Template'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _customers.length,
            itemBuilder: (context, index) {
              final customer = _customers[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(customer.name),
                subtitle: Text(customer.area),
                onTap: () {
                  Navigator.pop(context);
                  createFromTemplate(template, customer.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ==================== ANALYTICS ====================
  // Analytics time filter state
  String _analyticsTimeFilter = 'month'; // today, week, month, year

  Widget _buildAnalyticsSection() {
    // Filter orders based on time selection
    final now = DateTime.now();
    final filteredOrders = _orders.where((order) {
      switch (_analyticsTimeFilter) {
        case 'today':
          return order.createdAt.year == now.year &&
              order.createdAt.month == now.month &&
              order.createdAt.day == now.day;
        case 'week':
          final weekAgo = now.subtract(const Duration(days: 7));
          return order.createdAt.isAfter(weekAgo);
        case 'month':
          return order.createdAt.year == now.year &&
              order.createdAt.month == now.month;
        case 'year':
          return order.createdAt.year == now.year;
        default:
          return true;
      }
    }).toList();

    // Calculate metrics
    final totalSales = filteredOrders.fold<double>(
      0,
      (sum, o) => sum + o.totalAmount,
    );
    final totalCollection = filteredOrders.fold<double>(
      0,
      (sum, o) => sum + o.paidAmount,
    );
    final pendingDues = filteredOrders.fold<double>(
      0,
      (sum, o) => sum + o.dueAmount,
    );
    final totalOrders = filteredOrders.length;

    // Calculate KPIs
    final avgOrderValue = totalOrders > 0 ? totalSales / totalOrders : 0.0;
    final collectionEfficiency = totalSales > 0
        ? (totalCollection / totalSales * 100)
        : 0.0;

    // Product performance
    final Map<String, double> productSales = {};
    final Map<String, int> productQuantity = {};
    for (var order in filteredOrders) {
      for (var item in order.items) {
        productSales[item.productName] =
            (productSales[item.productName] ?? 0) + item.amount;
        productQuantity[item.productName] =
            (productQuantity[item.productName] ?? 0) + item.quantity;
      }
    }
    final topProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Category performance
    final Map<String, double> categorySales = {};
    for (var order in filteredOrders) {
      for (var item in order.items) {
        try {
          final product = _products.firstWhere((p) => p.id == item.productId);
          categorySales[product.category] =
              (categorySales[product.category] ?? 0) + item.amount;
        } catch (e) {
          // Product not found
        }
      }
    }
    final topCategories = categorySales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Customer performance
    final Map<String, double> customerSales = {};
    for (var order in filteredOrders) {
      customerSales[order.customerName] =
          (customerSales[order.customerName] ?? 0) + order.totalAmount;
    }
    final topCustomers = customerSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Payment mode distribution
    final Map<PaymentMode, double> paymentModeSales = {};
    for (var order in filteredOrders) {
      if (order.paymentMode != null) {
        paymentModeSales[order.paymentMode!] =
            (paymentModeSales[order.paymentMode!] ?? 0) + order.paidAmount;
      }
    }

    // Order status distribution
    final Map<OrderStatus, int> orderStatusCount = {};
    for (var order in filteredOrders) {
      orderStatusCount[order.status] =
          (orderStatusCount[order.status] ?? 0) + 1;
    }

    // Daily sales for chart (last 7 days)
    final Map<String, double> dailySales = {};
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.day}/${date.month}';
      double dayTotal = 0;
      for (var order in filteredOrders) {
        if (order.createdAt.year == date.year &&
            order.createdAt.month == date.month &&
            order.createdAt.day == date.day) {
          dayTotal += order.totalAmount;
        }
      }
      dailySales[dateKey] = dayTotal;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with time filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📊 Analytics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              // Time filter chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTimeFilterChip('Today', 'today'),
                    _buildTimeFilterChip('Week', 'week'),
                    _buildTimeFilterChip('Month', 'month'),
                    _buildTimeFilterChip('Year', 'year'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Target Achievement Gauge (Circular Progress)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3B70), Color(0xFF2C599D)],
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
                        'Monthly Target',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${(_monthlyTarget / 1000).toStringAsFixed(0)}K',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Achievement: ₹${(totalSales / 1000).toStringAsFixed(1)}K',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Circular progress indicator
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: (totalSales / _monthlyTarget).clamp(0.0, 1.0),
                        strokeWidth: 8,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          accentTeal,
                        ),
                      ),
                      Center(
                        child: Text(
                          '${((totalSales / _monthlyTarget) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // KPI Cards Row 1
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Total Sales',
                  '₹${totalSales.toStringAsFixed(0)}',
                  Icons.shopping_cart,
                  Colors.blue,
                  '+${((totalSales / (_monthlyTarget == 0 ? 1 : _monthlyTarget)) * 100).toStringAsFixed(1)}%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKPICard(
                  'Collected',
                  '₹${totalCollection.toStringAsFixed(0)}',
                  Icons.currency_rupee,
                  Colors.green,
                  '${collectionEfficiency.toStringAsFixed(1)}%',
                  subtitle: 'Efficiency',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // KPI Cards Row 2
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Pending Dues',
                  '₹${pendingDues.toStringAsFixed(0)}',
                  Icons.pending_actions,
                  Colors.orange,
                  '${pendingDues > 0 ? "Attention" : "Clear"}',
                  subtitle: pendingDues > 0 ? 'Action needed' : 'All clear',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKPICard(
                  'Total Orders',
                  '$totalOrders',
                  Icons.receipt,
                  Colors.purple,
                  'orders',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // KPI Cards Row 3 - Advanced KPIs
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Avg Order Value',
                  '₹${avgOrderValue.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.teal,
                  'per order',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKPICard(
                  'Customers',
                  '${topCustomers.length}',
                  Icons.people,
                  Colors.indigo,
                  'active',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sales Trend Chart - Line Chart using fl_chart
          Container(
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📈 Sales Trend (Last 7 Days)',
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
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${dailySales.values.isNotEmpty ? ((dailySales.values.last - dailySales.values.first) / (dailySales.values.first == 0 ? 1 : dailySales.values.first) * 100).toStringAsFixed(1) : 0}%',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Proper LineChart using fl_chart
                SizedBox(
                  height: 200,
                  child: dailySales.isEmpty
                      ? const Center(
                          child: Text(
                            'No sales data available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 1,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.2),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final entries = dailySales.entries.toList();
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < entries.length) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          entries[value.toInt()].key,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '₹${(value / 1000).toStringAsFixed(0)}K',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: (dailySales.length - 1).toDouble(),
                            minY: 0,
                            maxY: dailySales.values.isEmpty
                                ? 1
                                : dailySales.values.reduce(
                                        (a, b) => a > b ? a : b,
                                      ) *
                                      1.2,
                            lineBarsData: [
                              LineChartBarData(
                                spots: dailySales.entries
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      return FlSpot(
                                        entry.key.toDouble(),
                                        entry.value.value,
                                      );
                                    })
                                    .toList(),
                                isCurved: true,
                                gradient: const LinearGradient(
                                  colors: [accentTeal, Color(0xFF00D9C0)],
                                ),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 4,
                                          color: accentTeal,
                                          strokeWidth: 2,
                                          strokeColor: Colors.white,
                                        );
                                      },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      accentTeal.withOpacity(0.3),
                                      const Color(0xFF00D9C0).withOpacity(0.1),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((touchedSpot) {
                                    final entries = dailySales.entries.toList();
                                    return LineTooltipItem(
                                      '₹${touchedSpot.y.toStringAsFixed(0)}',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Two Column Layout: Top Products & Categories
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Products
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Top Products',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (topProducts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No data',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...topProducts
                            .take(5)
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.key,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${productQuantity[entry.key] ?? 0} sold',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${entry.value.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryBlue,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Top Categories
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.category, color: Colors.purple, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (topCategories.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No data',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...topCategories
                            .take(5)
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '₹${entry.value.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Payment Mode Distribution (Pie Chart representation)
          Container(
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.payment, color: Colors.teal, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Payment Mode Distribution',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                if (paymentModeSales.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No payment data',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: paymentModeSales.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getPaymentModeColor(
                            entry.key,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getPaymentModeColor(
                              entry.key,
                            ).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPaymentModeIcon(entry.key),
                              size: 16,
                              color: _getPaymentModeColor(entry.key),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getPaymentModeName(entry.key),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getPaymentModeColor(entry.key),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '₹${entry.value.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getPaymentModeColor(entry.key),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Order Status Distribution
          Container(
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Order Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                if (orderStatusCount.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No orders',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...orderStatusCount.entries.map((entry) {
                    final percentage = totalOrders > 0
                        ? (entry.value / totalOrders * 100)
                        : 0.0;
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
                                  Text(
                                    _getStatusName(entry.key),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
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
                  }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Top Customers
          Container(
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.people_alt, color: Colors.indigo, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Top Customers',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                if (topCustomers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No customer data',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...topCustomers.take(5).toList().asMap().entries.map((
                    mapEntry,
                  ) {
                    final index = mapEntry.key;
                    final entry = mapEntry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: index == 0
                            ? Colors.amber.withOpacity(0.1)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: index == 0
                            ? Border.all(color: Colors.amber.withOpacity(0.3))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? Colors.amber
                                  : primaryBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: index < 3
                                  ? Icon(
                                      Icons.emoji_events,
                                      size: 16,
                                      color: index == 0
                                          ? Colors.amber[800]
                                          : primaryBlue,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: primaryBlue,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (index == 0)
                                  const Text(
                                    '⭐ Top Customer',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.amber,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${entry.value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Time filter chip widget
  Widget _buildTimeFilterChip(String label, String value) {
    final isSelected = _analyticsTimeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _analyticsTimeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // KPI Card widget
  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    String badge, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to get payment mode name
  String _getPaymentModeName(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.cheque:
        return 'Cheque';
      case PaymentMode.chequeWithCash:
        return 'Cheque+Cash';
      case PaymentMode.bankTransfer:
        return 'Bank Transfer';
      case PaymentMode.credit:
        return 'Credit';
      case PaymentMode.partial:
        return 'Partial';
    }
  }

  // Helper method to get payment mode icon
  IconData _getPaymentModeIcon(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return Icons.money;
      case PaymentMode.upi:
        return Icons.phone_android;
      case PaymentMode.cheque:
        return Icons.description;
      case PaymentMode.chequeWithCash:
        return Icons.payments;
      case PaymentMode.bankTransfer:
        return Icons.account_balance;
      case PaymentMode.credit:
        return Icons.credit_card;
      case PaymentMode.partial:
        return Icons.pending;
    }
  }

  // Helper method to get status name
  String _getStatusName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.taken:
        return 'Taken';
      case OrderStatus.dispatched:
        return 'Dispatched';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Widget _buildAnalyticsCard(
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

  // ==================== CART DIALOG ====================
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
                      final qty = _cart[productId]!.quantity;
                      final product = _products.firstWhere(
                        (p) => p.id == productId,
                        orElse: () => ProductModel(
                          id: '',
                          name: 'Unknown',
                          category: '',
                          sku: '',
                          price: 0,
                          stock: 0,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
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
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${product.price.toStringAsFixed(0)} each',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () {
                                    removeFromCart(product.id);
                                    Navigator.pop(context);
                                    _showCartDialog();
                                  },
                                ),
                                Text(
                                  '$qty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () {
                                    addToCartById(product.id);
                                    Navigator.pop(context);
                                    _showCartDialog();
                                  },
                                ),
                              ],
                            ),
                            Text(
                              '₹${(product.price * qty).toStringAsFixed(0)}',
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
                if (_cart.isNotEmpty) ...[
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
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderPreview(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Preview - ${order.orderNumber}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text(
                      'Order Date: ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                    ),
                    Text('Customer: ${order.customerName}'),
                    Text('Area: ${order.areaName}'),
                    Text(
                      'Status: ${order.statusDisplay}',
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
                                Text('SKU: ${item.sku}'),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Qty: ${item.quantity}'),
                              Text('Rate: ₹${item.rate.toStringAsFixed(2)}'),
                              Text(
                                'Amount: ₹${item.amount.toStringAsFixed(2)}',
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Total: ₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
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
                    const Text('Due:', style: TextStyle(color: Colors.red)),
                    Text(
                      '₹${order.dueAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.red,
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
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
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
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share to WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
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

  // ==================== SIDEBAR ====================
  Widget _buildSidebarOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _isSidebarOpen = false),
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Stack(
          children: [
            Positioned(
              top: 155,
              left: 0,
              child: Container(
                width: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    _sidebarItem(0, Icons.dashboard, 'Dashboard', primaryBlue),
                    _sidebarItem(1, Icons.inventory_2, 'Products', accentTeal),
                    _sidebarItem(2, Icons.people_alt, 'Customers', Colors.blue),
                    _sidebarItem(
                      3,
                      Icons.add_shopping_cart,
                      'Create Order',
                      Colors.orange,
                    ),
                    _sidebarItem(
                      4,
                      Icons.receipt_long,
                      'My Orders',
                      Colors.purple,
                    ),
                    _sidebarItem(
                      5,
                      Icons.payment,
                      'Payment Collection',
                      Colors.green,
                    ),
                    _sidebarItem(6, Icons.copy, 'Templates', Colors.indigo),
                    _sidebarItem(7, Icons.analytics, 'Analytics', Colors.teal),
                    const Divider(),
                    _sidebarItem(
                      -1,
                      Icons.logout,
                      'Logout',
                      Colors.red,
                      onTap: _logout,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(
    int index,
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? color : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? color : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _isSidebarOpen = false;
        });
        if (onTap != null) onTap();
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _paymentAmountController.dispose();
    _referenceController.dispose();
    _visitNoteController.dispose();
    super.dispose();
  }

  // Screenshot state for payment proof
  String? _paymentScreenshotPath;

  // Build screenshot button for UPI payments
  Widget _buildScreenshotButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Screenshot (Optional)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (_paymentScreenshotPath != null) ...[
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(_paymentScreenshotPath!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _paymentScreenshotPath = null;
                });
              },
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Remove'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Show a placeholder message - in production, use image_picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Screenshot feature: In production, this would open camera/gallery',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  // For demo purposes, set a placeholder
                  setState(() {
                    _paymentScreenshotPath = 'assets/images/TotalSolution.png';
                  });
                },
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Attach Screenshot'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: const BorderSide(color: primaryBlue),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== ADD PRODUCT DIALOG ====================
  // Show dialog for adding product with quantity, rate, and scheme
  void _showAddProductDialog(ProductModel product) {
    // Check if product already exists in cart - if so, load existing values
    final existingCartItem = _cart[product.id];

    // Initialize with existing cart values or defaults
    final quantityController = TextEditingController(
      text: existingCartItem != null
          ? existingCartItem.quantity.toString()
          : '1',
    );
    final rateController = TextEditingController(
      text: existingCartItem != null
          ? existingCartItem.rate.toStringAsFixed(0)
          : product.price.toStringAsFixed(0),
    );
    final schPerController = TextEditingController(
      text: existingCartItem != null ? existingCartItem.schPer.toString() : '0',
    );
    final schAmtController = TextEditingController(
      text: existingCartItem != null ? existingCartItem.schAmt.toString() : '0',
    );

    int quantity = 1;
    double rate = product.price;
    double schPer = 0;
    double schAmt = 0;

    // Calculate gross amount
    double grossAmt = quantity * rate;
    // Calculate scheme amount from percentage
    double calculatedSchAmt = (schPer / 100) * grossAmt;
    // Net amount = gross - scheme
    double netAmt = grossAmt - calculatedSchAmt;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Update calculations whenever values change
          void updateCalculations() {
            quantity = int.tryParse(quantityController.text) ?? 1;
            if (quantity < 1) quantity = 1;

            rate = double.tryParse(rateController.text) ?? product.price;
            if (rate < 0) rate = 0;

            schPer = double.tryParse(schPerController.text) ?? 0;
            if (schPer < 0) schPer = 0;
            if (schPer > 100) schPer = 100;

            schAmt = double.tryParse(schAmtController.text) ?? 0;
            if (schAmt < 0) schAmt = 0;

            // Calculate gross amount
            grossAmt = quantity * rate;

            // If scheme percentage is entered, calculate scheme amount
            if (schPer > 0) {
              calculatedSchAmt = (schPer / 100) * grossAmt;
              schAmt = calculatedSchAmt;
            } else if (schAmt > 0 && grossAmt > 0) {
              // If scheme amount is entered, calculate percentage
              schPer = (schAmt / grossAmt) * 100;
            }

            // Net amount = gross - scheme
            netAmt = grossAmt - schAmt;
          }

          return AlertDialog(
            title: Text('Add ${product.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'SKU: ${product.sku}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Base Price: ₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quantity Field
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setDialogState(() {
                        updateCalculations();
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Rate Field
                  TextField(
                    controller: rateController,
                    decoration: const InputDecoration(
                      labelText: 'Rate (₹)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setDialogState(() {
                        updateCalculations();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Scheme Section (only if toggle is ON)
                  if (_showSchemeOptions) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.discount,
                                color: Colors.orange,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Scheme / Discount',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Scheme Percentage
                          TextField(
                            controller: schPerController,
                            decoration: const InputDecoration(
                              labelText: 'Scheme %',
                              border: OutlineInputBorder(),
                              suffixText: '%',
                              hintText: 'Enter percentage',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setDialogState(() {
                                schAmtController.text = '0';
                                updateCalculations();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Scheme Amount
                          TextField(
                            controller: schAmtController,
                            decoration: const InputDecoration(
                              labelText: 'Scheme Amount (₹)',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                              hintText: 'Enter amount',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setDialogState(() {
                                schPerController.text = '0';
                                updateCalculations();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Enable Scheme toggle to add discount/scheme',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Calculation Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accentTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildCalculationRow(
                          'Gross Amount',
                          '₹${grossAmt.toStringAsFixed(0)}',
                          isBold: true,
                        ),
                        if (_showSchemeOptions &&
                            (schPer > 0 || schAmt > 0)) ...[
                          const Divider(),
                          _buildCalculationRow(
                            'Scheme (${schPer.toStringAsFixed(1)}%)',
                            '-₹${schAmt.toStringAsFixed(0)}',
                            color: Colors.red,
                          ),
                        ],
                        const Divider(),
                        _buildCalculationRow(
                          'Net Amount',
                          '₹${netAmt.toStringAsFixed(0)}',
                          isBold: true,
                          color: accentTeal,
                        ),
                      ],
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
                onPressed: () {
                  // Add to cart with the entered values
                  addToCart(
                    product,
                    quantity: quantity,
                    rate: rate,
                    schPer: _showSchemeOptions ? schPer : 0,
                    schAmt: _showSchemeOptions ? schAmt : 0,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $quantity x ${product.name}'),
                      backgroundColor: accentTeal,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
                child: const Text('Add to Cart'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper widget for calculation display
  Widget _buildCalculationRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
