# Ticket to Ride - Flutter Web App

A digital version of the classic Ticket to Ride board game built with Flutter for web, optimized for iPhone and MacBook browsers.

## Features

- 🎮 **Responsive Design**: Optimized for both mobile (iPhone) and desktop (MacBook) browsers
- 🔐 **Firebase Authentication**: Secure user login and registration
- 🎯 **Real-time Gameplay**: Multiplayer support with Firebase Firestore
- 📱 **PWA Support**: Install as a web app on mobile devices
- 🎨 **Modern UI**: Clean, intuitive interface with Material Design 3

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Firebase project setup
- Web browser (Chrome, Safari, Firefox, Edge)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd TicketToRide
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication and Firestore Database
   - Update `lib/firebase_options.dart` with your Firebase configuration
   - Add your Firebase config to the `firebase_options.dart` file

4. **Run the app**
   ```bash
   flutter run -d chrome
   ```

### Firebase Setup

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project
   - Enable Authentication (Email/Password)
   - Enable Firestore Database

2. **Configure Web App**
   - Add a web app to your Firebase project
   - Copy the Firebase configuration
   - Update `lib/firebase_options.dart` with your config

3. **Security Rules**
   ```javascript
   // Firestore rules
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /games/{gameId} {
         allow read, write: if request.auth != null;
       }
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── providers/
│   └── auth_provider.dart   # Authentication state management
└── screens/
    ├── home_screen.dart      # Main lobby screen
    ├── login_screen.dart     # Authentication screen
    ├── game_screen.dart      # Game board screen
    └── profile_screen.dart   # User profile screen
```

## Responsive Design

The app automatically adapts to different screen sizes:

- **Mobile (iPhone)**: Full-screen layout optimized for touch
- **Desktop (MacBook)**: Centered container with phone-like dimensions
- **Tablet**: Responsive layout that scales appropriately

## Building for Production

1. **Build for web**
   ```bash
   flutter build web
   ```

2. **Deploy to Firebase Hosting**
   ```bash
   firebase init hosting
   firebase deploy
   ```

## Technologies Used

- **Flutter**: Cross-platform UI framework
- **Firebase**: Backend services (Auth, Firestore, Hosting)
- **Riverpod**: State management
- **Go Router**: Navigation
- **ScreenUtil**: Responsive design
- **Material Design 3**: Modern UI components

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the repository.
