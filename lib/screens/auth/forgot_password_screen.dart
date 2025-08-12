import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _resetEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authController = Provider.of<AuthController>(context, listen: false);

      final success = await authController.forgotPassword(
        _emailController.text.trim(),
      );

      if (success && mounted) {
        setState(() {
          _resetEmailSent = true;
        });
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authController.error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _resetEmailSent
                ? _buildSuccessMessage()
                : _buildResetForm(authController),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm(AuthController authController) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          const Icon(
            Icons.lock_reset,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Reset Your Password',
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Enter the email associated with your account and we\'ll send you a link to reset your password.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Email Field
          CustomTextField(
            label: 'Email',
            hint: 'Enter your email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              // Simple email validation
              if (!value.contains('@') || !value.contains('.')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Reset Button
          CustomButton(
            text: 'Send Reset Link',
            onPressed: _resetPassword,
            isLoading: authController.isLoading,
          ),
          const SizedBox(height: 16),

          // Back to Login
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              '← Back to Login',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Icon
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: AppColors.success,
        ),
        const SizedBox(height: 24),

        // Success Message
        const Text(
          'Check Your Email',
          style: AppTextStyles.heading1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ve sent a password reset link to ${_emailController.text}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Back to Login Button
        CustomButton(
          text: 'Back to Login',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
