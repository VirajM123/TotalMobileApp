# Payment Collection Modification TODO

## Task: Restructure Payment Collection Options

### Requirements:
1. Payment modes must be:
   - Cash
   - UPI (with dropdown: Google Pay, PhonePe, Paytm, Other)
   - Cheque (shows: cheque no, date, remark, amount)
   - Cheque+Cash (shows: cash amount, cheque no, date, cheque amount)

2. Payment Collection History to track payment history

---

## Implementation Plan:

### Step 1: Modify PaymentCollectionModel in order_service.dart
- [x] Add upiType field
- [x] Add chequeNumber field  
- [x] Add chequeDate field
- [x] Add chequeAmount field
- [x] Add cashAmount field
- [x] Add remark field
- [x] Update toMap() and fromMap() methods

### Step 2: Modify PaymentMode enum in order_service.dart
- [x] Keep: cash, upi, cheque, chequeWithCash
- [x] Remove: gpay, phonepe, paytm, upiOther (will be sub-options of UPI)
- [x] Update paymentModeDisplay getter

### Step 3: Modify salesman_dashboard_enhanced.dart - Payment Dialog
- [ ] Restructure to show grouped payment options
- [ ] Add UPI dropdown for UPI type selection
- [ ] Show cheque fields only when Cheque or Cheque+Cash selected
- [ ] Show cash amount field for Cheque+Cash

### Step 4: Add Payment Collection History Section
- [ ] Add new navigation item for Payment History
- [ ] Display all payments collected with details
- [ ] Show filter options (by date, customer, mode)

---

## Files to Edit:
1. `totalsolution/lib/services/order_service.dart`
2. `totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart`

