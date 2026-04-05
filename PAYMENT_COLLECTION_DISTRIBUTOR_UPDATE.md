# Payment Collection Enhancement for Distributor

## Task
Fix payment option in distributor - if user selects Cash/UPI/Cheque, it must show the same detailed options as salesman login when collecting payments.

## Current State
- Distributor payment dialog only shows basic Cash, UPI, Cheque chips
- No UPI app selection (GPay, PhonePe, Paytm, etc.)
- No transaction number field for UPI
- No detailed cheque fields

## Required Changes

### 1. Add State Variables (around line 125-140)
Add these variables to the state class:
```dart
// Payment dialog state
UpiType? _selectedUpiType;
String? _paymentScreenshotPath;
```

### 2. Enhance _showPaymentDialog Method (around line 2170)
Replace the basic implementation with enhanced version that includes:
- UPI app selection dropdown (GPay, PhonePe, Paytm, Other)
- Transaction number field for UPI
- Cheque details fields (number, date, amount)
- Cash amount field for Cheque+Cash mode  
- Remark field
- Screenshot button for UPI proof

### 3. Update recordPayment call
Pass additional parameters:
- upiType
- transactionNumber
- paymentScreenshot
- chequeNumber
- chequeDate
- chequeAmount
- cashAmount

## Files to Edit
- `totalsolution/lib/screens/distributor/distributor_dashboard_enhanced.dart`

## Dependencies Already Available
- `PaymentMode` enum (cash, upi, cheque, chequeWithCash, etc.)
- `UpiType` enum (gpay, phonepe, paytm, other)
- All text controllers already defined (_chequeNumberController, _chequeDateController, etc.)

