# Salesman Dashboard Fixes TODO

## Issues to Fix:

### 1. Scheme Amount Calculation (Issue #1)
- When user enters percentage, calculate amount automatically
- Show calculated scheme amount in the dialog

### 2. Scheme Gets Unsaved When Editing Quantity (Issue #2)
- Fix updateCartQuantity to preserve scheme when updating quantity
- Make sure scheme values are stored in cart and retrieved properly

### 3. Review Step - Show Scheme Details (Issue #3)
- Show gross amount, scheme percentage, scheme amount, and net amount
- Show total scheme applied and final total after scheme

### 4. PDF Button Not Working (Issue #4)
- Fix PDF generation to include scheme details
- Ensure items table shows scheme information

### 5. Add 5 Templates of Frequently Ordered Items (Issue #5)
- Create 5 default order templates
- Load them on startup

## Implementation Steps:

1. Fix _showAddProductDialog to properly handle scheme
2. Fix updateCartQuantity to preserve scheme
3. Fix _buildReviewStep to show scheme breakdown
4. Fix PDF service to include scheme details
5. Add default order templates

## Files to Modify:
- totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart
- totalsolution/lib/services/pdf_service.dart

