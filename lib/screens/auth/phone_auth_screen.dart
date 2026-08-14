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
  bool _isLoading = false;
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

              if (_isLoading)
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

    final phoneNumber = _phoneNumber!.completeNumber;
    print('Sending OTP to: $phoneNumber'); // Debug print

    setState(() {
      _isLoading = true;
      _isSendingOtp = true;
    });

    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    
    // Test mode for development
    if (phoneNumber == '') {
      print('Using test mode for phone number');
      await Future.delayed(const Duration(seconds: 2)); // Simulate delay
      setState(() {
        _isLoading = false;
        _isSendingOtp = false;
      });
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            phoneNumber: phoneNumber,
            verificationId: 'test_verification_id',
          ),
        ),
      );
      return;
    }

    try {
      await authProvider.signInWithPhone(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          print('OTP sent successfully, verificationId: $verificationId'); // Debug print
          setState(() {
            _isLoading = false;
            _isSendingOtp = false;
          });
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: phoneNumber,
                verificationId: verificationId,
              ),
            ),
          );
        },
        onVerificationFailed: (e) {
          print('Verification failed: ${e.message}'); // Debug print
          setState(() {
            _isLoading = false;
            _isSendingOtp = false;
          });
          _showErrorDialog('Failed to send OTP: ${e.message}');
        },
        onVerificationCompleted: (credential) async {
          print('Auto-verification completed'); // Debug print
          // Auto-verification: sign in directly
          final success = await authProvider.signInWithCredential(credential);
          setState(() {
            _isLoading = false;
            _isSendingOtp = false;
          });
          if (!success) {
            _showErrorDialog('Auto-verification failed. Please enter OTP manually.');
          } else {
            if (!mounted) return;
            final destination = authProvider.userProfile == null ? '/onboarding' : '/home';
            Navigator.of(context).pushNamedAndRemoveUntil(destination, (route) => false);
          }
        },
      );
    } catch (e) {
      print('Exception in sendOtp: $e'); // Debug print
      setState(() {
        _isLoading = false;
        _isSendingOtp = false;
      });
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