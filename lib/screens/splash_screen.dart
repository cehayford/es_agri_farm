import 'package:flutter/material.dart';
import '../utils/utils.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            const CircleAvatar(
              radius: 75,
              backgroundImage: AssetImage(AppConstants.appLogo),
            ),
            const SizedBox(height: 32),

            // App Name
            Text(
              AppConstants.appName,
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.white,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 16),

            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
