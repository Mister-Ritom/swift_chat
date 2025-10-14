import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:swift_chat/app.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'package:swift_chat/pages/auth/login_page.dart';
import '../../providers/user_provider.dart';
import '../../utils/mapping.dart';

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

  List<String> _usernameSuggestions = [];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(userProvider.notifier)
          .register(
            _usernameController.text.trim().toLowerCase(),
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (!mounted || !context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const App()),
      );
    } catch (e, st) {
      if (!mounted || !context.mounted) return;
      log("Registration failed", error: e, stackTrace: st);
      final message =
          e is ClientException ? mapAuthError(e) : "Registration failed";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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

  Timer? _debounce;

  /// Validate username with availability check
  Future<void> _validateUsername(String username) async {
    // Cancel previous pending check
    _debounce?.cancel();

    // Start debounce
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final pb = PBClient.instance;
      final clean = username.trim().toLowerCase();

      try {
        // Check if username exists
        await pb.collection('users').getFirstListItem('username="$clean"');

        // Exists → username taken
        setState(() {
          _usernameError = "Username already taken";
          _usernameSuggestions = [];

          // Generate up to 3 dynamic suggestions
          for (int i = 0, n = 0; n < 3 && i < 50; i++) {
            final candidate =
                "$clean${DateTime.now().millisecondsSinceEpoch % 10000 + i}";
            if (!_usernameSuggestions.contains(candidate)) {
              _usernameSuggestions.add(candidate);
              n++;
            }
          }
        });
      } on ClientException catch (e) {
        if (e.statusCode == 404) {
          // Not found → available
          setState(() {
            _usernameError = null;
            _usernameSuggestions = [];
          });
        } else {
          log("Error checking username: $e");
        }
      } catch (e) {
        log("Error checking username: $e");
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
                      onChanged: (val) => _validateUsername(val),
                      validator: (_) => _usernameError,
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
                    if (_usernameSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            _usernameSuggestions
                                .map(
                                  (s) => ActionChip(
                                    label: Text(s),
                                    onPressed: () {
                                      _usernameController.text = s;
                                      _validateUsername(s);
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                    ],
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
