import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/admin_router.dart';
import '../../app/admin_navigation.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../utils/i18n.dart';

/// شاشة تسجيل دخول مسؤول المطعم.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _maybeAutoNavigate();
  }

  Future<void> _maybeAutoNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getBool('is_admin_mode') ?? false;
    if (isAdmin && mounted) {
      // Delay until after first frame so GoRouter/context are ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AdminRoutes.orders);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authViewModelProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
    final authState = ref.read(authViewModelProvider);
    if (authState.isAdmin && authState.restaurantId != null) {
      if (mounted) {
        context.go(AdminRoutes.orders);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    ref.listen<AuthState>(authViewModelProvider, (_, state) {
      if (state.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        t(context, 'Restaurant Admin Panel', 'Панель администратора'),
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: t(context, 'Email', 'Электронная почта'),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return t(
                              context,
                              'Please enter your email',
                              'Пожалуйста, введите email',
                            );
                          }
                          final emailRegex = RegExp(r'^.+@.+\..+$');
                          if (!emailRegex.hasMatch(value)) {
                            return t(
                              context,
                              'Invalid email format',
                              'Неверный формат email',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: t(context, 'Password', 'Пароль'),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return t(
                              context,
                              'Please enter your password',
                              'Пожалуйста, введите пароль',
                            );
                          }
                          if (value.length < 6) {
                            return t(
                              context,
                              'Password must be at least 6 characters',
                              'Пароль должен быть не менее 6 символов',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: authState.isLoading ? null : _submit,
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(t(context, 'Sign In', 'Войти')),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => switchToUserMode(context, ref),
                        icon: const Icon(Icons.person_outline),
                        label: Text(
                          t(context, 'Back to User Mode', 'Вернуться в режим пользователя'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
