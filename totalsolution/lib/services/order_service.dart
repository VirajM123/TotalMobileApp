import 'package:flutter/material.dart';
import '../models/models.dart';

// Mock Order Service - Works without Firebase for immediate testing
class OrderService extends ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  OrderService() {
    _loadMockOrders();
  }

  void _loadMockOrders() {
    _orders = [
      OrderModel(
        id: 'order_001',
        orderNumber: 'ORD-2024-001',
        customerId: 'cust_001',
        customerName: 'Mohan Stores',
        customerPhone: '+91 9876543210',
        areaName: 'North Sector A',
        salesmanId: 'salesman_001',
        salesmanName: 'John Salesman',
        items: [
          OrderItemModel(
            id: 'item_001',
            productId: 'prod_001',
            productName: 'Crunchy Chips 100g',
            sku: 'CC122',
            quantity: 10,
            rate: 120.0,
            amount: 1200.0,
            schPer: 10.0,
            schAmt: 120.0,
            grossAmt: 1200.0,
            netAmt: 1080.0,
          ),
          OrderItemModel(
            id: 'item_002',
            productId: 'prod_002',
            productName: 'Cool Cola 500ml',
            sku: 'CL499',
            quantity: 20,
            rate: 45.0,
            amount: 900.0,
            schPer: 5.0,
            schAmt: 45.0,
            grossAmt: 900.0,
            netAmt: 855.0,
          ),
        ],
        totalAmount: 1935.0,
        paidAmount: 0,
        dueAmount: 2100.0,
        status: OrderStatus.pending,
        orderType: OrderType.regular,
        paymentMode: PaymentMode.credit,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        timeline: [
          OrderTimelineEvent(
            id: 'timeline_001',
            status: 'pending',
            message: 'Order created and pending',
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ],
      ),
      OrderModel(
        id: 'order_002',
        orderNumber: 'ORD-2024-002',
        customerId: 'cust_002',
        customerName: 'Sharma Supermarket',
        customerPhone: '+91 9876543211',
        areaName: 'South Sector B',
        salesmanId: 'salesman_001',
        salesmanName: 'John Salesman',
        items: [
          OrderItemModel(
            id: 'item_003',
            productId: 'prod_003',
            productName: 'Sweet Biscuits 200g',
            sku: 'CL179',
            quantity: 50,
            rate: 25.0,
            amount: 1250.0,
          ),
        ],
        totalAmount: 1250.0,
        paidAmount: 1250.0,
        dueAmount: 0,
        status: OrderStatus.delivered,
        orderType: OrderType.regular,
        paymentMode: PaymentMode.cash,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        deliveredAt: DateTime.now().subtract(const Duration(hours: 20)),
        timeline: [
          OrderTimelineEvent(
            id: 'timeline_002',
            status: 'pending',
            message: 'Order created',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
          ),
          OrderTimelineEvent(
            id: 'timeline_003',
            status: 'taken',
            message: 'Order taken by salesman',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
          ),
          OrderTimelineEvent(
            id: 'timeline_004',
            status: 'delivered',
            message: 'Order delivered successfully',
            timestamp: DateTime.now().subtract(const Duration(hours: 20)),
          ),
        ],
        payments: [
          PaymentCollectionModel(
            id: 'pay_001',
            orderId: 'order_002',
            amount: 1250.0,
            mode: PaymentMode.cash,
            collectedAt: DateTime.now().subtract(const Duration(hours: 20)),
            collectedBy: 'John Salesman',
          ),
        ],
      ),
      OrderModel(
        id: 'order_003',
        orderNumber: 'ORD-2024-003',
        customerId: 'cust_004',
        customerName: 'Patel Provisions',
        customerPhone: '+91 9876543212',
        areaName: 'West Sector D',
        salesmanId: 'salesman_001',
        salesmanName: 'John Salesman',
        items: [
          OrderItemModel(
            id: 'item_004',
            productId: 'prod_004',
            productName: 'Sunkist Shampoo 400ml',
            sku: 'SH401',
            quantity: 5,
            rate: 199.0,
            amount: 995.0,
          ),
          OrderItemModel(
            id: 'item_005',
            productId: 'prod_005',
            productName: 'Tropical Juice 1L',
            sku: 'TJ100',
            quantity: 10,
            rate: 89.0,
            amount: 890.0,
          ),
        ],
        totalAmount: 1885.0,
        paidAmount: 0,
        dueAmount: 1885.0,
        status: OrderStatus.cancelled,
        orderType: OrderType.regular,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        cancelledAt: DateTime.now().subtract(const Duration(days: 1)),
        cancellationReason: 'Customer requested cancellation',
      ),
      OrderModel(
        id: 'order_004',
        orderNumber: 'ORD-2024-004',
        customerId: 'cust_003',
        customerName: 'Gupta General Store',
        customerPhone: '+91 9876543213',
        areaName: 'East Sector C',
        salesmanId: 'salesman_001',
        salesmanName: 'John Salesman',
        items: [
          OrderItemModel(
            id: 'item_006',
            productId: 'prod_006',
            productName: 'Creamy Milk 1L',
            sku: 'DM100',
            quantity: 20,
            rate: 55.0,
            amount: 1100.0,
          ),
        ],
        totalAmount: 1100.0,
        paidAmount: 500.0,
        dueAmount: 600.0,
        status: OrderStatus.pending,
        orderType: OrderType.urgent,
        paymentMode: PaymentMode.partial,
        notes: 'Urgent order - deliver today',
        createdAt: DateTime.now(),
      ),
    ];
  }

  Future<List<OrderModel>> getOrders() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoading = false;
    notifyListeners();
    return _orders;
  }

  Future<List<OrderModel>> getOrdersBySalesman(String salesmanId) async {
    return _orders.where((o) => o.salesmanId == salesmanId).toList();
  }

  Future<List<OrderModel>> getOrdersByCustomer(String customerId) async {
    return _orders.where((o) => o.customerId == customerId).toList();
  }

  Future<OrderModel?> getOrderById(String id) async {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> createOrder(OrderModel order) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _orders.insert(0, order);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status, {
    String? cancellationReason,
  }) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      final newTimelineEvent = OrderTimelineEvent(
        id: 'timeline_${DateTime.now().millisecondsSinceEpoch}',
        status: status.name,
        message: _getStatusMessage(status),
        timestamp: DateTime.now(),
      );
      final updatedTimeline = [...order.timeline, newTimelineEvent];

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
        paidAmount: order.paidAmount,
        dueAmount: order.dueAmount,
        status: status,
        orderType: order.orderType,
        paymentMode: order.paymentMode,
        paymentReference: order.paymentReference,
        createdAt: order.createdAt,
        scheduledDate: order.scheduledDate,
        deliveredAt: status == OrderStatus.delivered
            ? DateTime.now()
            : order.deliveredAt,
        cancelledAt: status == OrderStatus.cancelled
            ? DateTime.now()
            : order.cancelledAt,
        cancellationReason: cancellationReason ?? order.cancellationReason,
        timeline: updatedTimeline,
        payments: order.payments,
        deliverySignature: order.deliverySignature,
        deliveryImage: order.deliveryImage,
        notes: order.notes,
        internalNotes: order.internalNotes,
        isTemplate: order.isTemplate,
        templateName: order.templateName,
        latitude: order.latitude,
        longitude: order.longitude,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  String _getStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Order pending for processing';
      case OrderStatus.taken:
        return 'Order taken and confirmed';
      case OrderStatus.dispatched:
        return 'Order dispatched for delivery';
      case OrderStatus.delivered:
        return 'Order delivered successfully';
      case OrderStatus.cancelled:
        return 'Order cancelled';
    }
  }

  // Payment collection with enhanced parameters
  Future<void> recordPayment(
    String orderId,
    double amount,
    PaymentMode mode, {
    String? reference,
    String? notes,
    UpiType? upiType,
    String? chequeNumber,
    DateTime? chequeDate,
    double? chequeAmount,
    double? cashAmount,
    String? remark,
    String? transactionNumber,
    String? paymentScreenshot,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      final newPayment = PaymentCollectionModel(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        orderId: orderId,
        amount: amount,
        mode: mode,
        referenceNumber: reference,
        notes: notes,
        collectedAt: DateTime.now(),
        collectedBy: order.salesmanName,
        upiType: upiType,
        chequeNumber: chequeNumber,
        chequeDate: chequeDate,
        chequeAmount: chequeAmount,
        cashAmount: cashAmount,
        remark: remark,
        transactionNumber: transactionNumber,
        paymentScreenshot: paymentScreenshot,
      );

      final updatedPayments = [...order.payments, newPayment];
      final newPaidAmount = order.paidAmount + amount;
      final double newDueAmount = (order.totalAmount - newPaidAmount)
          .toDouble()
          .clamp(0.0, double.infinity);

      _orders[index] = order.copyWith(
        paidAmount: newPaidAmount,
        dueAmount: newDueAmount,
        payments: updatedPayments,
      );
      notifyListeners();
    }
  }

  // Get all payments collected (for payment history)
  List<PaymentCollectionModel> getAllPayments() {
    return _orders.expand((o) => o.payments).toList()
      ..sort((a, b) => b.collectedAt.compareTo(a.collectedAt));
  }

  // Get payments by date range
  List<PaymentCollectionModel> getPaymentsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return getAllPayments()
        .where(
          (p) => p.collectedAt.isAfter(start) && p.collectedAt.isBefore(end),
        )
        .toList();
  }

  // Get today's payments
  List<PaymentCollectionModel> getTodaysPayments() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getPaymentsByDateRange(startOfDay, endOfDay);
  }

  // Get total collection for a date range
  double getTotalCollectionByDateRange(DateTime start, DateTime end) {
    return getPaymentsByDateRange(
      start,
      end,
    ).fold(0.0, (sum, p) => sum + p.amount);
  }

  // Order modification
  Future<void> modifyOrder(String orderId, OrderModel updatedOrder) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = updatedOrder;
      notifyListeners();
    }
  }

  // Update entire order (for editing orders) - FIX FOR ORDER EDIT
  Future<void> updateOrder(OrderModel updatedOrder) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _orders.indexWhere((o) => o.id == updatedOrder.id);
    if (index != -1) {
      _orders[index] = updatedOrder;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Cancel order with reason
  Future<void> cancelOrder(String orderId, String reason) async {
    await updateOrderStatus(
      orderId,
      OrderStatus.cancelled,
      cancellationReason: reason,
    );
  }

  // Get orders by status
  List<OrderModel> getOrdersByStatus(OrderStatus status) {
    return _orders.where((o) => o.status == status).toList();
  }

  // Get orders with due
  List<OrderModel> getOrdersWithDue() {
    return _orders.where((o) => o.dueAmount > 0).toList();
  }

  // Get pending payments collection
  double get totalPendingAmount {
    return _orders
        .where((o) => o.status != OrderStatus.cancelled)
        .fold(0.0, (sum, o) => sum + o.dueAmount);
  }

  // Get today collection
  double get todayCollection {
    final now = DateTime.now();
    return _orders
        .expand((o) => o.payments)
        .where(
          (p) =>
              p.collectedAt.year == now.year &&
              p.collectedAt.month == now.month &&
              p.collectedAt.day == now.day,
        )
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  // Get scheduled orders
  List<OrderModel> getScheduledOrders() {
    return _orders.where((o) => o.orderType == OrderType.scheduled).toList();
  }

  // Get draft orders
  List<OrderModel> getDraftOrders() {
    return _orders.where((o) => o.orderType == OrderType.draft).toList();
  }

  // Mark order as urgent
  Future<void> markOrderAsUrgent(String orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      _orders[index] = order.copyWith(orderType: OrderType.urgent);
      notifyListeners();
    }
  }

  // Schedule order for future date
  Future<void> scheduleOrder(String orderId, DateTime scheduledDate) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      _orders[index] = order.copyWith(
        orderType: OrderType.scheduled,
        scheduledDate: scheduledDate,
      );
      notifyListeners();
    }
  }

  // Get customer order history
  List<OrderModel> getCustomerOrderHistory(String customerId) {
    return _orders.where((o) => o.customerId == customerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Save as draft
  Future<void> saveAsDraft(OrderModel order) async {
    final draftOrder = order.copyWith(orderType: OrderType.draft);
    await createOrder(draftOrder);
  }

  // Create order from template
  Future<void> createFromTemplate(
    OrderTemplateModel template,
    String customerId,
    String customerName,
    String customerPhone,
    String areaName,
  ) async {
    final orderItems = template.items
        .map(
          (item) => OrderItemModel(
            id: 'item_${DateTime.now().millisecondsSinceEpoch}_${item.productId}',
            productId: item.productId,
            productName: item.productName,
            sku: item.sku,
            quantity: item.quantity,
            rate: item.rate,
            amount: item.amount,
            batchNumber: item.batchNumber,
            expiryDate: item.expiryDate,
            unit: item.unit,
            conversionRate: item.conversionRate,
          ),
        )
        .toList();

    final order = OrderModel(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: generateOrderNumber(),
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      areaName: areaName,
      salesmanId: template.salesmanId,
      salesmanName: 'John Salesman',
      items: orderItems,
      totalAmount: template.estimatedAmount,
      paidAmount: 0,
      dueAmount: template.estimatedAmount,
      status: OrderStatus.pending,
      orderType: OrderType.regular,
      createdAt: DateTime.now(),
    );

    await createOrder(order);
  }

  Future<void> deleteOrder(String id) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _orders.removeWhere((o) => o.id == id);
    _isLoading = false;
    notifyListeners();
  }

  // Statistics
  int get totalOrders => _orders.length;

  int get todayOrders {
    final now = DateTime.now();
    return _orders
        .where(
          (o) =>
              o.createdAt.year == now.year &&
              o.createdAt.month == now.month &&
              o.createdAt.day == now.day,
        )
        .length;
  }

  int get pendingOrders =>
      _orders.where((o) => o.status == OrderStatus.pending).length;

  int get deliveredOrders =>
      _orders.where((o) => o.status == OrderStatus.delivered).length;

  double get totalSales => _orders
      .where((o) => o.status != OrderStatus.cancelled)
      .fold(0.0, (sum, o) => sum + o.totalAmount);

  List<OrderModel> getTodaysOrders() {
    final now = DateTime.now();
    return _orders
        .where(
          (o) =>
              o.createdAt.year == now.year &&
              o.createdAt.month == now.month &&
              o.createdAt.day == now.day,
        )
        .toList();
  }

  String generateOrderNumber() {
    final now = DateTime.now();
    final count = _orders.length + 1;
    return 'ORD-${now.year}-${count.toString().padLeft(4, '0')}';
  }
}
