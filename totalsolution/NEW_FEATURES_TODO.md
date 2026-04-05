# New Features Implementation TODO

## Task Summary
Implement all requested features for Distributor and Salesman login:

### Features to Implement:
1. ✅ Desktop Software Import - Sync products/customers from desktop via API
2. ✅ Search bar for customers and products (fix existing)
3. ✅ Last billing status when clicking customer/product
4. ✅ Salesman last order in distributor side with search
5. ✅ Order PDF download + WhatsApp share for both distributor and salesman

---

## Implementation Plan

### Step 1: Add Sync Service
- Create/enhance sync service to fetch products/customers from desktop API
- Add API endpoints configuration

### Step 2: Fix Search Functionality
- Fix search in customer section (distributor)
- Fix search in product section (distributor)
- Ensure search filters by name, area, phone, SKU

### Step 3: Enhance Desktop Import Button
- Add "Upload from Desktop" button in Products section
- Add "Upload from Desktop" button in Customers section
- Call sync API endpoints

### Step 4: Verify Existing Features
- Last billing status display (customer click)
- Salesman last order display
- PDF download and WhatsApp share

---

## Files to Modify:
1. `lib/services/sync_service.dart` - New sync service
2. `lib/screens/distributor/distributor_dashboard_enhanced.dart` - Main changes
3. `lib/services/services.dart` - Export new service

## Files to Verify:
1. `lib/screens/salesman/salesman_dashboard_enhanced.dart` - Already has features
2. `lib/services/pdf_service.dart` - Already has PDF and WhatsApp

---

## Status: IN PROGRESS

