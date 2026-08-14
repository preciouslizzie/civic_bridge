@echo off
REM CivicVoice Firebase Deployment Script for Windows

echo 🚀 Starting CivicVoice Firebase deployment...

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI is not installed. Please install it first:
    echo npm install -g firebase-tools
    pause
    exit /b 1
)

REM Check if user is logged in
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Not logged in to Firebase. Please run:
    echo firebase login
    pause
    exit /b 1
)

echo 📋 Checking Firebase project...
for /f "tokens=*" %%i in ('firebase use') do set PROJECT_ID=%%i
if %errorlevel% neq 0 (
    echo ❌ No Firebase project selected. Please run:
    echo firebase use your-project-id
    pause
    exit /b 1
)

echo ✅ Using Firebase project: %PROJECT_ID%

REM Deploy Firestore rules
echo 📝 Deploying Firestore rules...
firebase deploy --only firestore:rules
if %errorlevel% neq 0 (
    echo ❌ Failed to deploy Firestore rules
    pause
    exit /b 1
)

REM Deploy Storage rules
echo 🗄️ Deploying Storage rules...
firebase deploy --only storage
if %errorlevel% neq 0 (
    echo ❌ Failed to deploy Storage rules
    pause
    exit /b 1
)

REM Install functions dependencies
echo 📦 Installing Cloud Functions dependencies...
cd functions
call npm install
if %errorlevel% neq 0 (
    echo ❌ Failed to install functions dependencies
    cd ..
    pause
    exit /b 1
)
cd ..

REM Deploy functions
echo ⚡ Deploying Cloud Functions...
firebase deploy --only functions
if %errorlevel% neq 0 (
    echo ❌ Failed to deploy Cloud Functions
    pause
    exit /b 1
)

REM Deploy hosting (if configured)
echo 🌐 Deploying hosting...
firebase deploy --only hosting
if %errorlevel% neq 0 (
    echo ⚠️ Hosting deployment failed (this might be expected if not configured)
)

echo 🎉 Deployment completed successfully!
echo.
echo 📊 Summary:
echo   ✅ Firestore rules deployed
echo   ✅ Storage rules deployed
echo   ✅ Cloud Functions deployed
echo   ✅ Hosting deployed (if configured)
echo.
echo 🔗 Firebase Console: https://console.firebase.google.com/project/%PROJECT_ID%
echo.
echo 📝 Next steps:
echo   1. Update firebase_options.dart with your project configuration
echo   2. Test the functions locally: firebase emulators:start
echo   3. Create admin users in Firestore 'admins' collection
echo   4. Configure push notifications in mobile apps
echo.
pause