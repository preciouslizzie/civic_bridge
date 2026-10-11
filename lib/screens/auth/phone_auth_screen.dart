import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../utils/constants.dart';
import 'otp_verification_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  PhoneNumber? _phoneNumber;
  bool _isSendingOtp = false; // Prevent multiple sends

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.paddingLarge),
              Text(
                'Phone Verification',
                style: AppConstants.headline1,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                'Enter your phone number to verify your account',
                style: AppConstants.bodyText1,
              ),
              const SizedBox(height: AppConstants.paddingXLarge),

              _buildPhoneInput(),

              if (_isSendingOtp)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_phoneNumber?.isValidNumber() ?? false) && !_isSendingOtp ? _sendOtp : null,
                    child: Text(_isSendingOtp ? 'Sending...' : 'Send OTP'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your phone number',
          style: AppConstants.bodyText1,
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        IntlPhoneField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          initialCountryCode: 'NG', // Default to Nigeria
          onChanged: (phone) {
            setState(() {
              _phoneNumber = phone;
            });
          },
          validator: (phone) {
            if (phone == null || !phone.isValidNumber()) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _sendOtp() async {
    if (_phoneNumber == null || !_phoneNumber!.isValidNumber()) {
      _showErrorDialog('Please enter a valid phone number');
      return;
    }

    await _sendOtpForPhone(_phoneNumber!.completeNumber);
  }

  Future<void> _sendOtpForPhone(String phoneNumber) async {
    setState(() {
      _isSendingOtp = true;
    });

    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);

    try {
      await authProvider.signInWithPhone(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() => _isSendingOtp = false);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: phoneNumber,
                verificationId: verificationId,
                onResend: () async {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  await _sendOtpForPhone(phoneNumber);
                },
              ),
            ),
          );
        },
        onVerificationFailed: (e) {
          if (!mounted) return;
          setState(() => _isSendingOtp = false);
          _showErrorDialog('Failed to send OTP: ${e.message}');
        },
        onVerificationCompleted: (credential) async {
          final success = await authProvider.signInWithCredential(credential);
          if (!mounted) return;
          setState(() => _isSendingOtp = false);
          if (!success) {
            _showErrorDialog(
              authProvider.profileLoadError ??
                  'Auto-verification failed. Please enter OTP manually.',
            );
          } else {
            final destination = authProvider.userProfile == null ? '/onboarding' : '/home';
            Navigator.of(context).pushNamedAndRemoveUntil(destination, (route) => false);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingOtp = false);
      _showErrorDialog('An error occurred: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}