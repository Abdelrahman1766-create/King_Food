import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_page.dart';
import 'addresses_page.dart';
import '../providers/language_provider.dart';
import 'my_orders_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // Simple translation helper
  String _getText(BuildContext context, String enText, String ruText) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ru' ? ruText : enText;
  }

  String _displayNameForUser(User user) {
    final name = (user.displayName ?? '').trim();
    if (name.isNotEmpty) return name;
    final email = (user.email ?? '').trim();
    if (email.isNotEmpty) {
      final atIndex = email.indexOf('@');
      return atIndex > 0 ? email.substring(0, atIndex) : email;
    }
    return '';
  }

  Widget _buildUserHeader(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const SizedBox.shrink();

        final displayName = _displayNameForUser(user);
        final email = (user.email ?? '').trim();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 189, 10, 4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Color.fromARGB(255, 189, 10, 4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (displayName.isNotEmpty)
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildUserHeader(context),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.login),
          title: Text(
            _getText(
              context,
              'Sign in / Register',
              'Войти / Зарегистрироваться',
            ),
          ),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const AuthPage()));
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(_getText(context, 'Addresses', 'Адреса')),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddressesPage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.receipt_long),
          title: Text(_getText(context, 'My Orders', 'Мои заказы')),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MyOrdersPage()),
            );
          },
        ),
        const Divider(),
        // Admin Panel entry removed from user account page. Admin access is
        // available only by signing in with the special admin credentials.
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(_getText(context, 'Language', 'Язык')),
          subtitle: Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return Text(
                languageProvider.locale.languageCode == 'ru'
                    ? 'Русский'
                    : 'English',
              );
            },
          ),
          onTap: () {
            _showLanguageDialog(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(_getText(context, 'Logout', 'Выйти')),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _getText(
                    context,
                    'Signed out successfully.',
                    'Вы вышли из аккаунта.',
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return AlertDialog(
              title: const Text('Select Language'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('English'),
                    trailing: languageProvider.locale.languageCode == 'en'
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      languageProvider.changeLanguage('en');
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    title: const Text('Русский'),
                    trailing: languageProvider.locale.languageCode == 'ru'
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      languageProvider.changeLanguage('ru');
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

