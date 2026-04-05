# TODO - Fix Edit Order Issues

## Task Summary
Fix issues with editing orders in salesman dashboard:
1. Qty/rate erasing when editing an order
2. Scheme % not calculating properly  
3. Changes not saving properly

## Implementation Plan

### Step 1: Add state variables for order editing
- Add `_editingOrderId` to track if editing existing order
- Add `loadOrderToCart(OrderModel order)` method

### Step 2: Add Edit button to order cards
- Add "Edit" button in `_buildOrderCard` method
- Load order items into cart when clicked

### Step 3: Fix cart dialog to show editable fields
- Add TextField for qty, rate, sch % in cart item display
- Call calculate() when values change

### Step 4: Fix scheme calculation
- Ensure calculate() is called when schPer changes
- Display sch amount in cart

### Step 5: Fix order saving/updating
- Check if editing existing order and update instead of create new

## Files to Edit
- totalsolution/lib/screens/salesman/salesman_dashboard.dart

