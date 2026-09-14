import 'package:flutter/material.dart';
import '../All_Pages/Registrations/login.dart';
import '../utils/api_service.dart';
import '../utils/auth_session.dart';

enum AdminSidebarItem {
  dashboard,
  orders,
  carts,
  products,
  productList,
  stockManagement,
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

// ─── Section model ────────────────────────────────────────────────────────────
class _SidebarSection {
  final String label;
  final List<_SidebarEntry> items;
  bool expanded;
  _SidebarSection({
    required this.label,
    required this.items,
    this.expanded = true,
  });
}

class _SidebarEntry {
  final AdminSidebarItem item;
  final IconData icon;
  final String label;
  final int? badge; // red badge count (null = hidden)
  const _SidebarEntry({
    required this.item,
    required this.icon,
    required this.label,
    this.badge,
  });
}

// ─── Sidebar widget ───────────────────────────────────────────────────────────
class AdminSidebar extends StatefulWidget {
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
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  // ── Color palette (Altezza dark style) ──────────────────────────────────────
  static const Color _bg = Color(0xFF2B2B3B); // main sidebar bg
  static const Color _bgHeader = Color(0xFF252534); // slightly darker header
  // Use the same accessible blue as primary actions throughout the panel.
  static const Color _activePurple = Color(0xFF2563EB);
  static const Color _activeText = Color(0xFFFFFFFF); // white text on purple
  static const Color _inactiveText = Color(0xFFB0B0C8); // light grey labels
  static const Color _sectionLabel = Color(0xFF6B6B88); // muted section headers
  static const Color _divider = Color(0xFF3A3A50); // subtle divider
  static const Color _badgeBg = Color(0xFFE53935); // red badge

  // ── Section definitions ─────────────────────────────────────────────────────
  late final List<_SidebarSection> _sections = [
    _SidebarSection(
      label: 'STORE',
      items: [
        const _SidebarEntry(
          item: AdminSidebarItem.dashboard,
          icon: Icons.grid_view_rounded,
          label: 'Dashboard',
        ),
        const _SidebarEntry(
          item: AdminSidebarItem.viewStore,
          icon: Icons.store_outlined,
          label: 'View Store',
        ),
      ],
    ),
    _SidebarSection(
      label: 'CATALOGUE',
      items: [
        const _SidebarEntry(
          item: AdminSidebarItem.products,
          icon: Icons.add_box_outlined,
          label: 'Upload Product',
        ),
        const _SidebarEntry(
          item: AdminSidebarItem.productList,
          icon: Icons.list_alt_rounded,
          label: 'Product List',
        ),
        const _SidebarEntry(
          item: AdminSidebarItem.stockManagement,
          icon: Icons.inventory_rounded,
          label: 'Stock Management',
        ),
        const _SidebarEntry(
          item: AdminSidebarItem.collections,
          icon: Icons.category_outlined,
          label: 'Collections',
        ),
        const _SidebarEntry(
          item: AdminSidebarItem.brands,
          icon: Icons.business_outlined,
          label: 'Brands',
        ),
      ],
    ),
    _SidebarSection(
      label: 'SALES',
      items: [
        const _SidebarEntry(
          item: AdminSidebarItem.orders,
          icon: Icons.shopping_bag_outlined,
          label: 'Orders',
        ),
        const _SidebarEntry(
          item: AdminSidebarItem.carts,
          icon: Icons.shopping_cart_outlined,
          label: 'Abandoned Carts',
        ),
        const _SidebarEntry(
          item: AdminSidebarItem.payments,
          icon: Icons.account_balance_wallet_outlined,
          label: 'Payments',
        ),
        const _SidebarEntry(
          item: AdminSidebarItem.discounts,
          icon: Icons.confirmation_number_outlined,
          label: 'Discounts',
        ),
        const _SidebarEntry(
          item: AdminSidebarItem.deals,
          icon: Icons.local_offer_outlined,
          label: 'Deals',
        ),
        const _SidebarEntry(
          item: AdminSidebarItem.promotions,
          icon: Icons.campaign_outlined,
          label: 'Promotions',
        ),
      ],
    ),
    _SidebarSection(
      label: 'MARKETING',
      items: [
        const _SidebarEntry(
          item: AdminSidebarItem.banners,
          icon: Icons.dashboard_customize_outlined,
          label: 'Banners',
        ),
      ],
    ),
    _SidebarSection(
      label: 'LOGISTICS',
      items: [
        const _SidebarEntry(
          item: AdminSidebarItem.deliverySettings,
          icon: Icons.local_shipping_outlined,
          label: 'Delivery',
        ),
        const _SidebarEntry(
          item: AdminSidebarItem.sslSettings,
          icon: Icons.payment_outlined,
          label: 'SSL Commerz',
        ),
      ],
    ),
    _SidebarSection(
      label: 'ANALYTICS',
      expanded: false,
      items: [
        const _SidebarEntry(
          item: AdminSidebarItem.reports,
          icon: Icons.analytics_outlined,
          label: 'Reports',
        ),
      ],
    ),
    _SidebarSection(
      label: 'SYSTEM & HELP',
      expanded: true,
      items: [
        const _SidebarEntry(
          item: AdminSidebarItem.help,
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.sidebarWidth,
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          _buildHeader(context),

          // ── Scrollable menu ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _sections.map((s) => _buildSection(s)).toList(),
              ),
            ),
          ),

          // ── Bottom divider + Settings & Logout ──────────────────────────────
          Container(height: 1, color: _divider),
          const SizedBox(height: 4),
          _buildItem(
            item: AdminSidebarItem.settings,
            icon: Icons.settings_outlined,
            label: 'Settings',
          ),
          _buildLogoutItem(context),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Logout Admin'),
                content: const Text(
                  'Are you sure you want to log out of the admin panel?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await AuthSession.clear();
              await ApiService.clearToken();
              ApiService.invalidateCache();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LogIn()),
                  (route) => false,
                );
              }
            }
          },
          hoverColor: Colors.red.withOpacity(0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 20, color: Colors.red[300]),
                const SizedBox(width: 12),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red[300],
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _bgHeader,
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 20),
      child: Row(
        children: [
          // Brand icon circle
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _activePurple,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt, color: _activeText, size: 22),
          ),
          const SizedBox(width: 12),
          // Title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ElectroCity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'ADMIN',
                  style: TextStyle(
                    color: _sectionLabel,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Back / collapse button
          InkWell(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A52),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.keyboard_backspace_rounded,
                size: 18,
                color: _inactiveText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section block ────────────────────────────────────────────────────────────
  Widget _buildSection(_SidebarSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // Section label row (clickable to expand/collapse)
        GestureDetector(
          onTap: () => setState(() => section.expanded = !section.expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  section.expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: _sectionLabel,
                ),
                const SizedBox(width: 6),
                Text(
                  section.label,
                  style: const TextStyle(
                    color: _sectionLabel,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Items (animated expand/collapse)
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: section.expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            children: section.items
                .map(
                  (e) => _buildItem(
                    item: e.item,
                    icon: e.icon,
                    label: e.label,
                    badge: e.badge,
                  ),
                )
                .toList(),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Single nav item ──────────────────────────────────────────────────────────
  Widget _buildItem({
    required AdminSidebarItem item,
    required IconData icon,
    required String label,
    int? badge,
  }) {
    final bool isActive = item == widget.selected;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => widget.onItemSelected(item),
          splashColor: _activePurple.withOpacity(0.12),
          highlightColor: _activePurple.withOpacity(0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isActive ? _activePurple : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? _activeText : _inactiveText,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? _activeText : _inactiveText,
                    ),
                  ),
                ),
                // Badge
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
