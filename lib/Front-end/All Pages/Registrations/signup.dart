import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../utils/api_service.dart';
import '../../Dimensions/responsive_dimensions.dart';
import '../../pages/home_page.dart';
import '../../utils/auth_session.dart';
import '../CART/Cart_provider.dart';
import '../../pages/Profiles/Wishlist_provider.dart';
import 'login.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  static const String _logoPath = 'assets/elogo.png';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Signup with API
  Future<void> _onSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final parts = name.split(RegExp(r'\s+'));
      final firstName = parts.isNotEmpty ? parts.first : 'User';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Call register API
      final result = await ApiService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: '',
        gender: 'Male',
      );

      if (!mounted) return;

      // Check response
      if (result['token'] == null || result['user'] == null) {
        throw ApiException('Registration failed. Please try again.', 400);
      }

      final token = (result['token'] ?? '').toString();
      final userMap = result['user'] as Map<String, dynamic>?;

      if (token.isEmpty || userMap == null) {
        throw ApiException('Registration failed. Please try again.', 400);
      }

      // Create user data from response
      final userData = UserData(
        firstName: userMap['firstName'] ?? userMap['full_name'] ?? firstName,
        lastName: userMap['lastName'] ?? userMap['last_name'] ?? lastName,
        email: userMap['email'] ?? email,
        phone: userMap['phone'] ?? userMap['phone_number'] ?? '',
        gender: userMap['gender'] ?? 'Male',
      );

      // Save to session
      await AuthSession.saveUserData(userData);
      await AuthSession.saveToken(token);
      await ApiService.saveToken(token); // keep ApiService in-memory cache in sync
      await AuthSession.setAdmin(false);
      await AuthSession.setLoggedIn(true);

      // Try to get full profile
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
      } catch (_) {
        // Profile fetch failed, continue with basic data
      }

      // Set user ID in cart and merge guest cart
      if (mounted) {
        await context.read<CartProvider>().setCurrentUserId(
          userData.email,
          mergeFromGuest: true,
        );
      }

      // Sync wishlist from server after signup
      if (mounted) {
        await context.read<WishlistProvider>().init();
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
        ),
      );

      // Navigate to home
      Navigator.pushAndRemoveUntil(
        context,
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
        const SnackBar(
          content: Text(
            'Server connection failed. Please check if backend is running.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
            colors: [Color(0xFFFFD54F), Color(0xFF64B5F6)],
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
                        maxHeight: isStackedLayout ? double.infinity : r.hp(85),
                      ),
                      child: Card(
                        elevation: 10,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadius(context) + 6,
                          ),
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
          colors: [Color(0xFF1E40AF), Color(0xFFFBBF24)],
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
                  Icon(Icons.bolt, color: Colors.white, size: 80),
                  SizedBox(height: 8),
                  Text('ElectroZoneBD',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
      padding: EdgeInsets.all(AppDimensions.padding(context)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                'Register Your Account',
                style: TextStyle(
                  fontSize: AppDimensions.titleFont(context) * 0.85,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A3AFF),
                ),
              ),
            ),
            SizedBox(height: AppDimensions.padding(context)),
            _buildInputField(
              'Name',
              controller: _nameController,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            _buildInputField(
              'Email Address',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  !GetUtils.isEmail(v ?? '') ? 'Invalid Email' : null,
            ),
            _buildInputField(
              'Password',
              controller: _passwordController,
              isPassword: true,
              obscureText: _obscurePassword,
              onTogglePassword: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              validator: (v) =>
                  (v != null && v.length < 6) ? 'Min 6 chars' : null,
            ),
            _buildInputField(
              'Confirm Password',
              controller: _confirmPasswordController,
              isPassword: true,
              obscureText: _obscureConfirmPassword,
              onTogglePassword: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              validator: (v) => v != _passwordController.text
                  ? 'Passwords do not match'
                  : null,
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeight(context),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                        'SIGN UP',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already registered? ',
                  style: TextStyle(color: Colors.grey),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LogIn()),
                    );
                  },
                  child: const Text('Login'),
                ),
              ],
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
    String? Function(String?)? validator,
  }) {
    IconData prefixIcon;
    if (label.toLowerCase().contains('email')) {
      prefixIcon = Icons.email_outlined;
    } else if (label.toLowerCase().contains('password')) {
      prefixIcon = Icons.lock_outline;
    } else if (label.toLowerCase().contains('phone')) {
      prefixIcon = Icons.phone_outlined;
    } else if (label.toLowerCase().contains('name')) {
      prefixIcon = Icons.person_outline;
    } else {
      prefixIcon = Icons.text_fields;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 60,
        child: TextFormField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: label,
            isDense: false,
            prefixIcon: Icon(prefixIcon, size: 24),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: onTogglePassword,
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      size: 24,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
