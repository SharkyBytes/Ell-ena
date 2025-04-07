import 'package:flutter/material.dart';
import '../../widgets/custom_widgets.dart';
import '../../services/navigation_service.dart';

class VerifyOTPScreen extends StatefulWidget {
  const VerifyOTPScreen({super.key});

  @override
  State<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends State<VerifyOTPScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleVerification() {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length == 4) {
      // TODO: Implement OTP verification logic
      debugPrint('Verifying OTP: $otp');
      // Navigate to password reset or success screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenWrapper(
      title: 'Verify Code',
      subtitle: 'Enter the 4-digit code sent to your email',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            4,
            (index) => SizedBox(
              width: 60,
              height: 60,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                maxLength: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    if (index < 3) {
                      _focusNodes[index + 1].requestFocus();
                    } else {
                      _focusNodes[index].unfocus();
                      _handleVerification();
                    }
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        CustomButton(text: 'Verify Code', onPressed: _handleVerification),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Didn\'t receive the code? ',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement resend code logic
                NavigationService().goBack();
              },
              child: Text(
                'Resend',
                style: TextStyle(
                  color: Colors.green.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
