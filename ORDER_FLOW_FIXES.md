# Order Flow Fixes - TODO

## Task Summary
Fix order creation flow in both Distributor and Salesman dashboards with:
1. Customer selection with search
2. Product list with search
3. Manual quantity entry with +/-
4. Order summary before submitting

## Files to Modify

### 1. Distributor Dashboard (distributor_dashboard_enhanced.dart)
- [ ] Add product search controller and query variables
- [ ] Add filteredProductsForOrder getter
- [ ] Update _buildProductSelectionStep() with search bar
- [ ] Add manual quantity entry with +/- buttons
- [ ] Enhance _buildReviewStep() with full order summary

### 2. Salesman Dashboard (salesman_dashboard_enhanced.dart)
- [ ] Enhance product selection with manual quantity entry
- [ ] Ensure order summary is complete

## Implementation Steps
1. Add variables for product search in order flow
2. Create filtered getter for products
3. Add search bar UI
4. Add quantity input field with +/- buttons
5. Enhance order summary display

