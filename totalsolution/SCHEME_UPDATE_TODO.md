# Scheme Update Plan for Salesman Create Order

## Summary of Requirements:
1. When selecting customer, load products with search bar feature
2. Add ability to manually enter quantity and change rate
3. Add scheme (discount) functionality:
   - schPer (percentage): Calculate schAmt = (schPer/100) * grossAmt
   - schAmt (amount): Calculate schPer = (schAmt/grossAmt) * 100
   - Gross amt = qty * rate
   - Net amt = grossAmt - schAmt
4. Add on/off toggle to show/hide scheme options per customer

## Implementation Steps:

### Step 1: Add State Variables
- Add `_showSchemeOptions` boolean (default false)
- Add `_productOrderSearchController` for product search in step 2
- Add `_productOrderSearchQuery` for filtering products

### Step 2: Update CartItem Class
- Enhance CartItem to store userEnteredQty, userEnteredRate, schPer, schAmt, grossAmt, netAmt
- Add method to calculate amounts based on scheme

### Step 3: Update Product Selection Step (_buildProductSelectionStep)
- Add search bar for products
- Add scheme toggle switch
- Show products with search filtering
- Show editable quantity, rate, scheme fields per item in cart

### Step 4: Update Cart Methods
- Modify addToCart to accept rate parameter
- Add updateCartItem method for editing quantity/rate/scheme
- Recalculate totals properly

### Step 5: Update Review Step
- Show scheme details in order summary
- Calculate totals considering scheme

### Step 6: Update Submit Order
- Include scheme details when creating order items
- Calculate net amount properly

## Files to Modify:
- totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart

## Dependencies:
- OrderItemModel already has schPer, schAmt, grossAmt, netAmt fields

