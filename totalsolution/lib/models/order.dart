// Order status enum
enum OrderStatus { pending, taken, dispatched, delivered, cancelled }

// Order type enum
enum OrderType { regular, scheduled, draft, urgent }

// Payment mode enum
enum PaymentMode {
  cash,
  upi,
  bankTransfer,
  credit,
  partial,
  cheque,
  chequeWithCash,
}

// UPI type enum for UPI payments
enum UpiType { gpay, phonepe, paytm, other }

// Order item model with enhanced features
class OrderItemModel {
  final String id;
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double rate;
  final double amount;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? unit; // kg, pcs, box, etc.
  final double? conversionRate; // for UOM conversion
  // Scheme/Discount fields
  final double schPer; // Scheme percentage
  final double schAmt; // Scheme amount
  final double grossAmt; // Gross amount before scheme
  final double netAmt; // Net amount after scheme

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.batchNumber,
    this.expiryDate,
    this.unit,
    this.conversionRate,
    this.schPer = 0,
    this.schAmt = 0,
    this.grossAmt = 0,
    this.netAmt = 0,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderItemModel(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      sku: map['sku'] ?? '',
      quantity: map['quantity'] ?? 0,
      rate: (map['rate'] ?? 0).toDouble(),
      amount: (map['amount'] ?? 0).toDouble(),
      batchNumber: map['batchNumber'],
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'])
          : null,
      unit: map['unit'],
      conversionRate: map['conversionRate']?.toDouble(),
      schPer: (map['schPer'] ?? 0).toDouble(),
      schAmt: (map['schAmt'] ?? 0).toDouble(),
      grossAmt: (map['grossAmt'] ?? 0).toDouble(),
      netAmt: (map['netAmt'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate?.toIso8601String(),
      'unit': unit,
      'conversionRate': conversionRate,
      'schPer': schPer,
      'schAmt': schAmt,
      'grossAmt': grossAmt,
      'netAmt': netAmt,
    };
  }

  OrderItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? sku,
    int? quantity,
    double? rate,
    double? amount,
    String? batchNumber,
    DateTime? expiryDate,
    String? unit,
    double? conversionRate,
    double? schPer,
    double? schAmt,
    double? grossAmt,
    double? netAmt,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      unit: unit ?? this.unit,
      conversionRate: conversionRate ?? this.conversionRate,
      schPer: schPer ?? this.schPer,
      schAmt: schAmt ?? this.schAmt,
      grossAmt: grossAmt ?? this.grossAmt,
      netAmt: netAmt ?? this.netAmt,
    );
  }
}

// Payment collection model
class PaymentCollectionModel {
  final String id;
  final String orderId;
  final double amount;
  final PaymentMode mode;
  final UpiType? upiType; // For UPI payments - gpay, phonepe, paytm, other
  final String? chequeNumber; // For Cheque payments
  final DateTime? chequeDate; // For Cheque payments
  final double? chequeAmount; // For Cheque/Cheque+Cash payments
  final double? cashAmount; // For Cheque+Cash payments
  final String? remark; // Remarks for any payment
  final String? referenceNumber;
  final String? transactionNumber; // For UPI payments - transaction ID
  final String? paymentScreenshot; // Screenshot of payment proof (UPI/Cheque)
  final String? notes;
  final DateTime collectedAt;
  final String collectedBy;

  PaymentCollectionModel({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.mode,
    this.upiType,
    this.chequeNumber,
    this.chequeDate,
    this.chequeAmount,
    this.cashAmount,
    this.remark,
    this.referenceNumber,
    this.transactionNumber,
    this.paymentScreenshot,
    this.notes,
    required this.collectedAt,
    required this.collectedBy,
  });

  factory PaymentCollectionModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentCollectionModel(
      id: id,
      orderId: map['orderId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      mode: _parsePaymentMode(map['mode']),
      upiType: map['upiType'] != null ? _parseUpiType(map['upiType']) : null,
      chequeNumber: map['chequeNumber'],
      chequeDate: map['chequeDate'] != null
          ? DateTime.parse(map['chequeDate'])
          : null,
      chequeAmount: map['chequeAmount']?.toDouble(),
      cashAmount: map['cashAmount']?.toDouble(),
      remark: map['remark'],
      referenceNumber: map['referenceNumber'],
      transactionNumber: map['transactionNumber'],
      paymentScreenshot: map['paymentScreenshot'],
      notes: map['notes'],
      collectedAt: map['collectedAt'] != null
          ? DateTime.parse(map['collectedAt'])
          : DateTime.now(),
      collectedBy: map['collectedBy'] ?? '',
    );
  }

  static PaymentMode _parsePaymentMode(String? mode) {
    switch (mode) {
      case 'cash':
        return PaymentMode.cash;
      case 'upi':
        return PaymentMode.upi;
      case 'bankTransfer':
        return PaymentMode.bankTransfer;
      case 'credit':
        return PaymentMode.credit;
      case 'partial':
        return PaymentMode.partial;
      case 'cheque':
        return PaymentMode.cheque;
      case 'chequeWithCash':
        return PaymentMode.chequeWithCash;
      default:
        return PaymentMode.cash;
    }
  }

  static UpiType? _parseUpiType(String? type) {
    switch (type) {
      case 'gpay':
        return UpiType.gpay;
      case 'phonepe':
        return UpiType.phonepe;
      case 'paytm':
        return UpiType.paytm;
      case 'other':
        return UpiType.other;
      default:
        return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'amount': amount,
      'mode': mode.name,
      'upiType': upiType?.name,
      'chequeNumber': chequeNumber,
      'chequeDate': chequeDate?.toIso8601String(),
      'chequeAmount': chequeAmount,
      'cashAmount': cashAmount,
      'remark': remark,
      'referenceNumber': referenceNumber,
      'transactionNumber': transactionNumber,
      'paymentScreenshot': paymentScreenshot,
      'notes': notes,
      'collectedAt': collectedAt.toIso8601String(),
      'collectedBy': collectedBy,
    };
  }

  String get paymentModeDisplay {
    switch (mode) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        String upiName = '';
        if (upiType != null) {
          switch (upiType!) {
            case UpiType.gpay:
              upiName = ' (GPay)';
              break;
            case UpiType.phonepe:
              upiName = ' (PhonePe)';
              break;
            case UpiType.paytm:
              upiName = ' (Paytm)';
              break;
            case UpiType.other:
              upiName = ' (Other)';
              break;
          }
        }
        return 'UPI$upiName';
      case PaymentMode.bankTransfer:
        return 'Bank Transfer';
      case PaymentMode.credit:
        return 'Credit';
      case PaymentMode.partial:
        return 'Partial Payment';
      case PaymentMode.cheque:
        return 'Cheque';
      case PaymentMode.chequeWithCash:
        return 'Cheque + Cash';
    }
  }

  String get paymentDetails {
    switch (mode) {
      case PaymentMode.cheque:
      case PaymentMode.chequeWithCash:
        String details = '';
        if (chequeNumber != null && chequeNumber!.isNotEmpty) {
          details = 'Cheque No: $chequeNumber';
          if (chequeDate != null) {
            details +=
                ', Date: ${chequeDate!.day}/${chequeDate!.month}/${chequeDate!.year}';
          }
          if (chequeAmount != null) {
            details += ', Amount: ₹${chequeAmount!.toStringAsFixed(0)}';
          }
        }
        if (mode == PaymentMode.chequeWithCash && cashAmount != null) {
          if (details.isNotEmpty) details += '\n';
          details += 'Cash: ₹${cashAmount!.toStringAsFixed(0)}';
        }
        return details;
      default:
        return '';
    }
  }
}

// Order timeline event model
class OrderTimelineEvent {
  final String id;
  final String status;
  final String message;
  final DateTime timestamp;
  final String? location;
  final String? performedBy;

  OrderTimelineEvent({
    required this.id,
    required this.status,
    required this.message,
    required this.timestamp,
    this.location,
    this.performedBy,
  });

  factory OrderTimelineEvent.fromMap(Map<String, dynamic> map, String id) {
    return OrderTimelineEvent(
      id: id,
      status: map['status'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      location: map['location'],
      performedBy: map['performedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'performedBy': performedBy,
    };
  }
}

// Order model with enhanced features
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
  final double? paymentReference;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final List<OrderTimelineEvent> timeline;
  final List<PaymentCollectionModel> payments;
  final String? deliverySignature;
  final String? deliveryImage;
  final String? notes;
  final String? internalNotes;
  final bool isTemplate;
  final String? templateName;
  final double? latitude;
  final double? longitude;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.areaName,
    this.routeName = '',
    required this.salesmanId,
    required this.salesmanName,
    required this.items,
    required this.totalAmount,
    this.paidAmount = 0,
    this.dueAmount = 0,
    required this.status,
    this.orderType = OrderType.regular,
    this.paymentMode,
    this.paymentReference,
    required this.createdAt,
    this.scheduledDate,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
    this.timeline = const [],
    this.payments = const [],
    this.deliverySignature,
    this.deliveryImage,
    this.notes,
    this.internalNotes,
    this.isTemplate = false,
    this.templateName,
    this.latitude,
    this.longitude,
  });

  factory OrderModel.fromMap(
    Map<String, dynamic> map,
    String id,
    List<OrderItemModel> items,
    List<OrderTimelineEvent> timeline,
    List<PaymentCollectionModel> payments,
  ) {
    return OrderModel(
      id: id,
      orderNumber: map['orderNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      areaName: map['areaName'] ?? '',
      routeName: map['routeName'] ?? '',
      salesmanId: map['salesmanId'] ?? '',
      salesmanName: map['salesmanName'] ?? '',
      items: items,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      dueAmount: (map['dueAmount'] ?? 0).toDouble(),
      status: _parseStatus(map['status']),
      orderType: _parseOrderType(map['orderType']),
      paymentMode: map['paymentMode'] != null
          ? _parsePaymentMode(map['paymentMode'])
          : null,
      paymentReference: map['paymentReference']?.toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      scheduledDate: map['scheduledDate'] != null
          ? DateTime.parse(map['scheduledDate'])
          : null,
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.parse(map['deliveredAt'])
          : null,
      cancelledAt: map['cancelledAt'] != null
          ? DateTime.parse(map['cancelledAt'])
          : null,
      cancellationReason: map['cancellationReason'],
      timeline: timeline,
      payments: payments,
      deliverySignature: map['deliverySignature'],
      deliveryImage: map['deliveryImage'],
      notes: map['notes'],
      internalNotes: map['internalNotes'],
      isTemplate: map['isTemplate'] ?? false,
      templateName: map['templateName'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  static OrderStatus _parseStatus(String? status) {
    switch (status) {
      case 'taken':
        return OrderStatus.taken;
      case 'dispatched':
        return OrderStatus.dispatched;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  static OrderType _parseOrderType(String? type) {
    switch (type) {
      case 'scheduled':
        return OrderType.scheduled;
      case 'draft':
        return OrderType.draft;
      case 'urgent':
        return OrderType.urgent;
      default:
        return OrderType.regular;
    }
  }

  static PaymentMode _parsePaymentMode(String? mode) {
    switch (mode) {
      case 'cash':
        return PaymentMode.cash;
      case 'upi':
        return PaymentMode.upi;
      case 'bankTransfer':
        return PaymentMode.bankTransfer;
      case 'credit':
        return PaymentMode.credit;
      case 'partial':
        return PaymentMode.partial;
      default:
        return PaymentMode.cash;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'areaName': areaName,
      'routeName': routeName,
      'salesmanId': salesmanId,
      'salesmanName': salesmanName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'dueAmount': dueAmount,
      'status': status.name,
      'orderType': orderType.name,
      'paymentMode': paymentMode?.name,
      'paymentReference': paymentReference,
      'createdAt': createdAt.toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'timeline': timeline.map((e) => e.toMap()).toList(),
      'payments': payments.map((p) => p.toMap()).toList(),
      'deliverySignature': deliverySignature,
      'deliveryImage': deliveryImage,
      'notes': notes,
      'internalNotes': internalNotes,
      'isTemplate': isTemplate,
      'templateName': templateName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? areaName,
    String? routeName,
    String? salesmanId,
    String? salesmanName,
    List<OrderItemModel>? items,
    double? totalAmount,
    double? paidAmount,
    double? dueAmount,
    OrderStatus? status,
    OrderType? orderType,
    PaymentMode? paymentMode,
    double? paymentReference,
    DateTime? createdAt,
    DateTime? scheduledDate,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    List<OrderTimelineEvent>? timeline,
    List<PaymentCollectionModel>? payments,
    String? deliverySignature,
    String? deliveryImage,
    String? notes,
    String? internalNotes,
    bool? isTemplate,
    String? templateName,
    double? latitude,
    double? longitude,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      areaName: areaName ?? this.areaName,
      routeName: routeName ?? this.routeName,
      salesmanId: salesmanId ?? this.salesmanId,
      salesmanName: salesmanName ?? this.salesmanName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      status: status ?? this.status,
      orderType: orderType ?? this.orderType,
      paymentMode: paymentMode ?? this.paymentMode,
      paymentReference: paymentReference ?? this.paymentReference,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      timeline: timeline ?? this.timeline,
      payments: payments ?? this.payments,
      deliverySignature: deliverySignature ?? this.deliverySignature,
      deliveryImage: deliveryImage ?? this.deliveryImage,
      notes: notes ?? this.notes,
      internalNotes: internalNotes ?? this.internalNotes,
      isTemplate: isTemplate ?? this.isTemplate,
      templateName: templateName ?? this.templateName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

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

  String get orderTypeDisplay {
    switch (orderType) {
      case OrderType.regular:
        return 'Regular';
      case OrderType.scheduled:
        return 'Scheduled';
      case OrderType.draft:
        return 'Draft';
      case OrderType.urgent:
        return 'Urgent';
    }
  }

  bool get isPaid => dueAmount <= 0;
  bool get hasDue => dueAmount > 0;
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  int get uniqueItemCount => items.length;
}

// Order template model
class OrderTemplateModel {
  final String id;
  final String name;
  final String salesmanId;
  final List<OrderItemModel> items;
  final double estimatedAmount;
  final DateTime createdAt;

  OrderTemplateModel({
    required this.id,
    required this.name,
    required this.salesmanId,
    required this.items,
    required this.estimatedAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'salesmanId': salesmanId,
      'items': items.map((item) => item.toMap()).toList(),
      'estimatedAmount': estimatedAmount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OrderTemplateModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderTemplateModel(
      id: id,
      name: map['name'] ?? '',
      salesmanId: map['salesmanId'] ?? '',
      items:
          (map['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromMap(e, e['id'] ?? ''))
              .toList() ??
          [],
      estimatedAmount: (map['estimatedAmount'] ?? 0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
