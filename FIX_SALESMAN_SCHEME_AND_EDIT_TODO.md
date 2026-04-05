# Fix Plan: Salesman Scheme Calculation and Order Edit Issues

## Issues Identified:

### Issue 1: Scheme/Discount Calculation Problem
- The scheme calculation in `CartItemData.calculate()` appears correct mathematically
- However, the issue may be in how schAmt is being calculated or stored when submitting the order
- Need to verify that the net amount is being calculated correctly at submission time

### Issue 2: Order Edit - Quantity Shows 1
- The `loadOrderToCart()` function seems to load quantity correctly
- However, there may be an issue with how the cart is being handled after loading
- Need to ensure the cart item's quantity is preserved when editing

## Fix Plan:

### Fix 1: Ensure proper scheme calculation in OrderItemModel creation
- In `_buildReviewStep()`, ensure schAmt is calculated and stored properly

### Fix 2: Fix loadOrderToCart to preserve quantity
- Ensure the quantity is properly loaded and the cart is recalculated

### Fix 3: Add scheme input in product selection step
- Add a "Scheme %" button/input in the product selection step for quick scheme application

