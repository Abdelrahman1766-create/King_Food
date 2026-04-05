import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../driver_app/app/driver_app.dart';
import '../restaurant_admin/app/admin_app.dart';
import '../restaurant_admin/core/admin_constants.dart';
import '../restaurant_admin/domain/entities/driver.dart';
import 'my_orders_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // Simple translation helper
  String _getText(BuildContext context, String enText, String ruText) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ru' ? ruText : enText;
  }

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 189, 10, 4),
        foregroundColor: Colors.white,
        title: Text(
          _isLogin
              ? _getText(context, 'Sign In', 'Войти')
              : _getText(context, 'Register', 'Регистрация'),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or Icon
            const Icon(
              Icons.fastfood,
              size: 80,
              color: Color.fromARGB(255, 189, 10, 4),
            ),
            const SizedBox(height: 32),

            // Name field (only for registration)
            if (!_isLogin) ...[
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _getText(context, 'Full Name', 'Полное имя'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Email field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: _getText(context, 'Email', 'Электронная почта'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: _getText(context, 'Password', 'Пароль'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 189, 10, 4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isLogin
                            ? _getText(context, 'Sign In', 'Войти')
                            : _getText(context, 'Register', 'Регистрация'),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Toggle between login and register
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
              child: Text(
                _isLogin
                    ? _getText(
                        context,
                        'Don\'t have an account? Register',
                        'Нет аккаунта? Зарегистрироваться',
                      )
                    : _getText(
                        context,
                        'Already have an account? Sign In',
                        'Уже есть аккаунт? Войти',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // Check if fields are empty
    if (email.isEmpty || password.isEmpty || (!_isLogin && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getText(
              context,
              'Please fill all required fields',
              'Пожалуйста, заполните все обязательные поля',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate email format
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getText(
              context,
              'Please enter a valid email address',
              'Пожалуйста, введите действительный адрес электронной почты',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getText(
              context,
              'Password must be at least 6 characters',
              'Пароль должен содержать не менее 6 символов',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate name (for registration)
    if (!_isLogin && name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getText(
              context,
              'Name must be at least 2 characters',
              'Имя должно содержать не менее 2 символов',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // If this is the special admin account, switch to admin mode
      if (email == 'admin1871000@gmail.com' && password == '18719900') {
        try {
          await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            await auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } else {
            rethrow;
          }
        }

        final currentUser = auth.currentUser;
        if (currentUser != null) {
          try {
            await firestore
                .collection(AdminConstants.usersCollection)
                .doc(currentUser.uid)
                .set({
              'displayName': 'Admin',
              'email': email,
              'role': AdminConstants.adminRole,
              'restaurantId': 'demo_restaurant',
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (e) {
            // Firestore rules might block this; still allow admin mode.
            // ignore: avoid_print
            print('Admin profile write failed: $e');
          }
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_admin_mode', true);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminApp()),
        );
        return;
      }

      if (_isLogin) {
        await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final currentUser = auth.currentUser;
        if (currentUser != null) {
          final doc = await firestore
              .collection(AdminConstants.usersCollection)
              .doc(currentUser.uid)
              .get();
          final role = doc.data()?['role'] as String?;
          if (role == AdminConstants.adminRole) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_admin_mode', true);
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminApp()),
            );
            return;
          }
        }

        if (currentUser != null && _isDriverUser(currentUser.uid)) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const ProviderScope(child: DriverApp()),
            ),
          );
          return;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getText(
                context,
                'Signed in successfully!',
                'Вход выполнен успешно!',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(name);

      if (credential.user != null) {
        await firestore
            .collection(AdminConstants.usersCollection)
            .doc(credential.user!.uid)
            .set({
          'displayName': name,
          'email': email,
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MyOrdersPage(welcomeName: name)),
      );
    } on FirebaseAuthException catch (e) {
      // Log the exact auth error for easier debugging in dev builds.
      // ignore: avoid_print
      print('FirebaseAuth error: ${e.code} - ${e.message}');

      final message = _authErrorMessage(e.code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getText(
              context,
              'Something went wrong. Please try again.',
              'Произошла ошибка. Пожалуйста, попробуйте еще раз.',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    // Basic email validation regex
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  bool _isDriverUser(String uid) {
    return demoDrivers.any((driver) => driver.id == uid);
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return _getText(
          context,
          'Account not found. Please register first.',
          'Аккаунт не найден. Пожалуйста, зарегистрируйтесь.',
        );
      case 'wrong-password':
        return _getText(
          context,
          'Incorrect password.',
          'Неверный пароль.',
        );
      case 'email-already-in-use':
        return _getText(
          context,
          'This email is already in use.',
          'Этот email уже используется.',
        );
      case 'invalid-email':
        return _getText(
          context,
          'Invalid email address.',
          'Неверный адрес электронной почты.',
        );
      case 'weak-password':
        return _getText(
          context,
          'Password is too weak.',
          'Слишком простой пароль.',
        );
      case 'network-request-failed':
        return _getText(
          context,
          'Network error. Please check your internet connection.',
          'Ошибка сети. Проверьте интернет‑соединение.',
        );
      case 'operation-not-allowed':
        return _getText(
          context,
          'Email/Password sign-in is not enabled in Firebase.',
          'В Firebase не включен вход по Email/Password.',
        );
      case 'too-many-requests':
        return _getText(
          context,
          'Too many attempts. Please try again later.',
          'Слишком много попыток. Попробуйте позже.',
        );
      default:
        return _getText(
          context,
          'Authentication failed. Please try again.',
          'Ошибка входа. Пожалуйста, попробуйте снова.',
        );
    }
  }
}




