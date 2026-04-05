import 'dart:async';

import 'package:flutter/material.dart';
import '../controllers/cart_controller.dart';
import '../models/product.dart';
import '../l10n/app_localizations.dart';
import '../utils/responsive_helper.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key, required this.cart});
  final CartController cart;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  String? _pressedCategoryId;
  late final TextEditingController _searchController;
  Timer? _typingTimer;
  bool _isUserEditing = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _startTypingAnimation();
    _typingTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _isUserEditing = true;
      _typingTimer?.cancel();
      _searchController.clear();
      _handleSearchChanged('');
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      {'id': 'all', 'name': l10n.all, 'icon': Icons.restaurant_menu},
      {'id': 'fries', 'name': l10n.fries, 'icon': Icons.local_fire_department},
      {'id': 'sandwiches', 'name': l10n.sandwiches, 'icon': Icons.lunch_dining},
      {'id': 'meals', 'name': l10n.mainMeals, 'icon': Icons.dinner_dining},
      {'id': 'drinks', 'name': l10n.drinks, 'icon': Icons.local_drink},
      {'id': 'desserts', 'name': l10n.desserts, 'icon': Icons.cake},
    ];
  }

  List<Product> _getFilteredProducts() {
    final base = _selectedCategory == 'all'
        ? demoProducts
        : demoProducts.where((p) => p.category == _selectedCategory);
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return base.toList();
    }
    return base.where((p) => p.name.toLowerCase().contains(query)).toList();
  }

  void _startTypingAnimation() {
    const target = 'Fast Food';
    _typingTimer?.cancel();
    _isUserEditing = false;

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || _isUserEditing) return;
      var index = 0;
      _typingTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
        if (!mounted || _isUserEditing) {
          timer.cancel();
          return;
        }
        index++;
        if (index > target.length) {
          timer.cancel();
          return;
        }
        final text = target.substring(0, index);
        _searchController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        setState(() => _searchQuery = text);
      });
    });
  }

  void _handleSearchChanged(String value) {
    if (!_isUserEditing) {
      _isUserEditing = true;
      _typingTimer?.cancel();
    }
    setState(() => _searchQuery = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filteredProducts = _getFilteredProducts();
    final categories = _getCategories(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: false,
            delegate: _MenuHeaderDelegate(
              title: l10n.foodMenu,
              isMobile: ResponsiveHelper.isMobile(context),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: ResponsiveHelper.isMobile(context) ? 12 : 16),
          ),
          SliverToBoxAdapter(child: _buildSearchBar(context)),
          SliverToBoxAdapter(
            child: SizedBox(height: ResponsiveHelper.isMobile(context) ? 4 : 8),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: ResponsiveHelper.isMobile(context) ? 100.0 : 120.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.isMobile(context) ? 16.0 : 24.0,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory == category['id'];
                  final isPressed = _pressedCategoryId == category['id'];
                  final categoryWidth =
                      ResponsiveHelper.isMobile(context) ? 90.0 : 110.0;

                  return AnimatedScale(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    scale: isPressed ? 0.96 : 1.0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            setState(() => _selectedCategory = category['id']),
                        onTapDown: (_) => setState(
                          () => _pressedCategoryId = category['id'],
                        ),
                        onTapUp: (_) =>
                            setState(() => _pressedCategoryId = null),
                        onTapCancel: () =>
                            setState(() => _pressedCategoryId = null),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          width: categoryWidth,
                          margin: EdgeInsets.only(
                            right: ResponsiveHelper.isMobile(context)
                                ? 8.0
                                : 12.0,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.red.withOpacity(0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                width: ResponsiveHelper.isMobile(context)
                                    ? 50.0
                                    : 60.0,
                                height: ResponsiveHelper.isMobile(context)
                                    ? 50.0
                                    : 60.0,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.red.shade700
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.25),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Icon(
                                  category['icon'],
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  size:
                                      ResponsiveHelper.getSmallIconSize(context),
                                ),
                              ),
                              SizedBox(
                                height: ResponsiveHelper.isMobile(context)
                                    ? 2.0
                                    : 4.0,
                              ),
                              Text(
                                category['name'],
                                style: TextStyle(
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                    context,
                                    mobileSize: 10,
                                    tabletSize: 11,
                                    desktopSize: 12,
                                  ),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.red.shade700
                                      : Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveHelper.getGridColumns(context),
                childAspectRatio: 0.75,
                crossAxisSpacing:
                    ResponsiveHelper.isMobile(context) ? 12.0 : 16.0,
                mainAxisSpacing:
                    ResponsiveHelper.isMobile(context) ? 12.0 : 16.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = filteredProducts[index];
                  return _buildProductCard(product, context, index);
                },
                childCount: filteredProducts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    Product product,
    BuildContext context,
    int index,
  ) {
    return _AnimatedProductCard(
      key: ValueKey('${product.id}-$_selectedCategory'),
      product: product,
      index: index,
      onAddToCart: () => _addToCart(product, context),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isMobile(context) ? 16 : 24,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onTap: () {
            if (!_isUserEditing) {
              _isUserEditing = true;
              _typingTimer?.cancel();
            }
          },
          onChanged: _handleSearchChanged,
          decoration: InputDecoration(
            hintText: l10n.search,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _handleSearchChanged('');
                    },
                  ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              vertical: ResponsiveHelper.isMobile(context) ? 12 : 16,
              horizontal: 16,
            ),
          ),
        ),
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

  void _addToCart(Product product, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    widget.cart.add(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ${l10n.addedToCart}'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _AnimatedProductCard extends StatefulWidget {
  const _AnimatedProductCard({
    super.key,
    required this.product,
    required this.index,
    required this.onAddToCart,
  });

  final Product product;
  final int index;
  final VoidCallback onAddToCart;

  @override
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final l10n = AppLocalizations.of(context);
    final scale = _pressed ? 0.98 : (_hovered ? 1.01 : 1.0);
    final shadowBlur = _pressed ? 10.0 : (_hovered ? 18.0 : 14.0);
    final shadowOffset = _pressed ? 4.0 : (_hovered ? 8.0 : 6.0);

    return _AppearOnMount(
      delay: Duration(milliseconds: 60 * widget.index),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: scale,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: shadowBlur,
                  offset: Offset(0, shadowOffset),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {},
                onTapDown: (_) => _setPressed(true),
                onTapUp: (_) => _setPressed(false),
                onTapCancel: () => _setPressed(false),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: product.imageUrl != null
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.asset(
                                  product.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: _getCategoryColor(product.category),
                                      child: Icon(
                                        _getCategoryIcon(product.category),
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                color: _getCategoryColor(product.category),
                                child: Icon(
                                  _getCategoryIcon(product.category),
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: EdgeInsets.all(
                          ResponsiveHelper.isMobile(context) ? 10 : 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  mobileSize: 12,
                                  tabletSize: 14,
                                  desktopSize: 16,
                                ),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Text(
                              '${product.price} RUB',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  mobileSize: 14,
                                  tabletSize: 16,
                                  desktopSize: 18,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: ResponsiveHelper.isMobile(context)
                                  ? 6.0
                                  : 8.0,
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: ResponsiveHelper.getButtonHeight(context),
                              child: ElevatedButton(
                                onPressed: widget.onAddToCart,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  l10n.addToCart,
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      mobileSize: 12,
                                      tabletSize: 14,
                                      desktopSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

class _AppearOnMount extends StatefulWidget {
  const _AppearOnMount({
    required this.child,
    required this.delay,
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<_AppearOnMount> createState() => _AppearOnMountState();
}

class _AppearOnMountState extends State<_AppearOnMount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_opacity);

    _timer = Timer(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class _MenuHeaderDelegate extends SliverPersistentHeaderDelegate {
  _MenuHeaderDelegate({
    required this.title,
    required this.isMobile,
  });

  final String title;
  final bool isMobile;

  @override
  double get maxExtent => isMobile ? 220 : 260;

  @override
  double get minExtent => isMobile ? 120 : 140;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final iconScale = 1.0 - (0.2 * progress);

    return Container(
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0xFFFFE08A), Colors.white, progress),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05 + (0.08 * progress)),
            blurRadius: 8 + (6 * progress),
            offset: Offset(0, 4 + (2 * progress)),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 16 : 20,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: isMobile ? 10 : 14),
          Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: iconScale,
              child: Icon(
                Icons.fastfood,
                size: isMobile ? 64 : 72,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MenuHeaderDelegate oldDelegate) {
    return title != oldDelegate.title || isMobile != oldDelegate.isMobile;
  }
}
