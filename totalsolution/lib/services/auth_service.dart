import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';
import '../screens/auth/login_screen.dart';
import '../screens/distributor_dashboard.dart';
import '../screens/salesman_dashboard.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Auth Service with proper API endpoint configuration
class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  static const String _userKey = 'current_user';
  
  // API endpoint - FIXED: Proper platform detection
  static String get _backendUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    
    // For mobile devices
    if (Platform.isAndroid) {
      // For Android emulator
      return 'http://10.0.2.2:3000/api';
      // For physical Android device, replace with your computer's IP address
      // return 'http://192.168.1.100:3000/api';
    } else if (Platform.isIOS) {
      // For iOS simulator
      return 'http://localhost:3000/api';
      // For physical iOS device, replace with your computer's IP address
      // return 'http://192.168.1.100:3000/api';
    }
    
    return 'http://localhost:3000/api';
  }
  
  // Mock users list - moved to a getter to avoid initialization issues
  List<UserModel> _mockUsers = [];
  
  // Initialize mock users in constructor
  AuthService() {
    _initializeMockUsers();
    _checkStoredUser();
  }
  
  void _initializeMockUsers() {
    _mockUsers = [
      UserModel(
        id: 'distributor_001',
        email: 'distributor@demo.com',
        name: 'Admin Distributor',
        phone: '+91 9876543210',
        role: UserRole.distributor,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        isActive: true,
      ),
      UserModel(
        id: 'salesman_001',
        email: 'salesman@demo.com',
        name: 'John Salesman',
        phone: '+91 9876543211',
        role: UserRole.salesman,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        isActive: true,
      ),
    ];
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isDistributor => _currentUser?.role == UserRole.distributor;
  bool get isSalesman => _currentUser?.role == UserRole.salesman;

  Future<void> _checkStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        final map = json.decode(userJson);
        _currentUser = UserModel.fromMap(map, map['id']);
        notifyListeners();
      } catch (e) {
        await prefs.remove(_userKey);
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Try both roles sequentially
      final roles = ['distributor', 'salesman'];
      UserModel? user;

      for (final roleStr in roles) {
        try {
          final response = await http.post(
            Uri.parse('$_backendUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email.toLowerCase().trim(),
              'password': password,
              'role': roleStr,
            }),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['success'] == true && data['user'] != null) {
              user = UserModel.fromMap(data['user'], data['user']['id'] ?? 'backend_${DateTime.now().millisecondsSinceEpoch}');
              _currentUser = user;
              
              // Persist to SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_userKey, json.encode(user!.toMap()));
              
              _isLoading = false;
              notifyListeners();
              return user;
            }
          }
        } catch (e) {
          // Continue to next role
          continue;
        }
      }

      throw Exception('Invalid credentials - no matching user found for distributor or salesman role');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<UserModel?> signIn(String email, String password, UserRole role) async {
    return await login(email, password); // Delegate to main login, ignore role param for now
  }

  Future<void> signUp(
    String email,
    String password,
    String name,
    UserRole role,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Check if email already exists
      final exists = _mockUsers.any(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
      if (exists) {
        throw Exception('Email already in use');
      }

      // Create new user
      final newUser = UserModel(
        id: '${role.name}_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
        isActive: true,
      );

      _mockUsers.add(newUser);
      _currentUser = newUser;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void setUserRole(UserRole role) {
    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        email: _currentUser!.email,
        name: _currentUser!.name,
        phone: _currentUser!.phone,
        role: role,
        createdAt: _currentUser!.createdAt,
        isActive: _currentUser!.isActive,
      );
      notifyListeners();
    }
  }

  // Demo login helpers
  Future<UserModel?> loginAsDistributor() async {
    return login('distributor@totalsolution.com', 'admin123');
  }

  Future<UserModel?> loginAsSalesman() async {
    return login('salesman@totalsolution.com', 'sales123');
  }

  Future<void> signOut() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    notifyListeners();
  }
}