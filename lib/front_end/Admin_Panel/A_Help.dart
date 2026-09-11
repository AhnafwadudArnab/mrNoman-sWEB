import 'package:flutter/material.dart';

import 'package:electrocitybd1/front_end/Admin_Panel/A_customers.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/Admin_sidebar.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_scaffold.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';

class AdminHelpPage extends StatefulWidget {
  final bool embedded;

  const AdminHelpPage({super.key, this.embedded = false});

  @override
  State<AdminHelpPage> createState() => _AdminHelpPageState();
}

class _AdminHelpPageState extends State<AdminHelpPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _faqCategories = [
    {
      'category': 'Products & Inventory',
      'icon': Icons.inventory_2_outlined,
      'color': Color(0xFF2563EB),
      'items': [
        {
          'q': 'How do I add a new product with images and prices?',
          'a':
              '1. Go to Products or Collections in the sidebar.\n'
              '2. Click the "+ Add New Product" tab or button.\n'
              '3. Fill in the product details: title, description, category, brand, and regular price.\n'
              '4. In the Image Picker section, click "Pick Image" from your computer.\n'
              '5. Verify the preview on the left and click "Upload Product" to save it live to the database.',
        },
        {
          'q': 'How do I upload picture or load image on product uploads?',
          'a':
              '1. In the Add Product form (Products or Collections), scroll to the Image section.\n'
              '2. Click "Pick Image" to browse files from your local storage.\n'
              '3. Once selected, the image preview container immediately displays the picture thumbnail.\n'
              '4. Click "Upload Product" to upload the image file to the backend server and link it to the product in the database.',
        },
        {
          'q': 'What should I do if product picture or image does not load properly?',
          'a':
              '1. Ensure the image is in JPG, PNG, or WebP format under 5MB.\n'
              '2. Verify that your backend PHP server is running and the public uploads folder has write permissions.\n'
              '3. In Admin Panel, use the image preview box to confirm image rendering before clicking Upload.',
        },
        {
          'q': 'How do I update product stock and track inventory?',
          'a':
              '1. Navigate to Products > Stock Management.\n'
              '2. Search or find the desired product in the inventory table.\n'
              '3. Click the "Update Stock" (edit) button.\n'
              '4. Select the operation: Add Stock (+), Reduce Stock (-), or Set Direct Stock.\n'
              '5. Enter the quantity and click Save. The live stock is updated in the database instantly.',
        },
        {
          'q': 'How do I assign products to Featured, Trending, or Flash Sale sections?',
          'a':
              '1. In the Products page, edit the product.\n'
              '2. Under "Section / Badge", select from Featured, Trending, Best Seller, or Flash Sale.\n'
              '3. Save the product. The homepage section updates automatically.',
        },
        {
          'q': 'What is the difference between Regular Price and Deal Price?',
          'a':
              '• Regular Price is the standard retail price shown to customers.\n'
              '• Deal Price / Discount Price is the promotional sale price. If entered, the regular price will be shown with a strikethrough and a discount percentage badge is automatically calculated.',
        },
      ],
    },
    {
      'category': 'Orders & Fulfillment',
      'icon': Icons.shopping_bag_outlined,
      'color': Color(0xFF10B981),
      'items': [
        {
          'q': 'How do I view and filter customer orders?',
          'a':
              '1. Navigate to Orders in the sidebar.\n'
              '2. Use the search bar at the top to search by Order ID, customer phone number, or customer name.\n'
              '3. Filter orders using the status chips: All, Pending, Processing, Shipped, or Delivered.',
        },
        {
          'q': 'How do I update an order\'s delivery status?',
          'a':
              '1. Open the Orders page and locate the specific order.\n'
              '2. Click on the Order Status dropdown menu.\n'
              '3. Select the updated status (e.g. Processing, Shipped, Delivered, or Cancelled).\n'
              '4. The order status is updated in the database and synced with customer notifications.',
        },
        {
          'q': 'Where can I find Abandoned Carts and recovery info?',
          'a':
              '1. Navigate to Abandoned Carts under the Orders section in the sidebar.\n'
              '2. Review items left behind by visitors, total value, and contact information.\n'
              '3. You can contact customers directly via WhatsApp or phone to assist in completing the purchase.',
        },
      ],
    },
    {
      'category': 'Delivery & Couriers',
      'icon': Icons.local_shipping_outlined,
      'color': Color(0xFFF59E0B),
      'items': [
        {
          'q': 'How do I enable or disable courier services (Pathao, REDX, Steadfast)?',
          'a':
              '1. Go to Delivery Settings in the sidebar.\n'
              '2. Each delivery service has its official logo card (Pathao, REDX, Steadfast, Paperfly, eCourier, Sundarban, SA Paribahan, In-house).\n'
              '3. Use the toggle switch on the right side of each card to enable or disable that courier.\n'
              '4. Click "Save" in the top bar to apply your settings.',
        },
        {
          'q': 'How do I set delivery charges for Inside Dhaka vs Outside Dhaka?',
          'a':
              '1. In Delivery Settings, click the edit / configure option on your active delivery provider.\n'
              '2. Set the Base Delivery Charge (e.g. ৳60 for Inside Dhaka, ৳120 for Outside Dhaka).\n'
              '3. Optionally configure Cash on Delivery (COD) percentage or fixed fee.\n'
              '4. Save changes to update the checkout shipping calculator.',
        },
        {
          'q': 'How do I connect courier API credentials for automated booking?',
          'a':
              '1. In Delivery Settings, select the provider.\n'
              '2. Change the mode from "Manual" to "Live" or "Sandbox".\n'
              '3. Enter your Merchant ID, API Key, and Secret provided by your courier merchant dashboard.\n'
              '4. Once saved, an green API Ready checkmark badge will appear on the courier logo.',
        },
      ],
    },
    {
      'category': 'Payments & SSLCommerz',
      'icon': Icons.payment_outlined,
      'color': Color(0xFF8B5CF6),
      'items': [
        {
          'q': 'How do I configure SSLCommerz Payment Gateway?',
          'a':
              '1. Navigate to SSL Commerz Settings in the sidebar.\n'
              '2. Toggle between Sandbox Mode (for testing) or Live Mode (for real transactions).\n'
              '3. Enter your Store ID and Store Password provided by SSLCommerz.\n'
              '4. Copy the IPN Webhook URL and register it in your SSLCommerz Merchant Portal.\n'
              '5. Click "Save Settings" at the top right.',
        },
        {
          'q': 'How do I enable or disable Mobile Banking (bKash, Nagad, Rocket)?',
          'a':
              '1. In SSL Commerz Settings, scroll to the "Payment Tabs Configuration" section.\n'
              '2. Toggle the switch for "Mobile Banking (bKash, Nagad, Rocket, Upay)".\n'
              '3. You can also customize the tab label or set custom fallback messages.\n'
              '4. Check the Live Hosted Checkout Preview on the right to see the customer view.',
        },
        {
          'q': 'How do I configure checkout session timer and convenience charges?',
          'a':
              '1. In SSL Commerz Settings > Checkout Session & Parameters.\n'
              '2. Set the Session Timer (in minutes, e.g. 5 or 10 mins).\n'
              '3. Set the Convenience Fee in ৳ (set 0 for free transactions).\n'
              '4. Changes appear in the live mockup preview immediately.',
        },
      ],
    },
    {
      'category': 'Marketing, Deals & Banners',
      'icon': Icons.campaign_outlined,
      'color': Color(0xFFEC4899),
      'items': [
        {
          'q': 'How do I upload and manage Mid Banners (below Flash Sale)?',
          'a':
              '1. Go to Banners in the sidebar and scroll to "Mid Banners (Dynamic list below Flash_Sale)".\n'
              '2. Click "+ Add banner".\n'
              '3. Click the folder icon on the input field to pick an image from your computer.\n'
              '4. Verify the preview box and click the green Check button to save.\n'
              '5. The image is uploaded to the server and updates on the storefront home page.',
        },
        {
          'q': 'How do I setup Deals and Deals Countdown Timer?',
          'a':
              '1. Go to Deals in the sidebar.\n'
              '2. Use Tab 1 ("Deals & Discounts") to manage individual product deals, start dates, and end dates.\n'
              '3. Use Tab 2 ("Deals Timer") to enable or adjust the live countdown clock displayed on the store.\n'
              '4. Set duration or target end date and click Save.',
        },
        {
          'q': 'How do I create promotional discount coupons?',
          'a':
              '1. Navigate to Discounts in the sidebar.\n'
              '2. Click "Create New Coupon".\n'
              '3. Set the coupon code (e.g. SAVE20), discount type (percentage or fixed ৳), and minimum purchase amount.\n'
              '4. Save the coupon. Customers can now apply it at checkout.',
        },
      ],
    },
    {
      'category': 'Settings & Security',
      'icon': Icons.settings_outlined,
      'color': Color(0xFF0F766E),
      'items': [
        {
          'q': 'How do I update WhatsApp support number and Footer QR code?',
          'a':
              '1. Navigate to Settings in the sidebar.\n'
              '2. Under "WhatsApp Support", enter your WhatsApp phone number with country code (e.g. +8801...).\n'
              '3. Under "Footer QR Code", upload your app download or store contact QR code image.\n'
              '4. Click Save to publish changes.',
        },
        {
          'q': 'How do I change my admin password securely?',
          'a':
              '1. In Settings > Security, click "Change Password".\n'
              '2. Enter your current password, then type your new password (at least 6 characters) and confirm it.\n'
              '3. Click Save. Your new credentials take effect immediately.',
        },
        {
          'q': 'How do I safely log out of the admin panel?',
          'a':
              '1. Scroll to the bottom of the Settings page.\n'
              '2. Click the "Logout" button.\n'
              '3. A clean confirmation box will prompt you to confirm.\n'
              '4. Click "Logout" to clear your admin session securely.',
        },
      ],
    },
  ];

  void _navigate(BuildContext context, AdminSidebarItem item) {
    if (item == AdminSidebarItem.help) return;
    AdminNav.go(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildHelpContent(context);
    if (widget.embedded) {
      return Material(color: AdminTheme.bg, child: SizedBox.expand(child: body));
    }
    return AdminScaffold(
      selected: AdminSidebarItem.help,
      onItemSelected: (item) => _navigate(context, item),
      body: body,
    );
  }

  Widget _buildHelpContent(BuildContext context) {
    final filteredCategories = _getFilteredCategories();

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Intro Banner
                    _buildHeroBanner(),
                    const SizedBox(height: 24),

                    // Search and Category Bar
                    _buildSearchAndFilter(),
                    const SizedBox(height: 24),

                    // FAQ Accordion Sections
                    if (filteredCategories.isEmpty)
                      _buildNoResults()
                    else
                      ...filteredCategories.map(_buildCategorySection),

                    const SizedBox(height: 32),

                    // Technical Support Contact Cards
                    _buildContactSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AdminTheme.surfaceAlt,
        border: Border(bottom: BorderSide(color: AdminTheme.border)),
      ),
      child: Row(
        children: const [
          Icon(Icons.help_center_rounded, color: Color(0xFF2563EB), size: 22),
          SizedBox(width: 10),
          Text(
            'Admin Knowledge Base & User Guide',
            style: TextStyle(
              color: AdminTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x201E3A8A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'How to Use ElectroZoneBD Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Complete guide covering products, inventory, orders, courier settings, payment gateway, and store management. Click any dropdown question below to view detailed steps.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final categories = [
      'All',
      'Products & Inventory',
      'Orders & Fulfillment',
      'Delivery & Couriers',
      'Payments & SSLCommerz',
      'Marketing, Deals & Banners',
      'Settings & Security',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        TextField(
          controller: _searchCtrl,
          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search any question (e.g. stock, upload banner, courier, SSLCommerz)...',
            hintStyle: const TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: AdminTheme.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AdminTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final active = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: active,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: const Color(0xFF2563EB),
                  backgroundColor: AdminTheme.surfaceAlt,
                  labelStyle: TextStyle(
                    color: active ? Colors.white : AdminTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: active ? const Color(0xFF2563EB) : AdminTheme.border,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  static final Set<String> _stopWords = {
    'a', 'an', 'the', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
    'by', 'from', 'up', 'about', 'into', 'over', 'after', 'how',
    'do', 'i', 'can', 'is', 'are', 'what', 'where', 'when', 'why',
    'or', 'and', 'my', 'me', 'it', 'be', 'this', 'that', 'please',
  };

  static final Map<String, List<String>> _synonyms = {
    'picture': ['image', 'photo', 'pic', 'thumbnail', 'upload', 'load'],
    'pictures': ['image', 'images', 'photo', 'photos', 'pic', 'pics'],
    'photo': ['image', 'picture', 'pic'],
    'image': ['picture', 'photo', 'pic', 'thumbnail'],
    'images': ['pictures', 'photos', 'pics', 'thumbnails'],
    'load': ['upload', 'picker', 'add', 'choose', 'attach', 'fetch', 'picture', 'image'],
    'loading': ['upload', 'uploading', 'picker', 'fetching'],
    'upload': ['add', 'create', 'save', 'publish', 'pick', 'load', 'picture', 'image'],
    'uploads': ['add', 'create', 'products', 'upload', 'items', 'picture', 'image'],
    'uploading': ['upload', 'adding', 'creating', 'saving', 'loading'],
    'product': ['item', 'products', 'goods', 'stock', 'inventory'],
    'products': ['product', 'items', 'goods', 'inventory'],
    'item': ['product', 'products', 'items'],
    'items': ['product', 'products'],
    'brand': ['brands', 'manufacturer'],
    'brands': ['brand', 'manufacturers'],
    'deal': ['deals', 'discount', 'timer', 'offer'],
    'deals': ['deal', 'discount', 'timer', 'offer'],
    'courier': ['delivery', 'pathao', 'redx', 'steadfast', 'shipping'],
    'delivery': ['courier', 'shipping', 'dispatch', 'rider'],
    'stock': ['inventory', 'quantity', 'instock', 'units'],
  };

  bool _matchesFaqSearch(String query, String q, String a) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return true;

    final qLower = q.toLowerCase();
    final aLower = a.toLowerCase();
    final combined = '$qLower $aLower';

    // Direct substring match first
    if (combined.contains(cleanQuery)) return true;

    final rawTokens = cleanQuery
        .split(RegExp(r'[\s,.:;?!/\\-]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (rawTokens.isEmpty) return true;

    final tokens = rawTokens.length > 1
        ? rawTokens.where((t) => !_stopWords.contains(t)).toList()
        : rawTokens;
    final searchTokens = tokens.isEmpty ? rawTokens : tokens;

    int matchedCount = 0;
    for (final token in searchTokens) {
      if (combined.contains(token)) {
        matchedCount++;
        continue;
      }
      final syns = _synonyms[token] ?? [];
      bool synMatch = false;
      for (final syn in syns) {
        if (combined.contains(syn)) {
          synMatch = true;
          break;
        }
      }
      if (synMatch) {
        matchedCount++;
      }
    }

    // Match if at least 50% of tokens match (or all if 1-2 tokens)
    final requiredMatches = searchTokens.length <= 2
        ? (searchTokens.length == 1 ? 1 : 1)
        : (searchTokens.length * 0.5).ceil();
    return matchedCount >= requiredMatches;
  }

  List<Map<String, dynamic>> _getFilteredCategories() {
    return _faqCategories
        .map((cat) {
          final isCatSelected =
              _selectedCategory == 'All' || _selectedCategory == cat['category'];
          if (!isCatSelected) return null;

          final items = (cat['items'] as List<Map<String, String>>)
              .where((item) {
                return _matchesFaqSearch(_searchQuery, item['q']!, item['a']!);
              })
              .toList();

          if (items.isEmpty) return null;

          return {
            'category': cat['category'],
            'icon': cat['icon'],
            'color': cat['color'],
            'items': items,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Widget _buildCategorySection(Map<String, dynamic> cat) {
    final title = cat['category'] as String;
    final icon = cat['icon'] as IconData;
    final color = cat['color'] as Color;
    final items = cat['items'] as List<Map<String, String>>;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              border: const Border(bottom: BorderSide(color: AdminTheme.border)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length} questions',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // FAQ Accordions List
          ...items.asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value;
            final isLast = idx == items.length - 1;

            return Column(
              children: [
                _buildAccordionItem(item['q']!, item['a']!),
                if (!isLast) const Divider(color: AdminTheme.border, height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAccordionItem(String question, String answer) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        iconColor: const Color(0xFF2563EB),
        collapsedIconColor: AdminTheme.textSecondary,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.question_mark_rounded,
            size: 13,
            color: Color(0xFF2563EB),
          ),
        ),
        title: Text(
          question,
          style: const TextStyle(
            color: AdminTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdminTheme.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminTheme.border),
            ),
            child: Text(
              answer,
              style: const TextStyle(
                color: AdminTheme.textPrimary,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      padding: const EdgeInsets.all(36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AdminTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text(
            'No matching questions found',
            style: TextStyle(
              color: AdminTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try searching for another keyword or select "All" categories.',
            style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Still Need Assistance?',
            style: TextStyle(
              color: AdminTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Our technical support team is available to help resolve any issues.',
            style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final cards = [
                _buildContactCard(
                  icon: Icons.email_outlined,
                  title: 'Email Technical Support',
                  info: 'ahnafwadudarnab@gmail.com',
                  badge: '24-48h reply',
                  color: const Color(0xFF2563EB),
                ),
                _buildContactCard(
                  icon: Icons.phone_in_talk_outlined,
                  title: 'Direct Phone Line',
                  info: '01840-658317',
                  badge: '7PM - 11PM',
                  color: const Color(0xFF10B981),
                ),
              ];

              if (isMobile) {
                return Column(
                  children: [
                    cards[0],
                    const SizedBox(height: 12),
                    cards[1],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 14),
                  Expanded(child: cards[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String info,
    required String badge,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
