# Payment Collection - UPI Implementation TODO

## Task: Add UPI payment option with GPay, PhonePe, Paytm, Other + Screenshot attachment

## Implementation Steps:

### Step 1: Update PaymentCollectionModel (order.dart)
- [ ] Add `paymentScreenshot` field to store screenshot path/URL
- [ ] Update toMap() and fromMap() methods

### Step 2: Update OrderService.recordPayment (order_service.dart)
- [ ] Add `paymentScreenshot` parameter
- [ ] Pass it to PaymentCollectionModel

### Step 3: Update _showPaymentDialog (salesman_dashboard_enhanced.dart)
- [ ] Add UPI ChoiceChip option
- [ ] Show UPI dropdown when UPI is selected (GPay, PhonePe, Paytm, Other)
- [ ] Show transaction number field for UPI
- [ ] Add screenshot attachment button using image_picker
- [ ] Pass all new parameters to recordPayment

### Step 4: Check dependencies
- [ ] Ensure image_picker is in pubspec.yaml

## Files to Edit:
1. totalsolution/lib/models/order.dart
2. totalsolution/lib/services/order_service.dart  
3. totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart
4. totalsolution/pubspec.yaml (if needed)

