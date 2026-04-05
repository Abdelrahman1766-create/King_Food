import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/cart_controller.dart';
import 'checkout_page.dart';
import '../l10n/app_localizations.dart';
import '../utils/responsive_helper.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key, required this.cart});
  final CartController cart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        final items = cart.items;
        final currency = NumberFormat.simpleCurrency(
          locale: Localizations.localeOf(context).toString(),
        );
        if (items.isEmpty) {
          return Center(child: Text(l10n.yourCartIsEmpty));
        }
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final ci = items[index];
                  return ListTile(
                    title: Text(
                      ci.product.name,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobileSize: 14,
                          tabletSize: 16,
                          desktopSize: 18,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'x${ci.quantity}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobileSize: 12,
                          tabletSize: 13,
                          desktopSize: 14,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currency.format(ci.product.price * ci.quantity),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobileSize: 13,
                              tabletSize: 14,
                              desktopSize: 15,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline,
                            size: ResponsiveHelper.getSmallIconSize(context),
                          ),
                          onPressed: () => cart.decrease(ci.product.id),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: ResponsiveHelper.getSmallIconSize(context),
                          ),
                          onPressed: () => cart.remove(ci.product.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      ResponsiveHelper.isMobile(context) ? 12.0 : 16.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${l10n.total}: ${currency.format(cart.total)}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobileSize: 16,
                          tabletSize: 18,
                          desktopSize: 20,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.isMobile(context) ? 12.0 : 16.0,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: ResponsiveHelper.getButtonHeight(context),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CheckoutPage(cart: cart),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        l10n.checkout,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobileSize: 14,
                            tabletSize: 16,
                            desktopSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
