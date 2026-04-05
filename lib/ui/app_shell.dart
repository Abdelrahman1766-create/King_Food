import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../controllers/cart_controller.dart';
import '../models/product.dart';
import 'menu_page.dart';
import 'cart_page.dart';
import 'account_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  late final CartController _cart;

  @override
  void initState() {
    super.initState();
    _cart = CartController();
  }

  @override
  void dispose() {
    _cart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final pages = <Widget>[
      MenuPage(cart: _cart),
      CartPage(cart: _cart),
      const AccountPage(),
    ];

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 189, 10, 4),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            if (user == null) {
              return const Text(
                'FAST FOOD',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2),
              );
            }

            final displayName = _displayNameForUser(user);
            if (displayName.isEmpty) {
              return const Text(
                'FAST FOOD',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'FAST FOOD',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => setState(() => _currentIndex = 1),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_menu),
            label: l10n.tabMenu,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart),
            label: l10n.tabCart,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l10n.tabAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 189, 10, 4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.fastfood, size: 48, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'FAST FOOD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete Menu',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'All Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 189, 10, 4),
              ),
            ),
          ),
          ...demoProducts.map(
            (product) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _getCategoryColor(product.category),
                child: Icon(
                  _getCategoryIcon(product.category),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(product.name),
              subtitle: Text('${product.price} RUB'),
              trailing: Text(
                product.category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'fries':
        return Colors.orange.shade600;
      case 'sandwiches':
        return Colors.brown.shade600;
      case 'meals':
        return Colors.green.shade600;
      case 'drinks':
        return Colors.blue.shade600;
      case 'desserts':
        return Colors.pink.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'fries':
        return Icons.local_fire_department;
      case 'sandwiches':
        return Icons.lunch_dining;
      case 'meals':
        return Icons.dinner_dining;
      case 'drinks':
        return Icons.local_drink;
      case 'desserts':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
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
}
