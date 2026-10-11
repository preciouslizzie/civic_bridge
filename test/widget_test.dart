// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civicvoice/screens/auth/welcome_screen.dart';
import 'package:civicvoice/screens/auth/otp_verification_screen.dart';

void main() {
  testWidgets('Welcome screen shows onboarding prompt', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    expect(find.textContaining('Welcome to'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('OTP resend triggers the resend callback', (WidgetTester tester) async {
    var resendCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: OtpVerificationScreen(
          phoneNumber: '+2348012345678',
          verificationId: 'verification-id',
          onResend: () async {
            resendCount++;
          },
        ),
      ),
    );

    await tester.tap(find.text('Resend Code'));
    await tester.pump();

    expect(resendCount, 1);
  });
}
