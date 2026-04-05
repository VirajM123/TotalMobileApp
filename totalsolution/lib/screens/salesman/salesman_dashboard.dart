import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../auth/login_screen.dart';

class SalesmanDashboard extends StatefulWidget {
  const SalesmanDashboard({super.key});

  @override
  State<SalesmanDashboard> createState() => _SalesmanDashboardState();
}

class _SalesmanDashboardState extends State<SalesmanDashboard> {
  // Color constants - matching existing design
  static const Color primaryBlue = Color(0xFF1A3B70);
  static const Color accentTeal = Color(0xFF00A68A);
  static const Color secondaryBlue = Color(0xFF2C599D);

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
  bool _isLoading = true;

  // Cart for order - using CartItemData to support qty, rate, scheme
  final Map<String, CartItemData> _cart = {};

  // Order creation state
  int _orderStep =
      1; // 1 = Select Customer, 2 = Select Products, 3 = Review & Submit
  String? _selectedCustomerId;
  String? _editingOrderId; // Track if editing existing order

  // Search controllers
  final TextEditingController _customerSearchController =
      TextEditingController();
  final TextEditingController _productSearchController =
      TextEditingController();
  String _customerSearchQuery = '';
  String _productSearchQuery = '';

  // Monthly target
  double _monthlyTarget = 100000; // ₹1 Lakh target

  // Payment collection controllers
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

  // Filtered lists based on search
  List<CustomerModel> get filteredCustomers {
    if (_customerSearchQuery.isEmpty) return _customers;
    final query = _customerSearchQuery.toLowerCase();
    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
          customer.area.toLowerCase().contains(query) ||
          (customer.phone?.toLowerCase().contains(query) ?? false) ||
          (customer.mobile?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<ProductModel> get filteredProducts {
    if (_productSearchQuery.isEmpty) return _products;
    final query = _productSearchQuery.toLowerCase();
    return _products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query);
    }).toList();
  }

  // Get last order for a customer
  OrderModel? getLastOrderForCustomer(String customerId) {
    try {
      final customerOrders = _orders
          .where((o) => o.customerId == customerId)
          .toList();
      if (customerOrders.isEmpty) return null;
      customerOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return customerOrders.first;
    } catch (e) {
      return null;
    }
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

  // Add product to cart with default qty 1 and product price as rate
  // Fixed: If product already exists in cart, just increment quantity instead of overwriting
  void addToCart(String productId) {
    final product = _products.firstWhere((p) => p.id == productId);
    setState(() {
      if (_cart.containsKey(productId)) {
        // Product already in cart - just increment quantity
        _cart[productId]!.quantity += 1;
        _cart[productId]!.calculate();
      } else {
        // New product - create cart item with defaults
        _cart[productId] = CartItemData(
          productId: product.id,
          productName: product.name,
          sku: product.sku,
          quantity: 1,
          rate: product.price,
        );
        _cart[productId]!.calculate();
      }
    });
  }

  // Remove or decrease quantity from cart
  void removeFromCart(String productId) {
    setState(() {
      final cartItem = _cart[productId];
      if (cartItem == null) return;

      if (cartItem.quantity > 1) {
        cartItem.quantity -= 1;
        cartItem.calculate();
      } else {
        _cart.remove(productId);
      }
    });
  }

  // Update cart item with custom qty, rate, and scheme
  void updateCartItem(
    String productId, {
    int? quantity,
    double? rate,
    double? schPer,
  }) {
    setState(() {
      final cartItem = _cart[productId];
      if (cartItem == null) return;

      if (quantity != null) cartItem.quantity = quantity;
      if (rate != null) cartItem.rate = rate;
      if (schPer != null) cartItem.schPer = schPer;
      cartItem.calculate();
    });
  }

  // Show dialog to edit cart item (qty, rate, scheme)
  void _showEditCartItemDialog(String productId) {
    final cartItem = _cart[productId];
    if (cartItem == null) return;

    final product = _products.firstWhere((p) => p.id == productId);

    // FIXED: Use the current quantity from cart item (which should have the correct quantity from loadOrderToCart)
    // Initialize with current cart values, not defaults
    final qtyController = TextEditingController(
      text: cartItem.quantity.toString(),
    );
    final rateController = TextEditingController(
      text: cartItem.rate.toStringAsFixed(2),
    );
    final schPerController = TextEditingController(
      text: cartItem.schPer.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${product.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quantity
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Rate
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Rate (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Scheme Percentage
              TextField(
                controller: schPerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Scheme %',
                  suffixText: '%',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Live calculation preview
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
                      'Gross: ₹${(cartItem.grossAmt).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Scheme: -₹${(cartItem.schAmt).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      'Net: ₹${(cartItem.netAmt).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
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
              final qty = int.tryParse(qtyController.text) ?? 1;
              final rate =
                  double.tryParse(rateController.text) ?? product.price;
              final schPer = double.tryParse(schPerController.text) ?? 0;

              updateCartItem(
                productId,
                quantity: qty,
                rate: rate,
                schPer: schPer,
              );

              Navigator.pop(context);
              // Refresh the dialog that called this
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
            child: const Text('Save'),
          ),
        ],
      ),
    );
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

  // Clear editing state and reset cart
  void clearEditingState() {
    setState(() {
      _editingOrderId = null;
      _cart.clear();
      _selectedCustomerId = null;
      _orderStep = 1;
    });
  }

  // Calculate cart total based on net amount (after scheme)
  double get cartTotal {
    double total = 0;
    _cart.forEach((productId, cartItem) {
      total += cartItem.netAmt;
    });
    return total;
  }

  // Get total quantity in cart
  int get cartItemCount {
    int count = 0;
    _cart.forEach((productId, cartItem) {
      count += cartItem.quantity;
    });
    return count;
  }

  // Get gross total (before scheme)
  double get cartGrossTotal {
    double total = 0;
    _cart.forEach((productId, cartItem) {
      total += cartItem.grossAmt;
    });
    return total;
  }

  // Get total scheme amount
  double get cartSchemeTotal {
    double total = 0;
    _cart.forEach((productId, cartItem) {
      total += cartItem.schAmt;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: NetworkImage('https://i.imgur.com/8pS6XpY.jpg'),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: Colors.white, width: 2),
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
              const Expanded(
                child: Text(
                  'Total Solution - Order Management',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
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

  // ==================== SALESMAN DASHBOARD ====================
  double get totalOrderAmount {
    return _orders.fold<double>(0, (sum, order) => sum + order.totalAmount);
  }

  double get achievementPercentage {
    if (_monthlyTarget == 0) return 0;
    return (totalOrderAmount / _monthlyTarget * 100).clamp(0, 100);
  }

  // Get monthly data for graph (last 6 months)
  List<Map<String, dynamic>> get monthlyData {
    final now = DateTime.now();
    final Map<String, double> monthlyTotals = {};

    // Initialize last 6 months with 0
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = '${date.month}/${date.year}';
      monthlyTotals[key] = 0;
    }

    // Sum up orders by month
    for (final order in _orders) {
      final key = '${order.createdAt.month}/${order.createdAt.year}';
      if (monthlyTotals.containsKey(key)) {
        monthlyTotals[key] = monthlyTotals[key]! + order.totalAmount;
      }
    }

    return monthlyTotals.entries
        .map((e) => {'month': e.key, 'amount': e.value})
        .toList();
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildSalesmanDashboard();
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
      default:
        return _buildSalesmanDashboard();
    }
  }

  // ==================== SALESMAN DASHBOARD ====================
  Widget _buildSalesmanDashboard() {
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
                        const SizedBox(height: 4),
                        Text(
                          'Salesman Portal',
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

            // TARGET VS ACHIEVEMENT
            _buildTargetVsAchievement(),
            const SizedBox(height: 20),

            // QUICK STATS
            _buildQuickStats(),
            const SizedBox(height: 20),

            // MONTHLY PERFORMANCE CHART
            _buildMonthlyPerformanceChart(),
            const SizedBox(height: 20),

            // RECENT ORDERS
            _buildRecentOrders(),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetVsAchievement() {
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                achievementPercentage >= 100 ? Colors.green : accentTeal,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target: ₹${(_monthlyTarget / 1000).toStringAsFixed(0)}K',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                'Achievement: ₹${(totalOrderAmount / 1000).toStringAsFixed(1)}K',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Overview',
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
              child: _buildStatCard(
                'Total Orders',
                _orders.length.toString(),
                Icons.shopping_bag,
                primaryBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'Total Amount',
                '₹${(totalOrderAmount / 1000).toStringAsFixed(1)}K',
                Icons.currency_rupee,
                accentTeal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Monthly Target',
                '₹${(_monthlyTarget / 1000).toStringAsFixed(0)}K',
                Icons.flag,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'Pending',
                _orders
                    .where((o) => o.status == OrderStatus.pending)
                    .length
                    .toString(),
                Icons.pending_actions,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
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

  Widget _buildMonthlyPerformanceChart() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Performance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthlyData.map((data) {
                final amount = data['amount'] as double;
                final maxAmount = monthlyData
                    .map((e) => e['amount'] as double)
                    .reduce((a, b) => a > b ? a : b);
                final height = maxAmount > 0 ? (amount / maxAmount * 100) : 0.0;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '₹${(amount / 1000).toStringAsFixed(1)}K',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: amount > 0 ? accentTeal : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['month'],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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
            (order) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                  ),
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
                        Text(
                          order.orderNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${order.customerName} • ${order.items.length} items',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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
            ),
          ),
      ],
    );
  }

  // PRODUCTS SECTION (Read-only for salesman)
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
                  '${_products.length} Items',
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
          child: ListView.builder(
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
    final cartItem = _cart[product.id];
    final inCart = cartItem?.quantity ?? 0;
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
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${product.sku} | Stock: ${product.stock}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                      onPressed: () => addToCart(product.id),
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
                onPressed: () => addToCart(product.id),
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

  // CUSTOMERS SECTION (Read-only for salesman)
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Read Only',
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _customers.length,
            itemBuilder: (context, index) {
              final customer = _customers[index];
              return _buildCustomerCard(customer);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
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
        trailing: const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
      ),
    );
  }

  // Show Cart Dialog
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
                    '🛒 Cart Items',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
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
                          'Your cart is empty',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Add products from Products tab',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final productId = _cart.keys.elementAt(index);
                      final cartItem = _cart[productId]!;
                      final product = _products.firstWhere(
                        (p) => p.id == productId,
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
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.inventory_2,
                                color: primaryBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
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
                            Container(
                              decoration: BoxDecoration(
                                color: accentTeal,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      removeFromCart(product.id);
                                      // Refresh the dialog
                                      Navigator.pop(context);
                                      _showCartDialog();
                                    },
                                    icon: const Icon(
                                      Icons.remove,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${cartItem.quantity}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      addToCart(product.id);
                                      // Refresh the dialog
                                      Navigator.pop(context);
                                      _showCartDialog();
                                    },
                                    icon: const Icon(
                                      Icons.add,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${cartItem.netAmt.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                                if (cartItem.schPer > 0)
                                  Text(
                                    '(-${cartItem.schPer.toStringAsFixed(0)}%)',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditCartItemDialog(product.id);
                              },
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: accentTeal,
                              ),
                              tooltip: 'Edit qty, rate, scheme',
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
                        // Navigate to Create Order tab (index 3)
                        setState(() {
                          _selectedIndex = 3;
                          _orderStep =
                              2; // Go directly to product selection step
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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

  // CREATE ORDER SECTION with steps
  Widget _buildCreateOrderSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Indicator
          _buildStepIndicator(),
          const SizedBox(height: 20),

          // Step 1: Customer Selection
          if (_orderStep == 1) _buildCustomerSelectionStep(),

          // Step 2: Product Selection
          if (_orderStep == 2) _buildProductSelectionStep(),

          // Step 3: Review & Submit
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
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

          // Customer Search Bar
          TextField(
            controller: _customerSearchController,
            onChanged: (value) {
              setState(() {
                _customerSearchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search customer by name, area, or phone...',
              prefixIcon: const Icon(Icons.search, color: primaryBlue),
              suffixIcon: _customerSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _customerSearchController.clear();
                        setState(() {
                          _customerSearchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_customers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No customers available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredCustomers.length,
              itemBuilder: (context, index) {
                final customer = filteredCustomers[index];
                final isSelected = _selectedCustomerId == customer.id;
                final lastOrder = getLastOrderForCustomer(customer.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCustomerId = customer.id;
                      _orderStep = 2;
                    });
                  },
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                      color: isSelected
                                          ? primaryBlue
                                          : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Area: ${customer.area}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (customer.phone != null)
                                    Text(
                                      'Phone: ${customer.phone}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: primaryBlue,
                              ),
                          ],
                        ),
                        // Show last order summary if exists
                        if (lastOrder != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.history,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Last Order: ₹${lastOrder.totalAmount.toStringAsFixed(0)} on ${lastOrder.createdAt.day}/${lastOrder.createdAt.month}/${lastOrder.createdAt.year}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          if (_cart.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _orderStep = 2);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentTeal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Continue with ${cartItemCount} items in cart →',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cart Summary Bar
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

        // Products List
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to add or remove products from cart',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Product Search Bar
              TextField(
                controller: _productSearchController,
                onChanged: (value) {
                  setState(() {
                    _productSearchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search products by name or SKU...',
                  prefixIcon: const Icon(Icons.search, color: primaryBlue),
                  suffixIcon: _productSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _productSearchController.clear();
                            setState(() {
                              _productSearchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final inCart = _cart[product.id]?.quantity ?? 0;
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
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                'SKU: ${product.sku} | Stock: ${product.stock}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                  fontSize: 15,
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
                                  onPressed: () => addToCart(product.id),
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
                          Column(
                            children: [
                              // Quick quantity buttons
                              Row(
                                children: [
                                  _buildQuickAddButton(product.id, 1),
                                  const SizedBox(width: 4),
                                  _buildQuickAddButton(product.id, 5),
                                  const SizedBox(width: 4),
                                  _buildQuickAddButton(product.id, 10),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ElevatedButton(
                                onPressed: () => addToCart(product.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(60, 28),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
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
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Navigation Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _orderStep = 1);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '← Back',
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _cart.isNotEmpty
                    ? () {
                        setState(() => _orderStep = 3);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentTeal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _cart.isEmpty ? 'Add items to continue' : 'Review Order →',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    if (_selectedCustomerId == null) {
      return const Center(child: Text('No customer selected'));
    }

    final selectedCustomer = _customers.firstWhere(
      (c) => c.id == _selectedCustomerId,
      orElse: () => _customers.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
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
                    selectedCustomer.name,
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
                    selectedCustomer.area,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
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
                final cartItem = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                            // Show custom rate if different from product price
                            if (cartItem.rate != product.price)
                              Text(
                                'Custom Rate: ₹${cartItem.rate.toStringAsFixed(2)} x ${cartItem.quantity}',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                ),
                              )
                            else
                              Text(
                                '₹${product.price.toStringAsFixed(0)} x ${cartItem.quantity}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            // Show scheme if applied
                            if (cartItem.schPer > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Scheme: -${cartItem.schPer.toStringAsFixed(0)}% (₹${cartItem.schAmt.toStringAsFixed(2)})',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${cartItem.netAmt.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              })),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
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
                onPressed: () {
                  setState(() => _orderStep = 2);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '← Edit Order',
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  // Submit the order
                  final order = OrderModel(
                    id: 'order_${DateTime.now().millisecondsSinceEpoch}',
                    orderNumber:
                        'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                    customerId: _selectedCustomerId!,
                    customerName: selectedCustomer.name,
                    customerPhone:
                        selectedCustomer.phone ?? selectedCustomer.mobile ?? '',
                    areaName: selectedCustomer.area,
                    salesmanId: _currentSalesman.id,
                    salesmanName: _currentSalesman.name,
                    items: _cart.entries.map((entry) {
                      final product = _products.firstWhere(
                        (p) => p.id == entry.key,
                      );
                      return OrderItemModel(
                        id: 'item_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
                        productId: product.id,
                        productName: product.name,
                        sku: product.sku,
                        quantity: entry.value.quantity,
                        rate: entry.value.rate,
                        amount: entry.value.rate * entry.value.quantity,
                        schPer: entry.value.schPer,
                        schAmt: entry.value.schAmt,
                        grossAmt: entry.value.grossAmt,
                        netAmt: entry.value.netAmt,
                      );
                    }).toList(),
                    totalAmount: cartTotal,
                    status: OrderStatus.pending,
                    createdAt: DateTime.now(),
                  );

                  // Check if we're editing an existing order
                  if (_editingOrderId != null) {
                    // Get the existing order to preserve some fields
                    final existingOrder = _orders.firstWhere(
                      (o) => o.id == _editingOrderId,
                    );

                    // Update existing order
                    final updatedOrder = OrderModel(
                      id: _editingOrderId!,
                      orderNumber: existingOrder.orderNumber,
                      customerId: _selectedCustomerId!,
                      customerName: selectedCustomer.name,
                      customerPhone:
                          selectedCustomer.phone ??
                          selectedCustomer.mobile ??
                          '',
                      areaName: selectedCustomer.area,
                      salesmanId: _currentSalesman.id,
                      salesmanName: _currentSalesman.name,
                      items: order.items,
                      totalAmount: cartTotal,
                      paidAmount: existingOrder.paidAmount,
                      dueAmount: cartTotal - existingOrder.paidAmount,
                      status: existingOrder.status,
                      createdAt: existingOrder.createdAt,
                    );

                    await _orderService.updateOrder(updatedOrder);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '✅ Order ${existingOrder.orderNumber} updated successfully!',
                          ),
                          backgroundColor: accentTeal,
                        ),
                      );
                    }
                  } else {
                    await _orderService.createOrder(order);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Order submitted successfully!'),
                          backgroundColor: accentTeal,
                        ),
                      );
                    }
                  }

                  if (mounted) {
                    setState(() {
                      _cart.clear();
                      _selectedCustomerId = null;
                      _editingOrderId = null; // Clear editing state
                      _orderStep = 1;
                      _selectedIndex = 4; // Go to orders tab
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentTeal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '✅ Submit Order',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ORDER HISTORY SECTION
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
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderCard(order);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.receipt_long,
                color: _getStatusColor(order.status),
              ),
            ),
            title: Text(
              order.orderNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${order.customerName}'),
                Text('Items: ${order.items.length}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order.statusDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => loadOrderToCart(order),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                ),
                TextButton.icon(
                  onPressed: () => _showOrderPreview(order),
                  icon: const Icon(Icons.preview, size: 16),
                  label: const Text('Preview'),
                  style: TextButton.styleFrom(foregroundColor: primaryBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
                      'Order Date: ${_formatDateTime(order.createdAt)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
              const SizedBox(height: 8),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                if (item.schPer != null && item.schPer! > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Scheme: -${item.schPer!.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
                                'Gross: ₹${item.grossAmt.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              if (item.schAmt != null && item.schAmt! > 0)
                                Text(
                                  'Scheme: -₹${item.schAmt!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
                                  ),
                                ),
                              Text(
                                'Net: ₹${item.netAmt.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
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
                    'Total Amount: ₹${order.totalAmount.toStringAsFixed(2)}',
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

  // SIDEBAR
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
          // Reset order flow when navigating to create order
          if (index == 2) {
            _orderStep = 1;
            _selectedCustomerId = null;
          }
        });
        if (onTap != null) onTap();
      },
    );
  }

  // Quick add button for adding multiple items at once
  Widget _buildQuickAddButton(String productId, int quantity) {
    return InkWell(
      onTap: () {
        final product = _products.firstWhere((p) => p.id == productId);
        setState(() {
          if (_cart.containsKey(productId)) {
            _cart[productId]!.quantity += quantity;
            _cart[productId]!.calculate();
          } else {
            _cart[productId] = CartItemData(
              productId: product.id,
              productName: product.name,
              sku: product.sku,
              quantity: quantity,
              rate: product.price,
            );
            _cart[productId]!.calculate();
          }
        });
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '+$quantity',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
      ),
    );
  }

  // ==================== PAYMENT COLLECTION SECTION ====================
  String _paymentType = 'UPI';
  String? _selectedOrderId;
  List<OrderModel> _pendingOrders = [];

  Widget _buildPaymentCollectionSection() {
    // Filter pending orders for payment collection
    _pendingOrders = _orders
        .where(
          (o) =>
              o.status == OrderStatus.pending ||
              o.status == OrderStatus.taken ||
              o.status == OrderStatus.dispatched,
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Color(0xFF00C853)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.payment, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Collection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_pendingOrders.length} pending payments',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Select Order
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
                const Text(
                  'Select Order for Payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 12),
                if (_pendingOrders.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 48,
                            color: Colors.green,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No pending payments!',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...List.generate(_pendingOrders.length, (index) {
                    final order = _pendingOrders[index];
                    final isSelected = _selectedOrderId == order.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedOrderId = order.id;
                          _paymentAmountController.text = order.totalAmount
                              .toStringAsFixed(0);
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? Colors.green
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.receipt,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.orderNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    order.customerName,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      order.status,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    order.statusDisplay,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getStatusColor(order.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Type Selection
          if (_selectedOrderId != null) ...[
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
                  const Text(
                    'Payment Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildPaymentTypeChip('UPI', Icons.qr_code),
                      _buildPaymentTypeChip('Cash', Icons.money),
                      _buildPaymentTypeChip('Cheque', Icons.description),
                      _buildPaymentTypeChip('Cheque+Cash', Icons.payments),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment Details based on type
            if (_paymentType == 'UPI') _buildUPIPaymentFields(),
            if (_paymentType == 'Cash') _buildCashPaymentFields(),
            if (_paymentType == 'Cheque') _buildChequePaymentFields(),
            if (_paymentType == 'Cheque+Cash') _buildChequeCashPaymentFields(),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentTypeChip(String type, IconData icon) {
    final isSelected = _paymentType == type;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
          const SizedBox(width: 4),
          Text(type),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _paymentType = type;
        });
      },
      selectedColor: Colors.green,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
      ),
    );
  }

  Widget _buildUPIPaymentFields() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UPI Payment Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _paymentAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _transactionNumberController,
            decoration: InputDecoration(
              labelText: 'Transaction / UPI Ref No.',
              hintText: 'Enter UPI transaction reference',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarkController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Remark (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _processPayment('UPI'),
              icon: const Icon(Icons.check),
              label: const Text('Confirm Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashPaymentFields() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cash Payment Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _paymentAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referenceController,
            decoration: InputDecoration(
              labelText: 'Receipt No.',
              hintText: 'Enter cash receipt number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarkController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Remark (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _processPayment('Cash'),
              icon: const Icon(Icons.check),
              label: const Text('Confirm Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChequePaymentFields() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cheque Payment Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _chequeNumberController,
            decoration: InputDecoration(
              labelText: 'Cheque Number',
              hintText: 'Enter cheque number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chequeDateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Cheque Date',
              hintText: 'Select cheque date',
              suffixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (date != null) {
                setState(() {
                  _chequeDateController.text =
                      '${date.day}/${date.month}/${date.year}';
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chequeAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cheque Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarkController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Remark (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _processPayment('Cheque'),
              icon: const Icon(Icons.check),
              label: const Text('Confirm Cheque Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChequeCashPaymentFields() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cheque + Cash Payment Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),

          // Cheque Details
          const Text(
            'Cheque Part',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _chequeNumberController,
            decoration: InputDecoration(
              labelText: 'Cheque Number',
              hintText: 'Enter cheque number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chequeDateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Cheque Date',
              hintText: 'Select cheque date',
              suffixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (date != null) {
                setState(() {
                  _chequeDateController.text =
                      '${date.day}/${date.month}/${date.year}';
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chequeAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cheque Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cash Details
          const Text(
            'Cash Part',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cashAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cash Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referenceController,
            decoration: InputDecoration(
              labelText: 'Cash Receipt No.',
              hintText: 'Enter cash receipt number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarkController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Remark (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _processPayment('Cheque+Cash'),
              icon: const Icon(Icons.check),
              label: const Text('Confirm Split Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(String paymentMethod) async {
    if (_selectedOrderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an order first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_paymentAmountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // For cheque and cheque+cash, validate cheque details
    if (paymentMethod == 'Cheque' || paymentMethod == 'Cheque+Cash') {
      if (_chequeNumberController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter cheque number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_chequeDateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select cheque date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Method: $paymentMethod'),
            const SizedBox(height: 8),
            Text('Amount: ₹${amount.toStringAsFixed(2)}'),
            if (paymentMethod == 'Cheque' ||
                paymentMethod == 'Cheque+Cash') ...[
              const SizedBox(height: 8),
              Text('Cheque No: ${_chequeNumberController.text}'),
              Text('Cheque Date: ${_chequeDateController.text}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Update order payment status
      final orderIndex = _orders.indexWhere((o) => o.id == _selectedOrderId);
      if (orderIndex != -1) {
        final order = _orders[orderIndex];

        // Create payment record
        final paymentData = {
          'orderId': _selectedOrderId,
          'paymentMethod': paymentMethod,
          'amount': amount,
          'reference': paymentMethod == 'UPI'
              ? _transactionNumberController.text
              : paymentMethod == 'Cash'
              ? _referenceController.text
              : _chequeNumberController.text,
          'chequeNumber': _chequeNumberController.text,
          'chequeDate': _chequeDateController.text,
          'chequeAmount': double.tryParse(_chequeAmountController.text) ?? 0,
          'cashAmount': double.tryParse(_cashAmountController.text) ?? 0,
          'remark': _remarkController.text,
          'collectedBy': _currentSalesman.name,
          'collectedAt': DateTime.now().toIso8601String(),
        };

        // Update order status to delivered if payment is complete
        final totalAmount = order.totalAmount;
        if (amount >= totalAmount) {
          await _orderService.updateOrderStatus(
            _selectedOrderId!,
            OrderStatus.delivered,
          );
        }

        // Clear form
        setState(() {
          _selectedOrderId = null;
          _paymentAmountController.clear();
          _referenceController.clear();
          _chequeNumberController.clear();
          _chequeDateController.clear();
          _chequeAmountController.clear();
          _cashAmountController.clear();
          _transactionNumberController.clear();
          _remarkController.clear();
          _paymentType = 'UPI';
        });

        // Refresh data
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Payment collected successfully! ($paymentMethod)',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }
}
