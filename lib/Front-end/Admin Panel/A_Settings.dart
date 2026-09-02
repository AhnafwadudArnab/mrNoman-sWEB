import 'package:electrocitybd1/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../All Pages/CART/Cart_provider.dart';
import '../All Pages/Registrations/login.dart';
import '../utils/api_service.dart';
import '../utils/auth_session.dart';
import '../Provider/language_provider.dart';
import '../Provider/Orders_provider.dart';
import '../pages/Profiles/Wishlist_provider.dart';
import 'Admin_sidebar.dart';
import 'A_customers.dart';
import 'admin_scaffold.dart';
import 'admin_theme.dart';

class AdminSettingsPage extends StatefulWidget {
  final bool embedded;

  const AdminSettingsPage({super.key, this.embedded = false});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _emailNotifications = true;
  bool _pushNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailNotifications =
          prefs.getBool('email_notifications_enabled') ?? true;
      _pushNotifications = prefs.getBool('push_notifications_enabled') ?? false;
    });
  }

  Future<void> _togglePushNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', value);
    setState(() => _pushNotifications = value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Push notifications enabled'
                : 'Push notifications disabled',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  void _showAdminProfile(BuildContext context) async {
    try {
      final userData = await AuthSession.getUserData();
      final isAdmin = await AuthSession.isAdmin();
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.person, color: Color(0xFF7C3AED), size: 24),
              SizedBox(width: 12),
              Text('Admin Profile', style: TextStyle(color: AdminTheme.textPrimary)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _profileField('Name', userData?.fullName ?? 'N/A'),
                const SizedBox(height: 12),
                _profileField('Email', userData?.email ?? 'N/A'),
                const SizedBox(height: 12),
                _profileField('Phone', userData?.phone ?? 'N/A'),
                const SizedBox(height: 12),
                _profileField('Role', isAdmin ? 'admin' : 'user'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  Widget _profileField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14)),
      ],
    );
  }

  void _showChangePassword(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock, color: Color(0xFF7C3AED), size: 24),
            SizedBox(width: 12),
            Text('Change Password', style: TextStyle(color: AdminTheme.textPrimary)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                style: const TextStyle(color: AdminTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0x0D000000),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                style: const TextStyle(color: AdminTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0x0D000000),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: AdminTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0x0D000000),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                  ),
                );
                return;
              }

              try {
                await ApiService.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );
                Navigator.pop(ctx);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.black,
            ),
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.language, color: Color(0xFF7C3AED), size: 24),
            SizedBox(width: 12),
            Text('Select Language', style: TextStyle(color: AdminTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text(
                'English',
                style: TextStyle(color: AdminTheme.textPrimary),
              ),
              trailing: languageProvider.isEnglish
                  ? const Icon(Icons.check, color: Color(0xFF7C3AED))
                  : null,
              onTap: () async {
                await languageProvider.setLanguage('en');
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Language set to English')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Text('🇧🇩', style: TextStyle(fontSize: 24)),
              title: const Text('বাংলা', style: TextStyle(color: AdminTheme.textPrimary)),
              trailing: languageProvider.isBengali
                  ? const Icon(Icons.check, color: Color(0xFF7C3AED))
                  : null,
              onTap: () async {
                await languageProvider.setLanguage('bn');
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ভাষা বাংলায় সেট করা হয়েছে'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storefront,
                color: Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('About', style: TextStyle(color: AdminTheme.textPrimary)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ElectroZoneBD Admin Panel',
              style: TextStyle(
                color: AdminTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Manage your e-commerce store with ease. Track orders, manage products, and monitor sales all in one place.',
              style: TextStyle(
                color: Color(0x8A000000),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '© 2026 ElectroZoneBD. All rights reserved.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, AdminSidebarItem item) {
    if (item == AdminSidebarItem.settings) return;
    AdminNav.go(context, item);
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.redAccent, size: 24),
            SizedBox(width: 12),
            Text('Confirm Logout', style: TextStyle(color: AdminTheme.textPrimary)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of the admin panel?',
          style: TextStyle(color: Color(0x8A000000), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: AdminTheme.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ApiService.clearToken();
      await AuthSession.clear();
      await context.read<CartProvider>().switchToGuest();
      context.read<WishlistProvider>().clearWishlist();
      context.read<OrdersProvider>().clearForLogout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LogIn()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildSettingsContent(BuildContext context) {
    const Color cardBg = AdminTheme.surfaceAlt;
    const Color brandOrange = Color(0xFF7C3AED);
    return Column(
      children: [
        AdminPageHeader(
          color: cardBg,
          children: [
            const Text(
              'Management / Settings',
              style: TextStyle(color: Color(0x73000000), fontSize: 14),
            ),
            const Icon(Icons.person, color: Color(0x73000000)),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your admin preferences and account.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),
                _buildSection(
                  cardBg,
                  brandOrange,
                  icon: Icons.person_outline,
                  title: 'Account',
                  children: [
                    _buildSettingsTile(
                      icon: Icons.badge_outlined,
                      title: 'Admin Profile',
                      subtitle: 'View and edit your admin profile',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Color(0x42000000),
                      ),
                      onTap: () => _showAdminProfile(context),
                    ),
                    const Divider(color: Color(0x0D000000), height: 1),
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'Update your login credentials',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Color(0x42000000),
                      ),
                      onTap: () => _showChangePassword(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  cardBg,
                  brandOrange,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  children: [
                    _buildSettingsTile(
                      icon: Icons.email_outlined,
                      title: 'Email Notifications',
                      subtitle: 'Receive order and report alerts',
                      trailing: Switch(
                        value: _emailNotifications,
                        activeColor: brandOrange,
                        onChanged: (value) async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool(
                            'email_notifications_enabled',
                            value,
                          );
                          setState(() => _emailNotifications = value);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Email notifications enabled'
                                      : 'Email notifications disabled',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      onTap: () {},
                    ),
                    const Divider(color: Color(0x0D000000), height: 1),
                    _buildSettingsTile(
                      icon: Icons.campaign_outlined,
                      title: 'Push Notifications',
                      subtitle: 'Get instant updates on your device',
                      trailing: Switch(
                        value: _pushNotifications,
                        activeColor: brandOrange,
                        onChanged: _togglePushNotifications,
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  cardBg,
                  brandOrange,
                  icon: Icons.qr_code_2,
                  title: 'Footer QR Code',
                  children: [_QRCodeUploadSection()],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  cardBg,
                  brandOrange,
                  icon: Icons.chat,
                  title: 'WhatsApp Support',
                  children: [const _WhatsAppNumberSection()],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  cardBg,
                  brandOrange,
                  icon: Icons.tune_outlined,
                  title: 'General',
                  children: [
                    _buildSettingsTile(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'English',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Color(0x42000000),
                      ),
                      onTap: () => _showLanguageDialog(context),
                    ),
                    const Divider(color: Color(0x0D000000), height: 1),
                    _buildSettingsTile(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'ElectroZoneBD Admin v1.0',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Color(0x42000000),
                      ),
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: SizedBox(
                    width: (MediaQuery.of(context).size.width - 64).clamp(
                      180.0,
                      300.0,
                    ),
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withAlpha(30),
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
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
    if (widget.embedded) {
      return Material(
        color: darkBg,
        child: SizedBox.expand(child: _buildSettingsContent(context)),
      );
    }
    return AdminScaffold(
      selected: AdminSidebarItem.settings,
      onItemSelected: (item) => _navigate(context, item),
      body: _buildSettingsContent(context),
    );
  }

  Widget _buildSection(
    Color cardBg,
    Color accent, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0x0D000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              children: [
                Icon(icon, color: accent, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: Color(0x73000000), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: AdminTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _QRCodeUploadSection extends StatefulWidget {
  @override
  State<_QRCodeUploadSection> createState() => _QRCodeUploadSectionState();
}

class _QRCodeUploadSectionState extends State<_QRCodeUploadSection> {
  String? _currentQRCode;
  bool _loading = true;
  bool _uploading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    _loadCurrentQRCode();
  }

  Future<void> _loadCurrentQRCode() async {
    try {
      final settings = await ApiService.getSiteSetting('qr_code_image');
      if (mounted && settings['setting_value'] != null) {
        setState(() {
          _currentQRCode = settings['setting_value'];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (kDebugMode) print('Error loading QR code: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      if (kDebugMode) print('Starting image upload...');

      // Upload image to server
      final imageUrl = await ApiService.uploadImage(
        _selectedImageBytes!,
        _selectedImageName ?? 'qr_code.png',
      );

      if (kDebugMode) print('Image uploaded successfully: $imageUrl');

      // Convert relative URL to absolute URL if needed
      String fullImageUrl = imageUrl;
      if (imageUrl.startsWith('/')) {
        // Get base URL without /api
        final baseUrl = (ApiService.overrideBaseUrl ?? AppConfig.apiBaseUrl)
            .replaceAll('/api', '');
        fullImageUrl = '$baseUrl$imageUrl';
      }

      if (kDebugMode) {
        print('Full image URL: $fullImageUrl');
        print('Saving to site settings...');
      }

      // Save the URL to site settings
      await ApiService.saveSiteSetting({
        'setting_key': 'qr_code_image',
        'setting_value': fullImageUrl,
      });

      if (kDebugMode) print('Settings saved successfully');

      if (mounted) {
        setState(() {
          _currentQRCode = fullImageUrl;
          _selectedImageBytes = null;
          _selectedImageName = null;
          _uploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR Code uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Upload error: $e');
        print('Stack trace: $stackTrace');
      }

      if (mounted) {
        setState(() => _uploading = false);

        // Show detailed error message
        String errorMessage = 'Upload failed';
        if (e.toString().contains('ApiException')) {
          errorMessage = e
              .toString()
              .replaceAll('ApiException', '')
              .replaceAll('(', '')
              .replaceAll(')', '');
        } else {
          errorMessage = 'Upload failed: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload QR Code for Mobile App',
            style: TextStyle(
              color: AdminTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This QR code will appear in the footer section',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // Current QR Code Preview
          if (_currentQRCode != null &&
              _currentQRCode!.isNotEmpty &&
              _selectedImageBytes == null)
            Center(
              child: Column(
                children: [
                  const Text(
                    'Current QR Code',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentQRCode!,
                    style: const TextStyle(color: AdminTheme.textMuted, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 150,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AdminTheme.textPrimary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0x1F000000)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        _currentQRCode!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          if (kDebugMode) print('Image load error: $error');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Selected Image Preview
          if (_selectedImageBytes != null)
            Center(
              child: Column(
                children: [
                  const Text(
                    'Selected Image',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 150,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AdminTheme.textPrimary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF7C3AED),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        _selectedImageBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Text(
                    _selectedImageName ?? 'image.png',
                    style: const TextStyle(color: AdminTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          // Pick Image Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _uploading ? null : _pickImage,
              icon: const Icon(Icons.image),
              label: Text(
                _selectedImageBytes == null
                    ? 'Choose Image'
                    : 'Choose Different Image',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminTheme.textPrimary,
                side: const BorderSide(color: Color(0x1F000000)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Upload Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_uploading || _selectedImageBytes == null)
                  ? null
                  : _uploadImage,
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AdminTheme.textPrimary,
                      ),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_uploading ? 'Uploading...' : 'Upload QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppNumberSection extends StatefulWidget {
  const _WhatsAppNumberSection();

  @override
  State<_WhatsAppNumberSection> createState() => _WhatsAppNumberSectionState();
}

class _WhatsAppNumberSectionState extends State<_WhatsAppNumberSection> {
  String? _currentWhatsAppNumber;
  bool _loading = true;
  bool _saving = false;
  late TextEditingController _numberController;

  String _normalizeWhatsAppNumber(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    return digits;
  }

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController();
    _loadWhatsAppNumber();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _loadWhatsAppNumber() async {
    try {
      final settings = await ApiService.getSiteSetting(
        'support_whatsapp_number',
      );
      if (mounted) {
        setState(() {
          _currentWhatsAppNumber = settings['setting_value'];
          _numberController.text = _currentWhatsAppNumber ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading WhatsApp number: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveWhatsAppNumber() async {
    final number = _normalizeWhatsAppNumber(_numberController.text.trim());
    if (number.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid WhatsApp number')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ApiService.saveSiteSetting({
        'setting_key': 'support_whatsapp_number',
        'setting_value': number,
      });

      if (mounted) {
        setState(() {
          _currentWhatsAppNumber = number;
          _numberController.text = number;
          _saving = false;
        });
        // Reload from server to confirm the save was persisted
        _loadWhatsAppNumber();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp number saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving WhatsApp number: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support WhatsApp Number',
            style: TextStyle(
              color: AdminTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Users can contact support via WhatsApp from the main page',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (_currentWhatsAppNumber != null &&
              _currentWhatsAppNumber!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF25D366), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Number',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentWhatsAppNumber!,
                    style: const TextStyle(
                      color: Color(0xFF25D366),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _numberController,
            style: const TextStyle(color: AdminTheme.textPrimary),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText:
                  'WhatsApp Number (with country code, e.g., 8801234567890)',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1A2332),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0x1F000000)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0x1F000000)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF25D366),
                  width: 2,
                ),
              ),
              prefixIcon: const Icon(Icons.phone, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveWhatsAppNumber,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AdminTheme.textPrimary,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save WhatsApp Number'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: AdminTheme.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}











