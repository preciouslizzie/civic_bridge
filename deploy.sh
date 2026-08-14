#!/bin/bash

# CivicVoice Firebase Deployment Script

echo "🚀 Starting CivicVoice Firebase deployment..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase. Please run:"
    echo "firebase login"
    exit 1
fi

echo "📋 Checking Firebase project..."
PROJECT_ID=$(firebase use)
if [ $? -ne 0 ]; then
    echo "❌ No Firebase project selected. Please run:"
    echo "firebase use your-project-id"
    exit 1
fi

echo "✅ Using Firebase project: $PROJECT_ID"

# Deploy Firestore rules
echo "📝 Deploying Firestore rules..."
firebase deploy --only firestore:rules
if [ $? -ne 0 ]; then
    echo "❌ Failed to deploy Firestore rules"
    exit 1
fi

# Deploy Storage rules
echo "🗄️ Deploying Storage rules..."
firebase deploy --only storage
if [ $? -ne 0 ]; then
    echo "❌ Failed to deploy Storage rules"
    exit 1
fi

# Install functions dependencies
echo "📦 Installing Cloud Functions dependencies..."
cd functions
npm install
if [ $? -ne 0 ]; then
    echo "❌ Failed to install functions dependencies"
    exit 1
fi
cd ..

# Deploy functions
echo "⚡ Deploying Cloud Functions..."
firebase deploy --only functions
if [ $? -ne 0 ]; then
    echo "❌ Failed to deploy Cloud Functions"
    exit 1
fi

# Deploy hosting (if configured)
echo "🌐 Deploying hosting..."
firebase deploy --only hosting
if [ $? -ne 0 ]; then
    echo "⚠️ Hosting deployment failed (this might be expected if not configured)"
fi

echo "🎉 Deployment completed successfully!"
echo ""
echo "📊 Summary:"
echo "  ✅ Firestore rules deployed"
echo "  ✅ Storage rules deployed"
echo "  ✅ Cloud Functions deployed"
echo "  ✅ Hosting deployed (if configured)"
echo ""
echo "🔗 Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"
echo ""
echo "📝 Next steps:"
echo "  1. Update firebase_options.dart with your project configuration"
echo "  2. Test the functions locally: firebase emulators:start"
echo "  3. Create admin users in Firestore 'admins' collection"
echo "  4. Configure push notifications in mobile apps"