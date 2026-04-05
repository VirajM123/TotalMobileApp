# Fix Cart Edit Issues - TODO

## Issues to Fix:
1. User cannot edit qty, rate multiple times
2. Previously added qty, rate erases when clicking edit button
3. Scheme % doesn't calculate the sch amount in the sch amount field
4. Scheme % doesn't save

## Fix Plan:

### 1. Fix Order Submission - Save scheme fields
- In `_buildReviewStep()`, when creating OrderItemModel, include:
  - schPer, schAmt, grossAmt, netAmt

### 2. Add Cart Item Edit Dialog
- Create a dialog to edit qty, rate, schPer for each cart item
- Add edit button to cart items

### 3. Fix Load Order to Cart  
- Ensure schPer is properly loaded from order items
- Call calculate() to recalculate amounts

## Files to Edit:
1. `totalsolution/lib/screens/salesman/salesman_dashboard.dart`
   - Fix order submission to save scheme fields
   - Add cart item edit dialog with qty, rate, schPer fields

