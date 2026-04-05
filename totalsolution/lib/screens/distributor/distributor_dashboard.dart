import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../auth/login_screen.dart';

class DistributorDashboard extends StatefulWidget {
  const DistributorDashboard({super.key});

  @override
  State<DistributorDashboard> createState() => _DistributorDashboardState();
}

class _DistributorDashboardState extends State<DistributorDashboard> {
  // Color constants
  static const Color primaryBlue = Color(0xFF1A3B70);
  static const Color accentTeal = Color(0xFF00A68A);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53935);
  static const Color cardPurple = Color(0xFF9B59B6);

  int _selectedIndex = 0;
  bool _isSidebarOpen = false;

  // Services
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();

  // Data
  List<CustomerModel> _customers = [];
  List<ProductModel> _products = [];
  List<OrderModel> _orders = [];
  List<UserModel> _salesmen = [];
  bool _isLoading = true;

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
      _orderService.getOrders(),
    ]);
    setState(() {
      _customers = results[0] as List<CustomerModel>;
      _products = results[1] as List<ProductModel>;
      _orders = results[2] as List<OrderModel>;
      _salesmen = [
        UserModel(
          id: '1',
          email: 'john@demo.com',
          name: 'John Salesman',
          phone: '+91 9876543211',
          role: UserRole.salesman,
          createdAt: DateTime.now(),
          isActive: true,
        ),
        UserModel(
          id: '2',
          email: 'raj@demo.com',
          name: 'Raj Sharma',
          phone: '+91 9876543212',
          role: UserRole.salesman,
          createdAt: DateTime.now(),
          isActive: true,
        ),
        UserModel(
          id: '3',
          email: 'amit@demo.com',
          name: 'Amit Patel',
          phone: '+91 9876543213',
          role: UserRole.salesman,
          createdAt: DateTime.now(),
          isActive: true,
        ),
        UserModel(
          id: '4',
          email: 'vikram@demo.com',
          name: 'Vikram Singh',
          phone: '+91 9876543214',
          role: UserRole.salesman,
          createdAt: DateTime.now(),
          isActive: false,
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _customerService.getCustomers(),
      _productService.getProducts(),
      _orderService.getOrders(),
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
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ==================== CUSTOMER METHODS ====================
  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final areaController = TextEditingController();
    final addressController = TextEditingController();
    final routeController = TextEditingController();

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
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: areaController,
                decoration: const InputDecoration(
                  labelText: 'Area *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: routeController,
                decoration: const InputDecoration(
                  labelText: 'Route',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.route),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
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
            onPressed: () async {
              if (nameController.text.isEmpty || areaController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill required fields'),
                    backgroundColor: errorRed,
                  ),
                );
                return;
              }

              final newCustomer = CustomerModel(
                id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                mobile: phoneController.text.trim(),
                address: addressController.text.trim(),
                area: areaController.text.trim(),
                route: routeController.text.trim(),
                salesmanId: 'salesman_001',
                company: 'Total Solution',
                outstanding: 0.0,
                lastVisit: 'Today',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await _customerService.addCustomer(newCustomer);
              await _refreshData();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Customer added successfully!'),
                    backgroundColor: successGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
            child: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }

  // ==================== PRODUCT METHODS ====================
  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();

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
                  prefixIcon: Icon(Icons.inventory_2),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (₹) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
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
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  skuController.text.isEmpty ||
                  categoryController.text.isEmpty ||
                  priceController.text.isEmpty ||
                  stockController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                    backgroundColor: errorRed,
                  ),
                );
                return;
              }

              final newProduct = ProductModel(
                id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                sku: skuController.text.trim(),
                category: categoryController.text.trim(),
                price: double.tryParse(priceController.text) ?? 0.0,
                stock: int.tryParse(stockController.text) ?? 0,
                description: descriptionController.text.trim(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await _productService.addProduct(newProduct);
              await _refreshData();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Product added successfully!'),
                    backgroundColor: successGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
            child: const Text('Add Product'),
          ),
        ],
      ),
    );
  }

  // ==================== SALESMAN METHODS ====================
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
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
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
              if (nameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                    backgroundColor: errorRed,
                  ),
                );
                return;
              }

              // Add to local list (in production, would call API)
              final newSalesman = UserModel(
                id: '${DateTime.now().millisecondsSinceEpoch}',
                email: emailController.text.trim(),
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                role: UserRole.salesman,
                createdAt: DateTime.now(),
                isActive: true,
              );

              setState(() {
                _salesmen.add(newSalesman);
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Salesman added successfully!'),
                  backgroundColor: successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
            child: const Text('Add Salesman'),
          ),
        ],
      ),
    );
  }

  // ==================== ORDER METHODS ====================
  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showOrderDetailsDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: _getStatusColor(order.status)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                order.orderNumber,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Date: ${_formatDateTime(order.createdAt)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Text('Customer: ${order.customerName}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Text('Area: ${order.areaName}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.badge, size: 16, color: primaryBlue),
                          const SizedBox(width: 8),
                          Text('Salesman: ${order.salesmanName}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Status Section
                const Text(
                  'Order Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _buildStatusTimeline(order),
                const SizedBox(height: 16),

                // Items Section
                const Text(
                  'Order Items',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                ...order.items.map(
                  (item) => Container(
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
                            Text('₹${item.rate.toStringAsFixed(0)} each'),
                            Text(
                              '₹${item.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: accentTeal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showUpdateStatusDialog(order);
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
              child: const Text('Update Status'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(OrderModel order) {
    final statuses = [
      OrderStatus.pending,
      OrderStatus.taken,
      OrderStatus.dispatched,
      OrderStatus.delivered,
    ];

    final currentIndex = statuses.indexOf(order.status);

    // Handle cancelled status
    if (order.status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: errorRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: errorRed),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: errorRed),
            const SizedBox(width: 8),
            Text(
              'Order Cancelled',
              style: TextStyle(color: errorRed, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Row(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Expanded(
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? _getStatusColor(status)
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getStatusLabel(status),
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrent ? _getStatusColor(status) : Colors.grey,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getStatusLabel(OrderStatus status) {
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

  void _showUpdateStatusDialog(OrderModel order) {
    OrderStatus? selectedStatus = order.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Order Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order: ${order.orderNumber}'),
              const SizedBox(height: 16),
              const Text(
                'Select new status:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...[
                OrderStatus.pending,
                OrderStatus.taken,
                OrderStatus.dispatched,
                OrderStatus.delivered,
              ].map((status) {
                final isCurrentStatus = status == order.status;
                final isNextStatus = status.index == order.status.index + 1;

                return RadioListTile<OrderStatus>(
                  title: Text(_getStatusLabel(status)),
                  value: status,
                  groupValue: selectedStatus,
                  activeColor: _getStatusColor(status),
                  onChanged: (value) {
                    setDialogState(() => selectedStatus = value);
                  },
                  subtitle: isCurrentStatus
                      ? const Text(
                          'Current status',
                          style: TextStyle(color: Colors.green),
                        )
                      : isNextStatus
                      ? const Text(
                          'Next step',
                          style: TextStyle(color: Colors.blue),
                        )
                      : null,
                );
              }),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.cancel, color: errorRed),
                title: const Text('Cancel Order'),
                onTap: () {
                  setDialogState(() => selectedStatus = OrderStatus.cancelled);
                },
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
                if (selectedStatus == null || selectedStatus == order.status) {
                  return;
                }

                await _orderService.updateOrderStatus(
                  order.id,
                  selectedStatus!,
                );
                await _refreshData();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ Order status updated to ${_getStatusLabel(selectedStatus!)}!',
                      ),
                      backgroundColor: successGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
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
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.person, color: primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distributor Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Total Solution',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
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
              const Expanded(
                child: Text(
                  'Management System',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _refreshData,
                tooltip: 'Refresh Data',
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
        return _buildOverviewSection();
      case 1:
        return _buildCustomersSection();
      case 2:
        return _buildProductsSection();
      case 3:
        return _buildSalesmenSection();
      case 4:
        return _buildOrdersSection();
      default:
        return _buildOverviewSection();
    }
  }

  // OVERVIEW SECTION
  Widget _buildOverviewSection() {
    final totalRevenue = _orders
        .where((o) => o.status == OrderStatus.delivered)
        .fold<double>(0, (sum, o) => sum + o.totalAmount);
    final pendingOrders = _orders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final todayOrders = _orderService.todayOrders;

    return RefreshIndicator(
      onRefresh: _refreshData,
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
                        const Text(
                          "Today's Orders",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          '$todayOrders',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: accentTeal,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Customers',
                    _customers.length.toString(),
                    Icons.people,
                    cardPurple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Products',
                    _products.length.toString(),
                    Icons.inventory_2,
                    accentTeal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Salesmen',
                    _salesmen.length.toString(),
                    Icons.badge,
                    goldAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Revenue & Orders Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Revenue',
                    '₹${(totalRevenue / 1000).toStringAsFixed(1)}K',
                    Icons.currency_rupee,
                    successGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Pending Orders',
                    pendingOrders.toString(),
                    Icons.pending_actions,
                    warningOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Orders
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
            const SizedBox(height: 12),
            ..._orders.take(5).map((order) => _buildOrderCard(order)),
          ],
        ),
      ),
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

  // CUSTOMERS SECTION
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
              ElevatedButton.icon(
                onPressed: _showAddCustomerDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
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
                      Text(
                        'No customers yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Tap "Add" to add a customer',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryBlue.withOpacity(0.1),
                          child: const Icon(Icons.person, color: primaryBlue),
                        ),
                        title: Text(
                          customer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Area: ${customer.area}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${customer.outstanding.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: customer.outstanding > 0
                                    ? errorRed
                                    : successGreen,
                              ),
                            ),
                            const Text(
                              'Outstanding',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
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
    );
  }

  // PRODUCTS SECTION
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
              ElevatedButton.icon(
                onPressed: _showAddProductDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
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
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No products yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Tap "Add" to add a product',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: primaryBlue,
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('SKU: ${product.sku}'),
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
                            Text(
                              'Stock: ${product.stock}',
                              style: TextStyle(
                                fontSize: 10,
                                color: product.stock < 10
                                    ? errorRed
                                    : Colors.grey,
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
    );
  }

  // SALESMEN SECTION
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
              ElevatedButton.icon(
                onPressed: _showAddSalesmanDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(backgroundColor: accentTeal),
              ),
            ],
          ),
        ),
        Expanded(
          child: _salesmen.isEmpty
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
                      SizedBox(height: 5),
                      Text(
                        'Tap "Add" to add a salesman',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _salesmen.length,
                  itemBuilder: (context, index) {
                    final salesman = _salesmen[index];
                    final salesmanOrders = _orders
                        .where((o) => o.salesmanId == salesman.id)
                        .length;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
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
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: salesman.isActive
                                    ? successGreen.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                salesman.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: salesman.isActive
                                      ? successGreen
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$salesmanOrders orders',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
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
    );
  }

  // ORDERS SECTION
  Widget _buildOrdersSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
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
                  '${_orders.length} Orders',
                  style: const TextStyle(
                    color: cardPurple,
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
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
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
    return GestureDetector(
      onTap: () => _showOrderDetailsDialog(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
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
          subtitle: Text('Customer: ${order.customerName}'),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                    _sidebarItem(1, Icons.people_alt, 'Customers', cardPurple),
                    _sidebarItem(2, Icons.inventory_2, 'Products', accentTeal),
                    _sidebarItem(3, Icons.badge, 'Salesmen', goldAccent),
                    _sidebarItem(
                      4,
                      Icons.shopping_cart,
                      'Orders',
                      warningOrange,
                    ),
                    const Divider(),
                    _sidebarItem(
                      -1,
                      Icons.logout,
                      'Logout',
                      errorRed,
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
}
