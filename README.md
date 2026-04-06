# KING FOOD - Food Delivery System

A comprehensive Flutter-based food delivery application with separate apps for customers and drivers.

## Overview

KING FOOD is a complete food delivery platform featuring:
- **Customer App**: Browse restaurants, place orders, track delivery
- **Driver App**: Manage deliveries, navigate to customers, track earnings
- **Admin Dashboard**: Manage restaurants, orders, and drivers (web-based)

## Tech Stack

- **Frontend**: Flutter 3.9+
- **Backend**: Firebase (Authentication, Firestore, Cloud Functions, Storage)
- **Maps**: Yandex MapKit
- **State Management**: Riverpod & Provider
- **Navigation**: Go Router
- **Localization**: Multi-language support (Arabic, Russian, English)

## Project Structure

```
lib/
├── main.dart                    # Customer app entry point
├── main_driver.dart             # Driver app entry point
├── driver_app/                  # Driver application module
│   ├── app/
│   ├── ui/screens/
│   ├── viewmodels/
│   └── models/
├── restaurant_admin/            # Admin panel (web)
├── services/                    # API and Firebase services
├── models/                      # Data models
├── providers/                   # State management
└── ui/                          # UI components and screens
```

## Features

### Customer App
- 📱 User authentication (Email, Phone)
- 🍽️ Browse restaurants and menus
- 🛒 Shopping cart management
- 💳 Payment integration (YooKassa)
- 📍 Delivery tracking in real-time
- ⭐ Order history and ratings

### Driver App
- 🔐 Secure driver login
- 📦 Order management dashboard
- 🗺️ Real-time navigation with maps
- 📞 Direct customer contact
- 📍 Real-time location tracking
- 💰 Earnings tracking

### Admin Panel
- 👨‍💼 Restaurant management
- 📊 Orders tracking and analytics
- 👥 Driver management
- 💸 Payment settlements

## Installation

### Prerequisites
- Flutter 3.9 or higher
- Firebase project configured
- Dart SDK 3.0+

### Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Abdelrahman1766-create/King_Food.git
   cd King_Food
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - Download Firebase configuration files
   - Place `google-services.json` in `android/app/`
   - Place `GoogleService-Info.plist` in `ios/Runner/`

4. **Run the application**:
   ```bash
   # Customer app
   flutter run

   # Driver app
   flutter run lib/main_driver.dart
   ```

## Multi-language Support

The application supports multiple languages:
- 🇸🇦 Arabic (ar)
- 🇷🇺 Russian (ru)
- 🇬🇧 English (en)

## Documentation

- [Driver App Documentation](DRIVER_APP_README.md) (العربية)
- [Driver App Documentation](DRIVER_APP_README_EN.md) (English)
- [Payment Integration Guide](PAYMENT_INTEGRATION.md)
- [Localization Changes](LOCALIZATION_CHANGES.md)

## Build & Deployment

### Android Build
```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

### iOS Build
```bash
flutter build ios --release
```

## Security & Compliance

- ✅ Firebase Authentication
- ✅ Secure API communication
- ✅ PCI compliance for payment processing
- ✅ GDPR compliant data handling
- ✅ Location data privacy

## Contributing

Please follow the code style guidelines and submit pull requests to the main branch.

## License

This project is proprietary software. All rights reserved.

## Support & Contact

For technical support or inquiries:
- Email: support@kingfood.app
- Website: www.kingfood.app

## Development Status

- ✅ Customer App: Production Ready
- ✅ Driver App: Production Ready
- 🚀 Admin Panel: In Development
- 📱 Enhanced Features: Upcoming

