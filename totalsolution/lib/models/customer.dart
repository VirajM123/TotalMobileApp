// Customer model (Party in the existing app)
class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final String? mobile;
  final String? gstin;
  final String address;
  final String area;
  final String? route;
  final String? salesmanId;
  final String? company;
  final double outstanding;
  final String? lastVisit;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.mobile,
    this.gstin,
    required this.address,
    required this.area,
    this.route,
    this.salesmanId,
    this.company,
    this.outstanding = 0,
    this.lastVisit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map, String id) {
    return CustomerModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'],
      mobile: map['mobile'],
      gstin: map['gstin'],
      address: map['address'] ?? '',
      area: map['area'] ?? '',
      route: map['route'],
      salesmanId: map['salesmanId'],
      company: map['company'],
      outstanding: (map['outstanding'] ?? 0).toDouble(),
      lastVisit: map['lastVisit'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'mobile': mobile,
      'gstin': gstin,
      'address': address,
      'area': area,
      'route': route,
      'salesmanId': salesmanId,
      'company': company,
      'outstanding': outstanding,
      'lastVisit': lastVisit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? mobile,
    String? gstin,
    String? address,
    String? area,
    String? route,
    String? salesmanId,
    String? company,
    double? outstanding,
    String? lastVisit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
      area: area ?? this.area,
      route: route ?? this.route,
      salesmanId: salesmanId ?? this.salesmanId,
      company: company ?? this.company,
      outstanding: outstanding ?? this.outstanding,
      lastVisit: lastVisit ?? this.lastVisit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
