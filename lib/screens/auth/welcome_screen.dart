import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // App Logo/Icon
              Icon(
                Icons.report_problem,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: AppConstants.paddingLarge),
              Text(
                'Welcome to ${AppConstants.appName}',
                style: AppConstants.headline1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                'Report and track community issues transparently. Help make your community better by reporting problems and following up on solutions.',
                style: AppConstants.bodyText1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingXLarge),
              // Feature highlights
              _buildFeatureItem(
                icon: Icons.phone_android,
                title: 'Easy Reporting',
                description: 'Report issues with photos and location',
              ),
              const SizedBox(height: AppConstants.paddingLarge),
              _buildFeatureItem(
                icon: Icons.track_changes,
                title: 'Track Progress',
                description: 'Follow up on reported issues and see updates',
              ),
              const SizedBox(height: AppConstants.paddingLarge),
              _buildFeatureItem(
                icon: Icons.people,
                title: 'Community Driven',
                description: 'Connect with others working for change',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/auth'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingLarge),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: AppConstants.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(icon, size: 40, color: Colors.blue),
        const SizedBox(width: AppConstants.paddingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppConstants.headline2,
              ),
              Text(
                description,
                style: AppConstants.bodyText2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}