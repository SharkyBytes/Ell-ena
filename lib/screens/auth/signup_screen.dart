import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_widgets.dart';
import '../../services/navigation_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';
import '../../services/appwrite_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _teamNameController = TextEditingController();
  final _teamIdController = TextEditingController();
  bool _isLoading = false;
  late TabController _tabController;
  String? _teamIdError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          if (_tabController.indexIsChanging || _tabController.index != _tabController.previousIndex) {
            _formKey.currentState?.reset();
            _nameController.clear();
            _emailController.clear();
            _passwordController.clear();
            _confirmPasswordController.clear();
            _teamNameController.clear();
            _teamIdController.clear();
            _teamIdError = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _teamNameController.dispose();
    _teamIdController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation for team ID when joining a team
    if (_tabController.index == 0 && _teamIdError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_teamIdError!), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_tabController.index == 0) { // Join Team
        // This is just a placeholder for the UI - actual implementation not needed
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully joined team and created account!'), backgroundColor: Colors.green),
          );
          NavigationService().navigateToReplacement(const HomeScreen()); 
        }
      } else { // Create Team
        // This is just a placeholder for the UI - actual implementation not needed
        await Future.delayed(const Duration(seconds: 1));
        String newTeamId = "TEAM123"; // Placeholder
        
        if (mounted) {
          // Show a dialog with the team ID for the admin to share
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Team Created Successfully'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Your team has been created! Share this Team ID with your team members:'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          newTeamId,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: newTeamId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Team ID copied to clipboard'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Continue to Dashboard'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    NavigationService().navigateToReplacement(const HomeScreen());
                  },
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _validateTeamId(String value) async {
    if (value.isEmpty) {
      setState(() => _teamIdError = null);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // This is just a placeholder for the UI - actual implementation not needed
      await Future.delayed(const Duration(milliseconds: 500));
      bool exists = value.length == 6; // Placeholder validation
      
      setState(() {
        _teamIdError = exists ? null : 'Team ID not found';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _teamIdError = 'Error validating Team ID';
        _isLoading = false;
      });
    }
  }

  Widget _buildJoinTeamForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _teamIdController,
          label: 'Team ID',
          icon: Icons.group_work_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter team ID';
            }
            return _teamIdError;
          },
          onChanged: (value) {
            if (value.length >= 6) {
              _validateTeamId(value);
            } else {
              setState(() => _teamIdError = null);
            }
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
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
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline,
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          icon: Icons.lock_outline,
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCreateTeamForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _teamNameController,
          label: 'Team Name',
          icon: Icons.group_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter team name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _nameController,
          label: 'Admin Name',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter admin name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          label: 'Admin Email',
          icon: Icons.email_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter admin email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline,
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          icon: Icons.lock_outline,
          isPassword: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenWrapper(
      title: 'Create Account',
      subtitle: 'Join Ell-ena to get started',
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'Join the Team'),
              Tab(text: 'Create the Team'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(
                height: 380.0,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildJoinTeamForm(),
                    _buildCreateTeamForm(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _tabController.index == 0 ? 'Join Team' : 'Create Team',
                onPressed: _isLoading ? null : _handleSignup,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Already have an account? Sign In',
                onPressed: () {
                  NavigationService().navigateToReplacement(
                    const LoginScreen(),
                  );
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
