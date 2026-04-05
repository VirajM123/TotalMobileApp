# Salesman Order Scheme Changes - TODO

## Task Summary
Modify salesman side create order logic to add:
1. Product search functionality when selecting customer
2. Manual quantity and rate entry for products
3. Scheme (discount) calculation with percentage or amount
4. On/off toggle to show/hide scheme options

## Changes Required

### 1. Product Search in Create Order Step 2
- Add TextField search bar to filter products by name/SKU
- Filter products based on search query

### 2. Product Entry Dialog
- When adding a product, show a dialog to:
  - Enter quantity (default: 1)
  - Change rate (default: product price)
  - Toggle scheme options on/off
  - Enter scheme percentage OR scheme amount
  - Auto-calculate gross, scheme, and net amounts

### 3. Scheme Calculations
- Gross Amount = qty × rate
- If Sch% entered: Sch Amount = (Sch% / 100) × Gross Amount
- If Sch Amount entered: Sch% = (Sch Amount / Gross Amount) × 100
- Net Amount = Gross Amount - Scheme Amount

### 4. Scheme Toggle
- On/Off toggle to display scheme options
- Only show scheme fields when toggle is ON
- Each customer can have scheme enabled/disabled

### 5. Update Review Step
- Show scheme details (gross, sch%, sch amt, net) for each item
- Display calculated totals

## Files to Modify
- `totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart`
  - Add product search in `_buildProductSelectionStep()`
  - Create `_showAddProductDialog()` method
  - Enhance CartItem handling
  - Update `_buildReviewStep()` to show scheme details
  - Ensure `_showSchemeOptions` toggle works properly

## Implementation Status
- [ ] Add product search TextField in product selection step
- [ ] Create add product dialog with quantity/rate/scheme inputs
- [ ] Implement scheme calculation logic
- [ ] Add scheme toggle per customer
- [ ] Update review step to show scheme details
- [ ] Test the complete flow

