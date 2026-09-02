import 'package:flutter/material.dart'
    show
        Alignment,
        BorderRadius,
        BorderSide,
        BoxConstraints,
        BoxDecoration,
        BoxShadow,
        BuildContext,
        Center,
        CircularProgressIndicator,
        Color,
        Colors,
        Column,
        Container,
        EdgeInsets,
        ElevatedButton,
        FontWeight,
        Form,
        FormState,
        GlobalKey,
        InputDecoration,
        LinearGradient,
        MainAxisSize,
        MaterialPageRoute,
        Navigator,
        Offset,
        OutlineInputBorder,
        RoundedRectangleBorder,
        Scaffold,
        SingleChildScrollView,
        SizedBox,
        State,
        StatefulWidget,
        Text,
        TextAlign,
        TextButton,
        TextEditingController,
        TextFormField,
        TextInputType,
        TextStyle,
        Widget,
        Row,
        MainAxisAlignment;
import '../../utils/api_service.dart';
import 'login.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0; // 0: Email, 1: Code, 2: Password
  bool _isLoading = false;
  bool _isResending = false;
  String _userEmail = '';
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final email = _emailController.text.trim();

      final response = await ApiService.post('/password_reset', {
        'action': 'request_reset',
        'email': email,
      });

      if (response['success'] == true) {
        setState(() {
          _userEmail = email;
          _currentStep = 1;
          _successMessage = response['message'] ?? 'Code sent to your email!';
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to send code';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Unable to send code. Please check your connection and try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter the code');
      return;
    }

    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final response = await ApiService.post('/password_reset', {
        'action': 'verify_code',
        'code': code,
      });

      if (response['success'] == true) {
        setState(() {
          _currentStep = 2;
          _successMessage = response['message'] ?? 'Code verified!';
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Invalid or expired code';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to verify code. Please try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final response = await ApiService.post('/password_reset', {
        'action': 'request_reset',
        'email': _userEmail,
      });

      if (response['success'] == true) {
        _codeController.clear();
        setState(
          () => _successMessage = 'A new code has been sent to $_userEmail',
        );
      } else {
        setState(
          () => _errorMessage = response['message'] ?? 'Failed to resend code',
        );
      }
    } catch (e) {
      setState(
        () => _errorMessage = 'Unable to resend code. Please try again.',
      );
    } finally {
      setState(() => _isResending = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final response = await ApiService.post('/password_reset', {
        'action': 'reset_password',
        'code': _codeController.text.trim(),
        'new_password': _passwordController.text,
      });

      if (response['success'] == true) {
        setState(() => _successMessage = 'Password changed successfully!');

        // Navigate to login after 1 second
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LogIn()),
            );
          }
        });
      } else {
        setState(
          () =>
              _errorMessage = response['message'] ?? 'Failed to reset password',
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: Unable to reset password');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      _currentStep == 0
                          ? 'Forgot Password'
                          : _currentStep == 1
                          ? 'Code Verification'
                          : 'New Password',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Success Message
                    if (_successMessage.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4EDDA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _successMessage,
                          style: const TextStyle(
                            color: Color(0xFF155724),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Error Message
                    if (_errorMessage.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8D7DA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Color(0xFF721C24),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Step Content
                    if (_currentStep == 0) _buildEmailStep(),
                    if (_currentStep == 1) _buildCodeStep(),
                    if (_currentStep == 2) _buildPasswordStep(),

                    const SizedBox(height: 20),

                    // Back to Login
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          color: Color(0xFF7C4DFF),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        const Text(
          'Enter your email address',
          style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
        ),
        const SizedBox(height: 30),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter email address',
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter email';
            if (!v.contains('@')) return 'Invalid email';
            return null;
          },
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      children: [
        // Email sent confirmation
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFD4EDDA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'We\'ve sent a password reset OTP to your email - $_userEmail',
            style: const TextStyle(color: Color(0xFF155724), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 30),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            hintText: 'Enter code',
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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
                    'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Didn't receive the code? ",
              style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 14),
            ),
            _isResending
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF7C4DFF),
                    ),
                  )
                : TextButton(
                    onPressed: _resendCode,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text(
                      'Resend',
                      style: TextStyle(
                        color: Color(0xFF7C4DFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFD4EDDA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Please create a new password that you don\'t use on any other site.',
            style: TextStyle(color: Color(0xFF155724), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 30),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Create new password',
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter password';
            if (v.length < 6) return 'Min 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Confirm your password',
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Confirm password';
            return null;
          },
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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
                    'Change',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

