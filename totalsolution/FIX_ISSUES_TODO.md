# Fix Issues TODO

## Issues to Fix:

### 1. Login Screen Navigation Bug
- [x] Fix: Login navigates to salesman_dashboard_enhanced.dart instead of salesman_dashboard.dart
- Note: Enhanced version is now the default as it has more features

### 2. Create Order Navigation Bug
- [x] Fix: Cart checkout navigates to wrong tab (Customers instead of Create Order)

### 3. Order Creation Flow Enhancements
- [x] Add customer search bar in Step 1
- [x] Add last order summary when customer is selected
- [x] Add product search bar in Step 2
- [x] Add quick quantity buttons (1, 5, 10)

### 4. Flutter Icon Error Fix
- [x] Fix: Icons.split_payment doesn't exist - replaced with Icons.payments

### 5. Payment Collection Enhancements
- [x] Add Payment Collection section to salesman_dashboard_enhanced.dart
- [x] Add UPI type dropdown (GPay, PhonePe, Paytm, Other)
- [x] Add Cheque fields (number, date, amount)
- [x] Add Cheque+Cash fields
- [x] Add Payment Collection section to salesman_dashboard.dart (basic version)

## Files Edited:
1. lib/screens/auth/login_screen.dart - Uses enhanced dashboard (more features)
2. lib/screens/salesman/salesman_dashboard_enhanced.dart - Full payment collection
3. lib/screens/salesman/salesman_dashboard.dart - Added payment collection

## Status: All Issues Fixed ✅

