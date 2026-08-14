import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  String? _selectedState;
  String? _selectedLga;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about yourself',
                style: AppConstants.headline2,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                'This information helps us connect you with issues in your area',
                style: AppConstants.bodyText2,
              ),
              const SizedBox(height: AppConstants.paddingXLarge),

              _buildNameField(),
              const SizedBox(height: AppConstants.paddingLarge),

              _buildStateDropdown(),
              const SizedBox(height: AppConstants.paddingLarge),

              _buildLgaField(),
              const SizedBox(height: AppConstants.paddingLarge),

              _buildAnonymousToggle(),

              const Spacer(),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _completeOnboarding,
                    child: const Text('Get Started'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Name',
          style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: Icon(Icons.person),
          ),
        ),
      ],
    );
  }

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State',
          style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        DropdownButtonFormField<String>(
          value: _selectedState,
          decoration: const InputDecoration(
            hintText: 'Select your state',
            prefixIcon: Icon(Icons.location_on),
          ),
          items: AppConstants.nigerianStates.map((state) {
            return DropdownMenuItem(
              value: state,
              child: Text(state),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedState = value;
              _selectedLga = null; // Reset LGA when state changes
            });
          },
        ),
      ],
    );
  }

  Widget _buildLgaField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Local Government Area',
          style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        TextField(
          enabled: _selectedState != null,
          decoration: InputDecoration(
            hintText: _selectedState != null
                ? 'Enter your LGA'
                : 'Select state first',
            prefixIcon: const Icon(Icons.location_city),
          ),
          onChanged: (value) {
            _selectedLga = value;
          },
        ),
      ],
    );
  }

  Widget _buildAnonymousToggle() {
    return Row(
      children: [
        const Icon(Icons.visibility_off, size: 20),
        const SizedBox(width: AppConstants.paddingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anonymous Posting',
                style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'Hide your identity when creating issues',
                style: AppConstants.bodyText2,
              ),
            ],
          ),
        ),
        Switch(
          value: false, // Default to false
          onChanged: (value) {
            // This would be implemented with state management
            // For now, we'll set it to false
          },
        ),
      ],
    );
  }

  void _completeOnboarding() async {
    final name = _nameController.text.trim();
    final state = _selectedState;
    final lga = _selectedLga?.trim();

    if (name.isEmpty) {
      _showError('Please enter your name');
      return;
    }

    if (state == null) {
      _showError('Please select your state');
      return;
    }

    if (lga == null || lga.isEmpty) {
      _showError('Please enter your LGA');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.createUserProfile(
      name: name,
      state: state,
      lga: lga,
    );

    setState(() => _isLoading = false);

    if (!success) {
      _showError('Failed to create profile. Please try again.');
    }
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