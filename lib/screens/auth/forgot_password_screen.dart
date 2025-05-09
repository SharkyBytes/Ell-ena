import 'package:flutter/material.dart';
import '../../widgets/custom_widgets.dart';
import '../../services/navigation_service.dart';
import 'verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement password reset logic
      NavigationService().navigateTo(const VerifyOTPScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenWrapper(
      title: 'Reset Password',
      subtitle: 'Enter your email to receive a reset code',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: 'Email',
                icon: Icons.email_outlined,
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Send Reset Code',
                onPressed: _handleResetPassword,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Back to Login',
                onPressed: () {
                  NavigationService().goBack();
                },
                isOutlined: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
