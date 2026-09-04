import 'package:flutter/material.dart';

import 'package:electrocitybd1/front_end/Admin_Panel/A_customers.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/Admin_sidebar.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_scaffold.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';

class AdminHelpPage extends StatelessWidget {
  final bool embedded;

  const AdminHelpPage({super.key, this.embedded = false});

  void _navigate(BuildContext context, AdminSidebarItem item) {
    if (item == AdminSidebarItem.help) return;
    AdminNav.go(context, item);
  }

  Widget _buildHelpContent(BuildContext context) {
    final Color darkBg = AdminTheme.bg;
    final Color cardBg = AdminTheme.surfaceAlt;
    final Color brandOrange = Color(0xFF7C3AED);
    return Column(
      children: [
        _buildHeader(cardBg),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Help & Support Center",
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Find answers to common questions or contact support.",
                  style: TextStyle(color: AdminTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Frequently Asked Questions",
                        style: TextStyle(
                          color: AdminTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFAQTile(
                        "How to upload a new product?",
                        "Go to the Products page and fill out the 'Add New Product' form.",
                      ),
                      _buildFAQTile(
                        "How to manage discounts?",
                        "Use the Discounts section to create coupon codes and Flash_Sales.",
                      ),
                      _buildFAQTile(
                        "Where can I see customer reports?",
                        "Check the 'Reports' tab for all user complaints and feedback.",
                      ),
                      const SizedBox(height: 40),
                      const Divider(color: AdminTheme.border),
                      const SizedBox(height: 32),
                      Text(
                        "Contact Technical Support",
                        style: TextStyle(
                          color: AdminTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 500;
                          final cards = [
                            _buildContactCard(
                              darkBg,
                              Icons.email,
                              "Email Us",
                              "support@electrocitybd.com",
                              brandOrange,
                            ),
                            _buildContactCard(
                              darkBg,
                              Icons.phone,
                              "Call Us",
                              "+880 1700-000000",
                              brandOrange,
                            ),
                          ];
                          if (isMobile) {
                            return Column(
                              children: [
                                cards[0],
                                const SizedBox(height: 16),
                                cards[1],
                              ],
                            );
                          }
                          return Row(
                            children: [
                              cards[0],
                              const SizedBox(width: 20),
                              cards[1],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color darkBg = AdminTheme.bg;
    if (embedded) {
      return Material(
        color: darkBg,
        child: SizedBox.expand(child: _buildHelpContent(context)),
      );
    }
    return AdminScaffold(
      selected: AdminSidebarItem.help,
      onItemSelected: (item) => _navigate(context, item),
      body: _buildHelpContent(context),
    );
  }

  /// FAQ TILE
  Widget _buildFAQTile(String question, String answer) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          question,
          style: const TextStyle(color: AdminTheme.textMuted, fontSize: 15),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              answer,
              style: TextStyle(color: AdminTheme.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// CONTACT CARD
  Widget _buildContactCard(
    Color bg,
    IconData icon,
    String title,
    String info,
    Color orange,
  ) {
    return Flexible(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: orange, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: AdminTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info,
              style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// HEADER
  Widget _buildHeader(Color bgColor) => AdminPageHeader(
    color: bgColor,
    children: [
      Text(
        "Support Center",
        style: TextStyle(color: AdminTheme.textPrimary, fontSize: 18),
      ),
      const SizedBox.shrink(),
    ],
  );
}
