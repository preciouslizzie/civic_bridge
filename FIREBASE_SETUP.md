# CivicVoice - Firebase Setup Guide

This guide will help you set up the Firebase project, Cloud Functions, and security rules for the CivicVoice application.

## Prerequisites

- Firebase CLI installed (`npm install -g firebase-tools`)
- Flutter SDK installed
- Node.js installed (for Cloud Functions)
- A Google Cloud Platform project

## 1. Firebase Project Setup

### Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter "civicvoice-project" as the project name
4. Enable Google Analytics (recommended)
5. Choose your Google Analytics account
6. Click "Create project"

### Enable Required Services

In your Firebase project, enable the following services:

1. **Authentication**
   - Go to Authentication > Sign-in method
   - Enable "Phone" as a sign-in provider

2. **Firestore Database**
   - Go to Firestore Database
   - Click "Create database"
   - Choose "Start in test mode" (you can change this later)
   - Select a location for your database

3. **Storage**
   - Go to Storage
   - Click "Get started"
   - Choose "Start in test mode" (you can change this later)
   - Select a location for your storage

4. **Cloud Functions**
   - Go to Functions
   - Click "Get started"
   - This will enable Cloud Functions for your project

5. **Cloud Messaging**
   - Go to Cloud Messaging
   - This should be automatically enabled

## 2. Firebase CLI Setup

### Install Firebase CLI (if not already installed)

```bash
npm install -g firebase-tools
```

### Login to Firebase

```bash
firebase login
```

### Initialize Firebase in your project

```bash
cd civicvoice
firebase init
```

When prompted:
- Select "Functions" and "Hosting"
- Choose your Firebase project ("civicvoice-project")
- Select "JavaScript" for Functions
- Choose "ESLint" for linting
- Install dependencies automatically: Yes

## 3. Configure Firebase Options

Update `lib/firebase_options.dart` with your actual Firebase configuration:

1. Go to Firebase Console > Project settings > General
2. Scroll down to "Your apps" section
3. Click "Add app" and add both Android and iOS apps
4. Copy the configuration values to `firebase_options.dart`

For web configuration:
1. Click "Add app" > Web app
2. Copy the config object to the web section in `firebase_options.dart`

## 4. Deploy Security Rules

### Firestore Rules

```bash
firebase deploy --only firestore:rules
```

### Storage Rules

```bash
firebase deploy --only storage
```

## 5. Cloud Functions Setup

### Install Dependencies

```bash
cd functions
npm install
```

### Deploy Functions

```bash
firebase deploy --only functions
```

### Available Functions

- `moderateIssue`: Automatically moderates new issues for inappropriate content
- `moderateComment`: Moderates comments for inappropriate content
- `sendIssueStatusNotification`: Notifies users when issue status changes
- `sendCommentNotification`: Notifies issue authors of new comments
- `updateIssueVotes`: Maintains vote counts on issues
- `cleanupOldTempFiles`: Cleans up temporary files
- `updateIssueStats`: Updates analytics statistics

## 6. Admin Setup

### Create Admin User

To create an admin user, add their UID to the `admins` collection in Firestore:

```javascript
// In Firebase Console > Firestore
// Add document to 'admins' collection
{
  userId: "ADMIN_UID_HERE",
  assignedAt: Timestamp.now(),
  assignedBy: "system"
}
```

### Access Admin Panel

Admin users can access the admin panel by navigating to `/admin` route or by implementing role-based navigation in your app.

## 7. Push Notifications Setup

### iOS Setup

1. In Xcode, enable Push Notifications capability
2. Upload your APNs certificate to Firebase Console
3. Add the following to your `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Android Setup

1. Add to `android/app/build.gradle`:

```gradle
dependencies {
    // ... other dependencies
    implementation 'com.google.firebase:firebase-messaging:23.1.2'
}
```

2. Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
    <!-- ... other configurations -->

    <application ...>
        <!-- ... other configurations -->

        <service
            android:name=".MyFirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>
    </application>
</manifest>
```

## 8. Environment Variables

Create a `.env` file in the functions directory for sensitive configuration:

```env
# Add any environment variables needed for functions
# Example:
# OPENAI_API_KEY=your_key_here
```

## 9. Testing

### Test Functions Locally

```bash
cd functions
firebase functions:shell
```

### Test with Emulator Suite

```bash
firebase emulators:start
```

## 10. Production Deployment

### Deploy Everything

```bash
firebase deploy
```

### Deploy Specific Components

```bash
# Deploy only functions
firebase deploy --only functions

# Deploy only hosting
firebase deploy --only hosting

# Deploy only rules
firebase deploy --only firestore:rules,storage
```

## 11. Monitoring

### View Function Logs

```bash
firebase functions:log
```

### Monitor Usage

- Go to Firebase Console > Functions
- View execution logs and performance metrics

## 12. Security Considerations

1. **Update Firestore Rules**: Change from test mode to production rules
2. **Storage Rules**: Implement proper access controls
3. **API Keys**: Restrict API keys in Google Cloud Console
4. **Rate Limiting**: Implement rate limiting for functions if needed
5. **Data Validation**: Ensure proper data validation in functions

## Troubleshooting

### Common Issues

1. **Functions not deploying**: Check that billing is enabled for your project
2. **Notifications not working**: Verify FCM configuration and APNs certificates
3. **Rules not applying**: Wait a few minutes after deployment for rules to propagate

### Support

For issues with Firebase setup, check:
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase CLI Documentation](https://firebase.google.com/docs/cli)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/firebase)

## Next Steps

1. Configure monitoring and alerting
2. Set up CI/CD pipeline for automatic deployments
3. Implement A/B testing for features
4. Set up backup and disaster recovery procedures