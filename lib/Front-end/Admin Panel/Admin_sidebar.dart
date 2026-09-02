import 'package:flutter/material.dart';

import 'admin_theme.dart';

enum AdminSidebarItem {
  dashboard,
  orders,
  carts,
  products,
  collections,
  brands,
  payments,
  deliverySettings,
  banners,
  reports,
  discounts,
  deals,
  dealsTimer,
  flashSales,
  promotions,
  help,
  settings,
  viewStore,
  featuredBrands,
  sslSettings,
}

class AdminSidebar extends StatelessWidget {
  final AdminSidebarItem selected;
  final ValueChanged<AdminSidebarItem> onItemSelected;
  final double sidebarWidth;

  const AdminSidebar({
    super.key,
    required this.selected,
    required this.onItemSelected,
    this.sidebarWidth = 260,
  });

  @override
  Widget build(BuildContext context) {
    final brandOrange = AdminTheme.brand;
    const Color darkBg = Color(0xFF0D1117);
    const Color darkSurface = Color(0xFF161B22);
    const Color darkBorder = Color(0xFF30363D);
    const Color activeBackground = Color(0x1AF59E0B);
    final inactiveGrey = AdminTheme.darkTextSecondary;
    final textWhite = AdminTheme.darkTextPrimary;

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: darkSurface,
        border: Border(right: BorderSide(color: darkBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          /// LOGO + BACK BUTTON SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Back button
                InkWell(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2333),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: Color(0xFF8B949E),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: brandOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Admin Panel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textWhite,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          /// MENU ITEMS
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSidebarItem(
                    item: AdminSidebarItem.dashboard,
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    onItemSelected: onItemSelected,
                    activeColor: brandOrange,
                    activeBg: activeBackground,
                    inactiveColor: inactiveGrey,
                  ),
                  _buildSidebarItem(
                    item: AdminSidebarItem.orders,
                    icon: Icons.shopping_bag_outlined,
                    label: 'Orders',
                    onItemSelected: onItemSelected,
                    activeColor: brandOrange,
                    activeBg: activeBackground,
                    inactiveColor: inactiveGrey,
                  ),
                  _buildSidebarItem(
                    item: AdminSidebarItem.products,
                    icon: Icons.inventory_2_outlined,
                    label: 'Products',
                    onItemSelected: onItemSelected,
                    activeColor: brandOrange,
                    activeBg: activeBackground,
                    inactiveColor: inactiveGrey,
                  ),
                  _buildSidebarItem(
                    item: AdminSidebarItem.collections,
                    icon: Icons.category_outlined,
                    label: 'Collections',
                    onItemSelected: onItemSelected,
                    activeColor: brandOrange,
                    activeBg: activeBackground,
                    inactiveColor: inactiveGrey,
                  ),
                  _buildSidebarItem(
                    item: AdminSidebarItem.brands,
                    icon: Icons.business_outlined,
                    label: 'Brands',
                    onItemSelected: onItemSelected,
                    activeColor: brandOrange,
                    activeBg: activeBackground,
                    inactiveColor: inactiveGrey,
                  ),
                  // carts menu removed per requirement
                  _buildSidebarItem(
                    item: AdminSidebarItem.payments,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Payments',
                    onItemSelected: onItemSelected,
                    activeColor: brandOrange,
                    activeBg: activeBackground,
                    inactiveColor: inactiveGrey,
                  ),
                  _buildSidebarItem(
                    item: AdminSidebarItem.deliverySettings,
                    icon: Icons.local_shipping_outlined,
                    label: 'Delivery',
                    onItemSelected: onItemSelected,
                    activeColor: brandOrange,
                    activeBg: activeBackground,
                    inactiveColor: inactiveGrey,
                  ),
                  _buildSidebarItem(
                    item: AdminSidebarItem.sslSettings,
                    icon: Icons.payment_outlined,
                    label: 'SSL Commerz',
                    onItemSelected: onItemSelected,
                    activeColor: brandOrange,
                    activeBg: activeBackground,
                    inactiveColor: inactiveGrey,
                  ),
                  _buildSidebarItem(
                    item: AdminSidebarItem.discounts,
                    icon: Icons.confirmation_number_outlined,
                    label: 'Discounts',
                    onItemSelected: onItemSelected,
                    activeColor: brandOrange,
                    activeBg: activeBackground,
                    inactiveColor: inactiveGrey,
                  ),

                  _buildSidebarItem(
                    item: AdminSidebarItem.dealsTimer,
                    icon: Icons.timer_outlined,
                    label: 'Deals Timer',
                    onItemSelected: onItemSelected,
                    activeColor: brandOrange,
                    activeBg: activeBackground,
                    inactiveColor: inactiveGrey,
                  ),
                  // _buildSidebarItem(
                  //   item: AdminSidebarItem.flashSales,
                  //   icon: Icons.flash_on_outlined,
                  //   label: 'Flash Sales',
                  //   onItemSelected: onItemSelected,
                  //   activeColor: brandOrange,
                  //   activeBg: activeBackground,
                  //   inactiveColor: inactiveGrey,
                  // ),
                  _buildSidebarItem(
                    item: AdminSidebarItem.promotions,
                    icon: Icons.campaign_outlined,
                    label: 'Promotions',
                    onItemSelected: onItemSelected,
                    activeColor: brandOrange,
                    activeBg: activeBackground,
                    inactiveColor: inactiveGrey,
                  ),
                  _buildSidebarItem(
                    item: AdminSidebarItem.banners,
                    icon: Icons.dashboard_customize_outlined,
                    label: 'Banners',
                    onItemSelected: onItemSelected,
                    activeColor: brandOrange,
                    activeBg: activeBackground,
                    inactiveColor: inactiveGrey,
                  ),
                  _buildSidebarItem(
                    item: AdminSidebarItem.viewStore,
                    icon: Icons.store_outlined,
                    label: 'View Store',
                    onItemSelected: onItemSelected,
                    activeColor: brandOrange,
                    activeBg: activeBackground,
                    inactiveColor: inactiveGrey,
                  ),
                  _buildSidebarItem(
                    item: AdminSidebarItem.reports,
                    icon: Icons.analytics_outlined,
                    label: 'Reports',
                    onItemSelected: onItemSelected,
                    activeColor: brandOrange,
                    activeBg: activeBackground,
                    inactiveColor: inactiveGrey,
                  ),
                ],
              ),
            ),
          ),

          /// BOTTOM SECTION (Settings/Logout)
          const Divider(height: 1),
          _buildSidebarItem(
            item: AdminSidebarItem.settings,
            icon: Icons.settings_outlined,
            label: 'Settings',
            onItemSelected: onItemSelected,
            activeColor: brandOrange,
            activeBg: activeBackground,
            inactiveColor: inactiveGrey,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required AdminSidebarItem item,
    required IconData icon,
    required String label,
    required ValueChanged<AdminSidebarItem> onItemSelected,
    required Color activeColor,
    required Color activeBg,
    required Color inactiveColor,
  }) {
    final bool isSelected = item == selected;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onItemSelected(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? activeColor : inactiveColor,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
