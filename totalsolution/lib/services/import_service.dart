import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';

class ImportService {
  /// Pick and parse a CSV file for products
  static Future<List<ProductModel>?> importProductsFromCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      if (file.bytes == null) return null;

      final csvString = utf8.decode(file.bytes!);
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

      if (rows.isEmpty) return null;

      // Skip header row if it exists
      final startIndex = _hasHeader(rows.first) ? 1 : 0;
      final products = <ProductModel>[];

      for (int i = startIndex; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 5) continue; // Skip invalid rows

        final product = ProductModel(
          id: 'prod_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: row[0].toString().trim(),
          category: row.length > 1 ? row[1].toString().trim() : 'General',
          sku: row.length > 2 ? row[2].toString().trim() : '',
          price: double.tryParse(row[3].toString().trim()) ?? 0,
          stock: int.tryParse(row[4].toString().trim()) ?? 0,
          description: row.length > 5 ? row[5].toString().trim() : '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        products.add(product);
      }

      return products;
    } catch (e) {
      throw Exception('Failed to import products: $e');
    }
  }

  /// Pick and parse a CSV file for customers
  static Future<List<CustomerModel>?> importCustomersFromCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      if (file.bytes == null) return null;

      final csvString = utf8.decode(file.bytes!);
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

      if (rows.isEmpty) return null;

      // Skip header row if it exists
      final startIndex = _hasHeader(rows.first) ? 1 : 0;
      final customers = <CustomerModel>[];

      for (int i = startIndex; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 4) continue; // Skip invalid rows

        final customer = CustomerModel(
          id: 'cust_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: row[0].toString().trim(),
          phone: row.length > 1 ? row[1].toString().trim() : '',
          mobile: row.length > 2 ? row[2].toString().trim() : '',
          address: row.length > 3 ? row[3].toString().trim() : '',
          area: row.length > 4 ? row[4].toString().trim() : 'Unknown',
          route: row.length > 5 ? row[5].toString().trim() : '',
          salesmanId: row.length > 6 ? row[6].toString().trim() : '',
          company: row.length > 7 ? row[7].toString().trim() : 'Total Solution',
          outstanding: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        customers.add(customer);
      }

      return customers;
    } catch (e) {
      throw Exception('Failed to import customers: $e');
    }
  }

  /// Check if the first row is a header
  static bool _hasHeader(List<dynamic> firstRow) {
    if (firstRow.isEmpty) return false;
    final firstCell = firstRow[0].toString().toLowerCase();
    // Common header names
    const headerNames = ['name', 'product', 'customer', 'sku', 'phone', 'address'];
    return headerNames.any((header) => firstCell.contains(header));
  }

  /// Generate sample CSV templates
  static String getProductTemplate() {
    return 'Name,Category,SKU,Price,Stock,Description\n'
        'Sample Product 1,Snacks,SKU001,50.0,100,Sample description\n'
        'Sample Product 2,Beverages,SKU002,30.0,200,Sample description';
  }

  static String getCustomerTemplate() {
    return 'Name,Phone,Mobile,Address,Area,Route,SalesmanID,Company\n'
        'Sample Customer,+919999999999,+919999999999,123 Main St,North Zone,Route 1,salesman_001,Total Solution';
  }
}

