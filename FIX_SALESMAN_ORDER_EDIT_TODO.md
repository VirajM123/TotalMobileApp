# Fix Salesman Order Edit Issues - TODO

## Issues to Fix:
1. When editing an order, qty and rate show defaults instead of saved values
2. Scheme (sch%) not saving and not calculating on re-edit

## Plan:

### Step 1: Add updateOrder function in OrderService
- [ ] Add modifyOrder function to properly update existing orders
- [ ] Ensure all order fields are preserved during update

### Step 2: Add Edit button in order history
- [ ] Add edit button to order card in order history section
- [ ] Connect edit button to loadOrderToCart function

### Step 3: Modify order submission logic
- [ ] Check if editingOrderId is set
- [ ] If editing, update existing order instead of creating new one
- [ ] Clear editing state after successful update

### Step 4: Fix CartItemData loading in loadOrderToCart
- [ ] Ensure all fields (quantity, rate, schPer, schAmt, grossAmt, netAmt) are loaded from order items

## Implementation Status:
- [ ] 

