import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/user_provider.dart';
import '../../utils/mapping.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(userProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text.trim());
    } catch (e, st) {
      if (!mounted || !context.mounted) return;
      final message = e is ClientException ? mapAuthError(e) : "Login failed";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      log("Login failed", error: e, stackTrace: st);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(
    String label, {
    Widget? suffix,
    IconData? icon,
  }) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Theme.of(context).cardColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    prefixIcon: icon != null ? Icon(icon) : null,
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                        "assets/icons/swift_chat.png",
                        width: 80,
                        height: 80,
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.2, duration: 400.ms),
                  const SizedBox(height: 24),

                  // Title
                  Text("Welcome Back", style: textTheme.titleLarge)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, duration: 400.ms),
                  const SizedBox(height: 8),
                  Text(
                    "Login to continue your journey",
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Email Field
                  TextField(
                    controller: _emailController,
                    decoration: _inputDecoration(
                      "Email",
                      icon: Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
                  const SizedBox(height: 16),

                  // Password Field
                  TextField(
                    controller: _passwordController,
                    decoration: _inputDecoration(
                      "Password",
                      icon: Icons.lock_outline,
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
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2),
                  const SizedBox(height: 24),

                  // Login Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text("Login"),
                        ).animate().shake(duration: 300.ms),
                      ),
                  const SizedBox(height: 16),

                  // Go to Register Page
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don’t have an account?",
                        style: textTheme.bodySmall,
                      ),
                      TextButton(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            ),
                        child: Text(
                          "Register",
                          style: textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
