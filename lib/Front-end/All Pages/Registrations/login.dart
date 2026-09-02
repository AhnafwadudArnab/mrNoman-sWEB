import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:electrocitybd1/config/app_config.dart';

import '../../utils/api_service.dart';
import '../../Dimensions/responsive_dimensions.dart';
import '../../pages/home_page.dart';
import '../../utils/auth_session.dart';
import '../CART/Cart_provider.dart';
import '../../pages/Profiles/Wishlist_provider.dart';
import 'forgot_password.dart';
import 'signup.dart';
import 'admin_login.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  static const String _logoPath = 'assets/elogo.png';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Regular user login with API
  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final result = await ApiService.login(email: email, password: password);

      if (!mounted) return;

      if (result['token'] == null || result['user'] == null) {
        throw ApiException('Invalid email or password.', 401);
      }

      final token = (result['token'] ?? '').toString();
      final userMap = result['user'] as Map<String, dynamic>?;

      if (token.isEmpty || userMap == null) {
        throw ApiException('Invalid email or password.', 401);
      }

      final userData = UserData(
        firstName: userMap['firstName'] ?? userMap['full_name'] ?? 'User',
        lastName: userMap['lastName'] ?? userMap['last_name'] ?? '',
        email: userMap['email'] ?? '',
        phone: userMap['phone'] ?? userMap['phone_number'] ?? '',
        gender: userMap['gender'] ?? 'Male',
      );

      await AuthSession.saveUserData(userData);
      await AuthSession.saveToken(token);
      await ApiService.saveToken(token);
      await AuthSession.setAdmin(false);
      await AuthSession.setLoggedIn(true);

      try {
        final profile = await ApiService.getProfile();
        final fullUser = UserData(
          firstName:
              profile['firstName'] ??
              profile['full_name'] ??
              userData.firstName,
          lastName:
              profile['lastName'] ?? profile['last_name'] ?? userData.lastName,
          email: profile['email'] ?? userData.email,
          phone: profile['phone'] ?? profile['phone_number'] ?? userData.phone,
          gender: profile['gender'] ?? userData.gender,
        );
        await AuthSession.updateUserData(fullUser);
      } catch (_) {}

      await context.read<CartProvider>().setCurrentUserId(
        userData.email,
        mergeFromGuest: true,
      );

      if (mounted) {
        await context.read<WishlistProvider>().init();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Server connection failed. Please check if backend is running at ${AppConfig.apiBaseUrl}',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToAdminLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
    );
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
          child: Stack(
            children: [
              // Decorative background shapes (approximation)
              Positioned(
                bottom: -50,
                left: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 100,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Container(
                          margin: EdgeInsets.all(
                            AppDimensions.padding(context),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: r.value(
                              smallMobile: 360,
                              mobile: 400,
                              tablet: 450,
                              smallDesktop: 900,
                              desktop: 1000,
                            ),
                            maxHeight:
                                isStackedLayout ? double.infinity : r.hp(70),
                          ),
                          child: Card(
                            elevation: 8,
                            shadowColor: Colors.black26,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child:
                                isStackedLayout
                                    ? _buildStackedLayout(r)
                                    : _buildDesktopLayout(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
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
          colors: [Color(0xFF1E40AF), Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.padding(context)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260, maxHeight: 260),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                'Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[850],
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildInputField(
              'Email or Username',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.alternate_email,
              validator:
                  (v) => (v == null || v.isEmpty) ? 'Enter your email' : null,
            ),
            const SizedBox(height: 10),
            _buildInputField(
              'Password',
              controller: _passwordController,
              isPassword: true,
              obscureText: _obscurePassword,
              prefixIcon: Icons.lock,
              onTogglePassword:
                  () => setState(() => _obscurePassword = !_obscurePassword),
              validator:
                  (v) => (v == null || v.length < 4) ? 'Min 4 characters' : null,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _navigateToAdminLogin,
                  child: const Text(
                    'Login as Admin',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 140,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B5F6),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const Signup()),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 13),
                      children: [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: "Register",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Back to store link at bottom
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  );
                },
                child: Text(
                  'Back to Store',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
          prefixIcon:
              prefixIcon != null
                  ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(prefixIcon, color: Colors.black, size: 24),
                  )
                  : null,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 24,
          ),
          suffixIcon:
              isPassword
                  ? IconButton(
                    onPressed: onTogglePassword,
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black,
                      size: 22,
                    ),
                  )
                  : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF64B5F6), width: 2),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }
}
