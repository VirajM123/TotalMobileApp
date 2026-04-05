# Salesman Order Changes - Implementation Plan

## Task: Modify Salesman Side Create Order Logic

### Requirements:
1. When selecting customer, load products with search bar functionality
2. Allow manual quantity entry
3. Allow rate change
4. Scheme (sch) feature:
   - On/off toggle to display scheme options (per customer)
   - If sch% entered: schAmt = (schPer/100) × grossAmt
   - If schAmt entered: schPer = (schAmt/grossAmt) × 100
   - grossAmt = qty × rate
   - netAmt = grossAmt - schAmt

## Implementation Steps:
- [ ] 1. Add `_showAddProductDialog` method with quantity, rate, and scheme fields
- [ ] 2. Connect the scheme toggle to show/hide scheme fields
- [ ] 3. Ensure products are loaded and searchable in Step 2
- [ ] 4. Update the cart item creation to use custom quantity/rate/scheme
- [ ] 5. Update review step to show scheme details

## Files to Edit:
- `totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart`

