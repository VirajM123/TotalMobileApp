# Total Solution - Distributor Salesman Order Management System

A production-grade distributor–salesman order management system built with Flutter, Firebase concepts, and Node.js backend.

## System Overview

The system has three main entities:
1. **DISTRIBUTOR (Admin)** - Manages products, customers, salesmen, and views all orders
2. **SALESMAN (User)** - Views products/customers (read-only), creates orders
3. **CUSTOMER (End buyer)** - The end customer who receives orders

### Business Flow
```
Distributor → Salesman → Customer
```

## Features

### Distributor Features
- ✅ Dashboard with statistics (Total Customers, Products, Salesmen, Orders, Today's Orders)
- ✅ Customer management (Add, Edit, View)
- ✅ Product management (Add, Edit, View)
- ✅ View all salesmen registered via mobile app
- ✅ View complete order history from all salesmen
- ✅ Delete orders
- ✅ Trigger legacy desktop data sync
- ✅ Logout

### Salesman Features
- ✅ View products (read-only)
- ✅ View customers (read-only)
- ✅ Place orders for existing customers
- ✅ View own order history
- ✅ Logout

## Tech Stack

- **Frontend**: Flutter (Mobile App)
- **Backend**: Node.js + Express.js
- **Database**: Firebase (Firestore) - Mock data for demo
- **Authentication**: Firebase Auth concepts (mock for demo)

## Project Structure

```
totalsolution/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/                      # Data models
│   │   ├── user.dart
│   │   ├── product.dart
│   │   ├── customer.dart
│   │   ├── order.dart
│   │   └── models.dart
│   ├── services/                   # Business logic services
│   │   ├── auth_service.dart
│   │   ├── product_service.dart
│   │   ├── customer_service.dart
│   │   ├── order_service.dart
│   │   └── services.dart
│   └── screens/
│       ├── auth/
│       │   └── login_screen.dart
│       ├── distributor/
│       │   └── distributor_dashboard.dart
│       └── salesman/
│           └── salesman_dashboard.dart
├── backend/                         # Node.js backend
│   ├── server.js                   # Express API server
│   └── package.json
└── pubspec.yaml                    # Flutter dependencies
```

## Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Node.js (v14 or higher)

### Running the Flutter App

1. Navigate to the project directory:
```
bash
cd totalsolution
```

2. Get dependencies:
```
bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Running the Backend (Optional)

1. Navigate to backend directory:
```
bash
cd totalsolution/backend
```

2. Install dependencies:
```bash
npm install
```

3. Start the server:
```
bash
npm start
```

The API will run on `http://localhost:3000`

## API Endpoints

### Products
- `GET /api/products` - Get all products
- `POST /api/products` - Add product (Distributor only)
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product

### Customers
- `GET /api/customers` - Get all customers
- `POST /api/customers` - Add customer (Distributor only)
- `PUT /api/customers/:id` - Update customer
- `DELETE /api/customers/:id` - Delete customer

### Orders
- `GET /api/orders` - Get all orders (filter by salesmanId)
- `POST /api/orders` - Create new order
- `PUT /api/orders/:id/status` - Update order status
- `DELETE /api/orders/:id` - Delete order (Distributor only)

### Legacy Desktop Sync (Idempotent)
- `POST /sync/products` - Sync products from desktop
- `POST /sync/customers` - Sync customers from desktop

### Statistics
- `GET /api/stats` - Get dashboard statistics

## Demo Login Credentials

### Distributor
- Email: distributor@demo.com
- Password: demo123
- Or click "Distributor" button for quick login

### Salesman
- Email: salesman@demo.com
- Password: demo123
- Or click "Salesman" button for quick login

## Legacy Desktop Data Sync

The system supports syncing data from existing desktop software:

1. Desktop software sends data to Node.js backend APIs:
   - `POST /sync/products` for products
   - `POST /sync/customers` for customers

2. Backend performs idempotent sync (updates existing, inserts new)

3. Data is stored in Firebase (mock in this demo)

## UI Design

The app follows a modern design with:
- Primary Color: #1A3B70 (Deep Blue)
- Accent Color: #00A68A (Teal)
- Material Design 3 principles
- Icon-based navigation (SPA-style dashboard)

## Production Deployment

To deploy to production:

1. **Firebase Setup**:
   - Create a Firebase project
   - Enable Firebase Auth
   - Enable Cloud Firestore
   - Add your config to `lib/services/firebase_config.dart`

2. **Backend Deployment**:
   - Deploy Node.js server to Cloud Run, Heroku, or AWS
   - Update API endpoints in Flutter app

3. **Mobile App**:
   - Build release: `flutter build apk --release`
   - Or build for iOS: `flutter build ios --release`

## License

This project is for demonstration purposes.
