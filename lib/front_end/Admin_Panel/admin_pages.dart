import 'package:flutter/material.dart';

import 'package:electrocitybd1/front_end/Admin_Panel/A_Help.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_Reports.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_Settings.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_banners.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_brands.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_carts.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_collections.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_deals.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_deals_timer.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_delivery_settings.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_discounts.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_flash_sales.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_orders.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_products.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_promotions.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_branding_logo.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/Admin_sidebar.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_dashboard_page.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_payments.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_ssl_settings.dart';

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



