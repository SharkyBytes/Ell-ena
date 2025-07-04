import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_widgets.dart';
import '../../services/navigation_service.dart';
import '../../services/supabase_service.dart';
import '../home/home_screen.dart';

class VerifyOTPScreen extends StatefulWidget {
  final String email;
  final String verifyType; // 'signup_join', 'signup_create', or 'reset_password'
  final Map<String, dynamic> userData;
  
  const VerifyOTPScreen({
    super.key, 
    required this.email, 
    required this.verifyType,
    this.userData = const {},
  });

  @override
  State<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends State<VerifyOTPScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;
  final _supabaseService = SupabaseService();

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

  Future<void> _handleVerification() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Verify OTP with Supabase
        final result = await _supabaseService.verifyOTP(
          email: widget.email,
          token: otp,
          type: widget.verifyType,
          userData: widget.userData,
        );
        
        if (result['success']) {
          // Handle successful verification based on verify type
          if (widget.verifyType == 'signup_create') {
            // Show team ID dialog for team creators
            if (result.containsKey('teamId')) {
              _showTeamIdDialog(result['teamId']);
            }
          } else if (widget.verifyType == 'signup_join') {
            // Navigate directly to home for team joiners
            NavigationService().navigateToReplacement(const HomeScreen());
          } else if (widget.verifyType == 'reset_password') {
            // Navigate to reset password screen
            // TODO: Implement reset password navigation
            NavigationService().goBack();
          }
        } else {
          setState(() {
            _errorMessage = result['error'] ?? 'Verification failed';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _supabaseService.resendVerificationEmail(widget.email);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code resent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to resend code';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Show dialog with the generated team ID
  void _showTeamIdDialog(String teamId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Team Created Successfully!',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your Team ID is:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      teamId,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.green),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: teamId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Team ID copied to clipboard'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share this ID with your team members so they can join your team.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                NavigationService().navigateToReplacement(const HomeScreen());
              },
              child: Text(
                'Continue',
                style: TextStyle(color: Colors.green.shade400),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenWrapper(
      title: 'Verify Email',
      subtitle: 'Enter the 6-digit code sent to ${widget.email}',
      children: [
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (index) => SizedBox(
              width: 50,
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
                  color: Colors.white,
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
                    if (index < 5) {
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
        CustomButton(
          text: 'Verify Code',
          onPressed: _isLoading ? null : _handleVerification,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Didn\'t receive the code? ',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            TextButton(
              onPressed: _isLoading ? null : _resendCode,
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