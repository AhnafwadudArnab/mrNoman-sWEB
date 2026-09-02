import 'package:flutter/material.dart';

import 'A_Help.dart';
import 'A_Reports.dart';
import 'A_Settings.dart';
import 'A_banners.dart';
import 'A_brands.dart';
import 'A_carts.dart';
import 'A_collections.dart';
import 'A_deals.dart';
import 'A_deals_timer.dart';
import 'A_delivery_settings.dart';
import 'A_discounts.dart';
import 'A_flash_sales.dart';
import 'A_orders.dart';
import 'A_products.dart';
import 'A_promotions.dart';
import 'A_branding_logo.dart';
import 'Admin_sidebar.dart';
import 'admin_dashboard_page.dart';
import 'A_payments.dart';
import 'A_ssl_settings.dart';

/// Returns the admin page widget for the given sidebar item (embedded mode).
/// Use this to avoid circular imports between admin pages.
Widget? getAdminPage(AdminSidebarItem item) {
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
    case AdminSidebarItem.carts:
      return const AdminCartsPage(embedded: true);
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
    case AdminSidebarItem.flashSales:
      return const AdminFlashSalesPage(embedded: true);
    case AdminSidebarItem.promotions:
      return const AdminPromotionsPage(embedded: true);
    case AdminSidebarItem.banners:
      return const AdminBannersPage(embedded: true);
    case AdminSidebarItem.help:
      return const AdminHelpPage(embedded: true);
    case AdminSidebarItem.settings:
      return const AdminSettingsPage(embedded: true);
    case AdminSidebarItem.viewStore:
      return null;
    case AdminSidebarItem.featuredBrands:
      return const AdminBrandingLogoPage(embedded: true);
    case AdminSidebarItem.sslSettings:
      return const AdminSslSettingsPage(embedded: true);
  }
}

