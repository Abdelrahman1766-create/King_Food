# KING FOOD Driver Application

A dedicated driver application for the KING FOOD food delivery system.

## Features

- **Driver Authentication**: Secure login with Firebase authentication
- **Order Management**: View orders assigned exclusively to the driver
- **Order Status Updates**: Update order status from "In Transit" to "Delivered"
- **Order Details**: View complete order information with prices and addresses
- **Navigation Map**: ✅ Yandex Maps integration for navigation to customer address with pickup and delivery point markers
- **Customer Contact**: ✅ Ability to call customers directly from the application
- **Location Tracking**: ✅ Track driver's current geographical location

## System Requirements

- Flutter SDK 3.0+
- Firebase project with Authentication and Firestore enabled
- Driver account registered in the administration system

## Project Setup

1. **Firebase Setup**:
   ```bash
   # Add Firebase packages
   flutter pub add firebase_core firebase_auth cloud_firestore
   ```

2. **Firebase Configuration**:
   - Create a new Firebase project or use an existing one
   - Enable Authentication with Email/Password
   - Enable Firestore Database
   - Add Flutter app and download configuration files

3. **Run the Application**:
   ```bash
   # Run the driver application
   flutter run lib/main_driver.dart
   ```

## Project Structure

```
lib/driver_app/
├── app/
│   ├── driver_app.dart          # Main driver application
│   ├── driver_providers.dart    # Riverpod state management
│   └── driver_router.dart       # Navigation setup
├── ui/
│   └── screens/
│       ├── login_screen.dart        # Login screen
│       ├── orders_screen.dart       # Orders list screen
│       └── order_details_screen.dart # Order details with map
└── viewmodels/
    ├── auth_viewmodel.dart      # Authentication management
    └── orders_viewmodel.dart    # Order management
```

## Application Usage

### Login
- Use the email address and password registered in the administration system
- Drivers are created by the administration

### Order Management
- View all orders assigned to the driver
- Update order status from "In Transit" to "Delivered"
- View complete order details

### Map and Navigation
- View Yandex Maps with pickup and delivery locations
- Green line indicates the route between points
- Zoom and pan the map for better navigation

### Customer Contact
- Press the phone button to call the customer directly
- Uses the device's default phone application

## Completed Features ✅

- [x] Yandex Maps navigation
- [x] Geolocation tracking
- [x] Customer contact functionality
- [x] Real-time order status updates

## Future Development

- [ ] Real-time notifications for new orders
- [ ] Direct VoIP calling (Voice over IP)
- [ ] Daily earnings and statistics dashboard
- [ ] Offline mode support
- [ ] Order history and customer ratings
- [ ] Performance optimization and UI improvements

## Support

For any inquiries or issues, please contact the development team.
