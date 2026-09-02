import 'package:flutter/material.dart';
import 'Admin_sidebar.dart';
import '../pages/home_page.dart';
import 'admin_theme.dart';

/// Responsive admin scaffold — desktop: persistent sidebar, mobile: Drawer
class AdminScaffold extends StatelessWidget {
  static const double mobileBreakpoint = 700;

  final AdminSidebarItem selected;
  final Widget body;
  final ValueChanged<AdminSidebarItem>? onItemSelected;

  const AdminScaffold({
    super.key,
    required this.selected,
    required this.body,
    this.onItemSelected,
  });

  void _handleItem(BuildContext context, AdminSidebarItem item) {
    if (item == AdminSidebarItem.viewStore) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
      return;
    }
    onItemSelected?.call(item);
  }

  /// Whether the screen is mobile-sized
  static bool isMobileScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static double desktopSidebarWidth(double screenWidth) {
    return (screenWidth * 0.24).clamp(220.0, 300.0);
  }

  static double drawerSidebarWidth(double screenWidth) {
    return (screenWidth * 0.88).clamp(240.0, 300.0);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = isMobileScreen(context);
    final desktopSidebarWidth = AdminScaffold.desktopSidebarWidth(screenWidth);
    final drawerSidebarWidth = AdminScaffold.drawerSidebarWidth(screenWidth);

    // Theme colors
    final pageBackground = AdminTheme.bg;
    final surfaceBackground = AdminTheme.surface;
    final brandOrange = AdminTheme.brand;

    return Scaffold(
      backgroundColor: pageBackground,
      drawer: isMobile
          ? Drawer(
              width: drawerSidebarWidth,
              child: AdminSidebar(
                sidebarWidth: drawerSidebarWidth,
                selected: selected,
                onItemSelected: (item) {
                  Navigator.pop(context);
                  _handleItem(context, item);
                },
              ),
            )
          : null,
      appBar: isMobile
          ? AppBar(
              backgroundColor: surfaceBackground,
              foregroundColor: AdminTheme.textPrimary,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: AdminTheme.brand),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  tooltip: 'Menu',
                ),
              ),
              title: Text(
                _label(selected),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: const IconThemeData(color: AdminTheme.brand),
              actions: [
                // Back button — goes back if possible, else goes to store
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AdminTheme.brand),
                  tooltip: 'Back',
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile)
            AdminSidebar(
              sidebarWidth: desktopSidebarWidth,
              selected: selected,
              onItemSelected: (item) => _handleItem(context, item),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }

  static String _label(AdminSidebarItem item) {
    switch (item) {
      case AdminSidebarItem.dashboard:
        return 'Dashboard';
      case AdminSidebarItem.orders:
        return 'Orders';
      case AdminSidebarItem.products:
        return 'Products';
      case AdminSidebarItem.collections:
        return 'Collections';
      case AdminSidebarItem.brands:
        return 'Brands';
      case AdminSidebarItem.payments:
        return 'Payments';
      case AdminSidebarItem.deliverySettings:
        return 'Delivery';
      case AdminSidebarItem.reports:
        return 'Reports';
      case AdminSidebarItem.discounts:
        return 'Discounts';
      case AdminSidebarItem.deals:
        return 'Deals';
      case AdminSidebarItem.dealsTimer:
        return 'Deals Timer';
      case AdminSidebarItem.featuredBrands:
        return 'Featured Brands';
      case AdminSidebarItem.flashSales:
        return 'Flash Sales';
      case AdminSidebarItem.promotions:
        return 'Promotions';
      case AdminSidebarItem.banners:
        return 'Banners';
      case AdminSidebarItem.help:
        return 'Help';
      case AdminSidebarItem.carts:
        return 'Carts';
      case AdminSidebarItem.settings:
        return 'Settings';
      case AdminSidebarItem.sslSettings:
        return 'SSL Settings';
      case AdminSidebarItem.viewStore:
        return 'Store';
    }
  }
}

/// Helper widget — hides the page's own header bar on mobile
/// (since AdminScaffold already shows an AppBar on mobile)
class AdminPageHeader extends StatelessWidget {
  final List<Widget> children;
  final Color? color;

  const AdminPageHeader({super.key, required this.children, this.color});

  @override
  Widget build(BuildContext context) {
    final isMobile = AdminScaffold.isMobileScreen(context);
    // On mobile, AdminScaffold already shows AppBar — hide the page header
    if (isMobile) return const SizedBox.shrink();
    return Container(
      height: 70,
      color: color ?? AdminTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children,
          ),
        ),
      ),
    );
  }
}
