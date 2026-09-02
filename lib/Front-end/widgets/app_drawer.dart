import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../All Pages/CART/Cart_provider.dart';
import '../All Pages/CART/Orders.dart';
import '../All Pages/Categories All/SideCatePages/KitchenAppliances.dart';
import '../pages/Profiles/Profile.dart';
import '../pages/Profiles/WishLists.dart';
import '../pages/home_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.orangeAccent],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 35, color: Colors.orange),
                ),
                SizedBox(height: 10),
                Text(
                  'ElectroZoneBD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KitchenAppliancesPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart_outlined),
            title: const Text('Cart'),
            onTap: () {
              Navigator.pop(context);
              final cart = context.read<CartProvider>();
              if (cart.items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your cart is empty. Add some products first!'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              final subtotal = cart.getCartTotal();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubmitOrderPage(totalAmount: subtotal),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Wishlist'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WishlistPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'ElectroZoneBD',
                applicationVersion: '1.0.0',
                applicationLegalese: '\u00a9 2025 ElectroZoneBD',
              );
            },
          ),
        ],
      ),
    );
  }
}
