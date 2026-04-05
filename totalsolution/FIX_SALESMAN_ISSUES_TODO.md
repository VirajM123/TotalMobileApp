# Fix Salesman Dashboard Issues - TODO

## Issues to Fix:

### 1. Scheme Calculation (Priority: HIGH)
- Problem: When user enters scheme percentage, amount should auto-calculate
- Solution: Add scheme fields to cart and calculate schAmt = (grossAmt * schPer) / 100

### 2. Scheme Gets Unsaved (Priority: HIGH)
- Problem: Scheme data lost when navigating between order steps
- Solution: Store scheme data per item in cart (change from Map<String, int> to custom class)

### 3. Review Page - Show Scheme Details (Priority: HIGH)
- Problem: Review page doesn't show scheme applied and final total
- Solution: Add scheme details section in review step showing:
  - Gross Total (before scheme)
  - Scheme Percentage & Amount
  - Net Total (after scheme)

### 4. PDF Button Not Working (Priority: HIGH)
- Problem: PDF button in order history doesn't work
- Solution: Fix the PdfService.downloadOrderPdf call in _buildOrderCard

### 5. Add 5 Default Templates (Priority: MEDIUM)
- Problem: No default templates for frequently ordered items
- Solution: Add 5 hardcoded templates with common products

## Implementation Steps:

1. [x] Read and understand existing code
2. [ ] Create CartItem class with scheme support
3. [ ] Update cart state management
4. [ ] Add scheme input in product dialog
5. [ ] Fix scheme calculation
6. [ ] Update review page with scheme details
7. [ ] Fix PDF button
8. [ ] Add default templates

