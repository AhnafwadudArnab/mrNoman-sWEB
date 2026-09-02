import 'package:flutter/material.dart';

import 'A_Help.dart';
import 'A_Reports.dart';
import 'A_Settings.dart';
import 'A_banners.dart';
import 'A_brands.dart';
import 'A_branding_logo.dart';
import 'A_carts.dart';
import 'A_collections.dart';
import 'A_deals.dart';
import 'A_deals_timer.dart';
import 'A_delivery_settings.dart';
import 'A_discounts.dart';
import 'A_flash_sales.dart';
import 'A_promotions.dart';
import 'A_orders.dart';
import 'A_products.dart';
import 'Admin_sidebar.dart';
import 'admin_dashboard_page.dart';
import '../pages/home_page.dart';
import 'A_payments.dart';
import 'A_ssl_settings.dart';
import 'admin_scaffold.dart';

/// Provides sidebar navigation to any embedded admin page via context.
/// Usage: AdminNav.of(context).navigateTo(AdminSidebarItem.orders)
class AdminNav extends InheritedWidget {
  final void Function(AdminSidebarItem item) navigateTo;

  const AdminNav({super.key, required this.navigateTo, required super.child});

  static AdminNav? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdminNav>();

  /// Navigates within AdminLayoutPage if embedded, otherwise falls back to
  /// pushing a new AdminLayoutPage route.
  static void go(BuildContext context, AdminSidebarItem item) {
    final nav = maybeOf(context);
    if (nav != null) {
      nav.navigateTo(item);
    } else {
      if (item == AdminSidebarItem.viewStore) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminLayoutPage(initialItem: item)),
      );
    }
  }

  @override
  bool updateShouldNotify(AdminNav oldWidget) =>
      navigateTo != oldWidget.navigateTo;
}

class AdminLayoutPage extends StatefulWidget {
  final AdminSidebarItem initialItem;

  const AdminLayoutPage({
    super.key,
    this.initialItem = AdminSidebarItem.dashboard,
  });

  @override
  State<AdminLayoutPage> createState() => _AdminLayoutPageState();
}

class _AdminLayoutPageState extends State<AdminLayoutPage> {
  late AdminSidebarItem selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialItem;
  }

  void _handleItem(BuildContext context, AdminSidebarItem item) {
    if (item == AdminSidebarItem.viewStore) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
      return;
    }
    setState(() => selected = item);
  }

  Widget _buildPage(AdminSidebarItem item) {
    switch (item) {
      case AdminSidebarItem.dashboard:
        return const AdminDashboardPage(embedded: true);
      case AdminSidebarItem.orders:
        return const AdminOrdersPage(embedded: true);
      case AdminSidebarItem.products:
        return const AdminProductUploadPage(embedded: true);
      case AdminSidebarItem.collections:
        return const AdminCollectionsPage(embedded: true);
      case AdminSidebarItem.brands:
        return const AdminBrandsPage(embedded: true);
      case AdminSidebarItem.payments:
        return const AdminPaymentsPage(embedded: true);
      case AdminSidebarItem.deliverySettings:
        return const AdminDeliverySettingsPage(embedded: true);
      case AdminSidebarItem.reports:
        return const AdminReportsPage(embedded: true);
      case AdminSidebarItem.discounts:
        return const AdminDiscountPage(embedded: true);
      case AdminSidebarItem.deals:
        return const AdminDealsPage(embedded: true);
      case AdminSidebarItem.dealsTimer:
        return const AdminDealsTimerPage(embedded: true);
      case AdminSidebarItem.featuredBrands:
        return const AdminBrandingLogoPage(embedded: true);
      case AdminSidebarItem.flashSales:
        return const AdminFlashSalesPage(embedded: true);
      case AdminSidebarItem.promotions:
        return const AdminPromotionsPage(embedded: true);
      case AdminSidebarItem.banners:
        return const AdminBannersPage(embedded: true);
      case AdminSidebarItem.help:
        return const AdminHelpPage(embedded: true);
      case AdminSidebarItem.carts:
        return const AdminCartsPage(embedded: true);
      case AdminSidebarItem.settings:
        return const AdminSettingsPage(embedded: true);
      case AdminSidebarItem.sslSettings:
        return const AdminSslSettingsPage(embedded: true);
      case AdminSidebarItem.viewStore:
        return const AdminDashboardPage(embedded: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selected: selected,
      onItemSelected: (item) => _handleItem(context, item),
      body: AdminNav(
        navigateTo: (item) => _handleItem(context, item),
        child: KeyedSubtree(
          key: ValueKey(selected),
          child: _buildPage(selected),
        ),
      ),
    );
  }
}


