// Firebase configuration for Flutter app
// Replace these values with your Firebase project configuration

class FirebaseConfig {
  // Firebase Web App Configuration
  // Get these from Firebase Console > Project Settings > General > Your apps
  static const String apiKey = "YOUR_API_KEY";
  static const String authDomain = "YOUR_PROJECT_ID.firebaseapp.com";
  static const String projectId = "YOUR_PROJECT_ID";
  static const String storageBucket = "YOUR_PROJECT_ID.appspot.com";
  static const String messagingSenderId = "YOUR_MESSAGING_SENDER_ID";
  static const String appId = "YOUR_APP_ID";

  // For Firestore
  static const String databaseURL = "https://YOUR_PROJECT_ID.firebaseio.com";

  // Firebase Collections names
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String customersCollection = 'customers';
  static const String ordersCollection = 'orders';
  static const String orderItemsCollection = 'order_items';
}
