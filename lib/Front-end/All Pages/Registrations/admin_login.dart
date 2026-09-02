import 'package:electrocitybd1/Front-end/All%20Pages/Registrations/login.dart';
import 'package:flutter/material.dart';

import '../../Admin Panel/A_customers.dart';
import '../../Admin Panel/Admin_sidebar.dart';
import '../../Dimensions/responsive_dimensions.dart';
import '../../utils/api_service.dart';
import '../../utils/auth_session.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  static const String _logoPath = 'assets/elogo.png';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Admin login with dedicated admin API
  Future<void> _onAdminLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      // Call the admin login API
      final result = await ApiService.adminLogin(
        username: username,
        password: password,
      );

      if (!mounted) return;

      final userMap = result['user'] as Map<String, dynamic>?;

      if (userMap != null) {
        final userData = UserData(
          firstName: userMap['firstName'] ?? userMap['full_name'] ?? 'Admin',
          lastName: userMap['lastName'] ?? userMap['last_name'] ?? '',
          email: userMap['email'] ?? username,
          phone: userMap['phone'] ?? userMap['phone_number'] ?? '',
          gender: userMap['gender'] ?? 'Male',
        );
        await AuthSession.saveUserData(userData);
      }

      // Save token if provided
      if (result['token'] != null) {
        await AuthSession.saveToken(result['token'].toString());
        await ApiService.saveToken(result['token'].toString());
      }

      await AuthSession.setAdmin(true);
      await AuthSession.setLoggedIn(true);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin login successful!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
        ),
      );

      if (!mounted) return;

      // Navigate to admin panel
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const AdminLayoutPage(initialItem: AdminSidebarItem.dashboard),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'সার্ভারের সাথে সংযোগ করা যাচ্ছে না। অনুগ্রহ করে আবার চেষ্টা করুন।',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final isCompact = r.isSmallMobile || r.isMobile;
    final isStackedLayout = isCompact || r.isTablet;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F7FA), // Light Cyan
              Color(0xFFB2EBF2), // Slightly darker Cyan
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.all(AppDimensions.padding(context)),
                      constraints: BoxConstraints(
                        maxWidth: r.value(
                          smallMobile: 360,
                          mobile: 430,
                          tablet: 550,
                          smallDesktop: 1040,
                          desktop: 1220,
                        ),
                        maxHeight: isStackedLayout ? double.infinity : r.hp(75),
                      ),
                      child: Card(
                        elevation: 12,
                        shadowColor: Colors.black38,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: isStackedLayout
                            ? _buildStackedLayout(r)
                            : _buildDesktopLayout(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildLeftPanel(showText: true)),
        Expanded(flex: 3, child: _buildRightPanel()),
      ],
    );
  }

  Widget _buildStackedLayout(AppResponsive r) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 150,
          width: double.infinity,
          child: _buildLeftPanel(showText: false),
        ),
        _buildRightPanel(),
      ],
    );
  }

  Widget _buildLeftPanel({required bool showText}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E3A8A), // Dark Blue
            Color(0xFF7C3AED), // Premium Purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.padding(context)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
            child: Image.asset(
              _logoPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.flash_on, color: Colors.white, size: 80),
                  SizedBox(height: 8),
                  Text(
                    'ElectroZoneBD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    final sw = MediaQuery.of(context).size.width;
    final isCompact = sw < 768;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          // Top navigation bar with Back and User Login buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF4A3AFF)),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LogIn()),
                  );
                },
                tooltip: 'Back to User Login',
              ),

              // Title
            ],
          ),
          const SizedBox(height: 40),

          // Content
          isCompact
              ? _buildAdminLoginTab()
              : Expanded(
                  child: SingleChildScrollView(child: _buildAdminLoginTab()),
                ),
        ],
      ),
    );
  }

  Widget _buildAdminLoginTab() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              'ADMIN LOGIN',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4A3AFF),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          _buildInputField(
            'Admin Username',
            controller: _usernameController,
            keyboardType: TextInputType.text,
            prefixIcon: Icons.person_outline,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter admin username' : null,
          ),
          const SizedBox(height: 10),
          _buildInputField(
            'Password',
            controller: _passwordController,
            isPassword: true,
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline,
            onTogglePassword: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) =>
                (v == null || v.length < 4) ? 'Min 4 characters' : null,
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onAdminLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Login as Admin',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label, {
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 22, color: const Color(0xFF4A3AFF))
              : null,
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDCDCDC), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A3AFF), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    size: 22,
                    color: const Color(0xFF4A3AFF),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
