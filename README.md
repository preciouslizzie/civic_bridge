# CivicVoice - Citizen Community Issue Reporting Platform

A Flutter application that empowers citizens to report, track, and validate community issues transparently.

## Features

- **Phone Authentication**: Secure OTP-based login
- **Issue Reporting**: Report community issues with photos and detailed descriptions
- **Public Feed**: Browse and filter reported issues by location and category
- **Community Validation**: Upvote and comment on issues
- **Status Tracking**: Monitor issue resolution progress
- **Anonymous Posting**: Option to post issues anonymously
- **Real-time Updates**: Live feed of community issues and status changes

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Firebase (Authentication, Firestore, Storage, Cloud Functions)
- **State Management**: Provider
- **Image Processing**: Image compression and cropping

## Setup Instructions

### Prerequisites

1. Flutter SDK (3.11.4 or higher)
2. Firebase CLI
3. Android Studio / Xcode for platform-specific setup

### Firebase Setup

1. Create a new Firebase project at https://console.firebase.google.com/
2. Enable Authentication with Phone provider
3. Enable Firestore Database
4. Enable Firebase Storage
5. Enable Cloud Messaging (FCM) for notifications

### App Configuration

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd civicvoice
   flutter pub get
   ```

2. **Firebase Configuration**:
   - Download `google-services.json` and place in `android/app/`
   - Download `GoogleService-Info.plist` and place in `ios/Runner/`

3. **Environment Variables**:
   - Update Firebase configuration in the app if needed

### Running the App

```bash
# For Android
flutter run

# For iOS
flutter run --flavor development
```

## Project Structure

```
lib/
├── models/          # Data models (User, Issue, Comment, etc.)
├── providers/       # State management providers
├── services/        # Firebase and utility services
├── screens/         # UI screens
│   ├── auth/        # Authentication screens
│   └── home/        # Main app screens
├── utils/           # Constants and utilities
└── widgets/         # Reusable UI components
```

## Database Schema

### Users Collection
```json
{
  "id": "string",
  "name": "string",
  "phoneNumber": "string",
  "state": "string",
  "lga": "string",
  "anonymousPosting": "boolean",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Issues Collection
```json
{
  "id": "string",
  "title": "string",
  "description": "string",
  "category": "string",
  "state": "string",
  "lga": "string",
  "userId": "string",
  "userName": "string",
  "isAnonymous": "boolean",
  "imageUrls": ["string"],
  "status": "string",
  "upvotes": "number",
  "commentCount": "number",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "statusHistory": [...]
}
```

## Key Features Implementation

### Authentication Flow
1. Phone number input with country code
2. OTP verification via Firebase Auth
3. User profile creation with location data

### Issue Reporting
1. Form validation for required fields
2. Image compression and upload to Firebase Storage
3. Real-time status updates

### Community Features
1. Upvoting system with user tracking
2. Comment system with anonymous posting
3. Status tracking with history

## Security Considerations

- Phone number verification for user authentication
- Image content moderation (basic filtering)
- User data privacy with anonymous posting options
- Secure Firebase rules for data access

## Performance Optimizations

- Image compression before upload
- Lazy loading for issue feeds
- Offline data caching with Firestore
- Optimized database queries with proper indexing

## Contributing

1. Follow Flutter best practices
2. Use Provider for state management
3. Implement proper error handling
4. Add unit tests for critical functionality
5. Follow the existing code style

## License

This project is licensed under the MIT License.
