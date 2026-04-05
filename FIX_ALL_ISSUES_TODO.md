# Fix All Issues TODO

## Issues to Fix:

### 1. [HIGH] Fix Scheme Data Not Being Saved to Orders
- Problem: submitOrder() doesn't use cart item's scheme data
- Solution: Update submitOrder() to use entry.value.rate, schPer, schAmt, grossAmt, netAmt

### 2. [HIGH] Show Scheme Breakdown in Review Step
- Problem: Review step shows only basic totals
- Solution: Show Gross Total, Scheme Amount, Net Total in review

### 3. [MEDIUM] Add 5 Default Order Templates
- Problem: No default templates exist
- Solution: Add 5 hardcoded templates with common products

### 4. [LOW] Verify PDF Button Functionality
- Problem: PDF buttons may not work
- Solution: Ensure PdfService is properly called

## Implementation Plan:

1. Fix submitOrder() method (lines ~546-605)
2. Fix _buildReviewStep() method to show scheme details
3. Add default templates in _loadData()
4. Verify PDF button code

## Files to Modify:
- totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart

