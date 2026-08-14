import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../providers/auth_provider.dart' as app_auth;
import '../../utils/constants.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.paddingLarge),
              Text(
                'Enter the 6-digit code',
                style: AppConstants.headline2,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                'We sent a verification code to ${widget.phoneNumber}',
                style: AppConstants.bodyText1,
              ),
              const SizedBox(height: AppConstants.paddingXLarge),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              TextButton(
                onPressed: _resendOtp,
                child: const Text('Resend Code'),
              ),

              const Spacer(),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifyOtp,
                    child: const Text('Verify'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showError('Please enter a valid 6-digit code');
      return;
    }

    // Test mode
    if (widget.verificationId == 'test_verification_id') {
      if (otp == '123456') {
        // Simulate successful verification
        final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
        // For test, we need to simulate sign in
        // Since we can't easily simulate, let's navigate to onboarding
        Navigator.of(context).pushReplacementNamed('/onboarding');
        return;
      } else {
        _showError('Invalid test code. Use 123456');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithCredential(credential);

      if (!success) {
        _showError('Verification failed. Please try again.');
      } else {
        if (!mounted) return;
        final destination = authProvider.userProfile == null ? '/onboarding' : '/home';
        Navigator.of(context).pushNamedAndRemoveUntil(destination, (route) => false);
      }
    } catch (e) {
      _showError('Invalid code. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resendOtp() async {
    // Navigate back to phone input screen
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
      ),
    );
  }
}