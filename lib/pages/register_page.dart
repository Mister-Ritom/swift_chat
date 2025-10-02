import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:swift_chat/pages/home_page.dart';
import 'package:swift_chat/pages/login_page.dart';
import '../providers/user_provider.dart';
import '../utils/error_map.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Real-time field errors
  String? _usernameError;
  String? _emailError;
  String? _passwordError;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(userProvider.notifier)
          .register(
            _usernameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (!mounted || !context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e, st) {
      if (!mounted || !context.mounted) return;

      final message =
          e is ClientException ? mapAuthError(e) : "Registration failed";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      log("Registration failed", error: e, stackTrace: st);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        suffixIcon: suffix,
      );

  void _validateUsername(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _usernameError = "Username is required";
      } else if (value.trim().length < 3) {
        _usernameError = "Minimum 3 characters";
      } else {
        _usernameError = null;
      }
    });
  }

  void _validateEmail(String value) {
    setState(() {
      final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
      if (value.trim().isEmpty) {
        _emailError = "Email is required";
      } else if (!emailRegex.hasMatch(value.trim())) {
        _emailError = "Enter a valid email";
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = "Password is required";
      } else if (value.length < 8) {
        _passwordError = "Minimum 8 characters";
      } else if (!RegExp(r'\d').hasMatch(value)) {
        _passwordError = "Include at least 1 number";
      } else {
        _passwordError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 8,
            shadowColor: theme.primaryColor.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Create Account", style: textTheme.titleLarge)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, duration: 400.ms),
                    const SizedBox(height: 24),

                    // Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: _inputDecoration("Username"),
                      onChanged: _validateUsername,
                      validator: (_) => _usernameError,
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration("Email"),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: _validateEmail,
                      validator: (_) => _emailError,
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecoration(
                        "Password",
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed:
                              () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      onChanged: _validatePassword,
                      validator: (_) => _passwordError,
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
                    const SizedBox(height: 24),

                    // Register button
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text("Register"),
                        ).animate().shake(duration: 300.ms),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed:
                          () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          ),
                      child: const Text("Already have an account? Login"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
