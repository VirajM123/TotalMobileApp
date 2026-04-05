# Salesman Create Order - Scheme Feature Implementation Plan

## Information Gathered:
1. **Main File**: `totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart`
2. **OrderModel**: Already has scheme fields (schPer, schAmt, grossAmt, netAmt)
3. **CartItem class**: Already defined with scheme support
4. **Existing Features**: Product search, scheme toggle (_showSchemeOptions)
5. **Missing Components**:
   - `_filteredOrderProducts` getter (referenced but not defined)
   - `_showAddProductDialog` method (referenced but not defined)
   - Proper cart handling with scheme calculations in review step

## Plan:

### 1. Add `_filteredOrderProducts` getter
- Location: After `filteredProducts` getter
- Purpose: Filter products based on `_orderProductSearchQuery`

### 2. Add `_showAddProductDialog` method
- Location: After cart methods
- Features:
  - Product name display
  - Quantity input (TextField with default 1)
  - Rate input (TextField with default = product price)
  - Scheme toggle (on/off switch)
  - If scheme ON:
    - Sch% input OR Sch Amount input
    - Auto-calculate: gross = qty × rate
    - If Sch% entered: schAmt = (sch% / 100) × gross
    - If schAmt entered: sch% = (schAmt / gross) × 100
    - Net amount = gross - schAmt
  - Add/Update cart button

### 3. Update Cart Handling
- Modify `addToCart` to create CartItem instead of simple int
- Update cartTotal getter to use calculatedNetAmt from CartItem

### 4. Update Review Step
- Show scheme details for each item (gross, sch%, sch amt, net)
- Display calculated totals with scheme

### 5. Fix submitOrder to include scheme data
- Use CartItem data to populate OrderItemModel with scheme fields

## Files to Edit:
- `totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart`

## Implementation Order:
1. Add `_filteredOrderProducts` getter
2. Modify cart methods to use CartItem
3. Add `_showAddProductDialog` method
4. Update review step
5. Fix submitOrder

## Followup Steps:
- Test the product selection flow
- Test scheme calculations
- Test order submission with scheme data

