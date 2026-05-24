import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../repositories/auth_repository.dart';
import '../../providers/global_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isPhoneNumber = false;
  bool _otpSent = false;
  String? _verificationId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isPhoneNumber) {
      if (_otpSent) {
        await _verifyOtp();
      } else {
        await _sendOtp();
      }
    } else {
      await _handleEmailLogin();
    }
  }

  Future<void> _handleEmailLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmailAndPassword(
        _identifierController.text.trim(),
        _passwordController.text,
      );

      // Update local profile state
      await ref.read(salesmanProfileProvider.notifier).refresh();

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll(RegExp(r'\[.*\]'), '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendOtp() async {
    final phoneNum = _identifierController.text.trim();
    if (phoneNum.isEmpty) {
      setState(() {
        _errorMessage = 'Phone number is required';
      });
      return;
    }

    String formattedPhone = phoneNum;
    if (!phoneNum.startsWith('+')) {
      final cleanDigits = phoneNum.replaceAll(RegExp(r'\D'), '');
      if (cleanDigits.length == 10) {
        formattedPhone = '+91$cleanDigits';
      } else {
        setState(() {
          _errorMessage =
              'Please provide the number with country prefix (e.g. +91...)';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        onCodeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification code sent to $formattedPhone'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onFailed: (errorMessage) {
          if (!kDebugMode) {
            setState(() {
              _isLoading = false;
              _errorMessage = errorMessage;
            });
            return;
          }
          setState(() {
            _verificationId = 'mock-verification-id-bypass:$formattedPhone';
            _otpSent = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '[SANDBOX BYPASS] Mock code 123456 ready for $formattedPhone'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    } catch (e) {
      if (!kDebugMode) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        return;
      }
      setState(() {
        _verificationId = 'mock-verification-id-bypass:$formattedPhone';
        _otpSent = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '[SANDBOX BYPASS] Mock code 123456 ready for $formattedPhone'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.isEmpty || smsCode.length < 6) {
      setState(() {
        _errorMessage = 'Please enter the 6-digit OTP';
      });
      return;
    }

    if (_verificationId == null) {
      setState(() {
        _errorMessage = 'Invalid verification session. Please resend OTP.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithPhoneCredential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      // Refresh local profile state
      await ref.read(salesmanProfileProvider.notifier).refresh();

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll(RegExp(r'\[.*\]'), '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isWide = width >= 650;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: isWide ? const EdgeInsets.all(32.0) : EdgeInsets.zero,
            decoration: isWide
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey[200]!,
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  )
                : null,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPhoneNumber
                                ? Icons.phone_android
                                : Icons.cloud_upload_outlined,
                            size: 40,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Cloud Power Salesman',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to manage shops, routes, and place bulk orders.',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Beautiful Tab Bar Segmented Control
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPhoneNumber = false;
                                _otpSent = false;
                                _verificationId = null;
                                _identifierController.clear();
                                _passwordController.clear();
                                _otpController.clear();
                                _errorMessage = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isPhoneNumber
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: !_isPhoneNumber
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 16,
                                      color: !_isPhoneNumber
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Email Login',
                                      style: TextStyle(
                                        fontWeight: !_isPhoneNumber
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: !_isPhoneNumber
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPhoneNumber = true;
                                _otpSent = false;
                                _verificationId = null;
                                _identifierController.clear();
                                _passwordController.clear();
                                _otpController.clear();
                                _errorMessage = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isPhoneNumber
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _isPhoneNumber
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: _isPhoneNumber
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Phone Login',
                                      style: TextStyle(
                                        fontWeight: _isPhoneNumber
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: _isPhoneNumber
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomTextField(
                    label: _isPhoneNumber ? 'Phone Number' : 'Email Address',
                    placeholder: _isPhoneNumber
                        ? '+919876543210'
                        : 'salesman@cloudpower.com',
                    controller: _identifierController,
                    keyboardType: _isPhoneNumber
                        ? TextInputType.phone
                        : TextInputType.emailAddress,
                    prefixIcon: _isPhoneNumber
                        ? Icons.phone_outlined
                        : Icons.email_outlined,
                    enabled: !_otpSent,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return _isPhoneNumber
                            ? 'Phone number is required'
                            : 'Email address is required';
                      }
                      if (!_isPhoneNumber && !v.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  if (!_isPhoneNumber) ...[
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Password',
                      placeholder: '••••••••',
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline,
                      validator: (v) => v == null || v.length < 6
                          ? 'Minimum 6 characters required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        child: const Text('Forgot Password?'),
                        onPressed: () => context.push('/forgot-password'),
                      ),
                    ),
                  ] else if (_otpSent) ...[
                    if (kDebugMode &&
                        _verificationId != null &&
                        _verificationId!
                            .startsWith('mock-verification-id-bypass:')) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sandbox View Helper (Debug Only)',
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'To perform testing inside the current dev sandbox, use the verification code: 123456.',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'One-Time Password (OTP)',
                      placeholder: 'Enter 6-digit OTP code',
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.security_outlined,
                      validator: (v) => v == null || v.length < 6
                          ? 'Please enter a valid 6-digit OTP'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _otpSent = false;
                              _verificationId = null;
                              _otpController.clear();
                            });
                          },
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Change Phone'),
                        ),
                        TextButton.icon(
                          onPressed: _sendOtp,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Resend OTP'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  CustomButton(
                    text: _isPhoneNumber
                        ? (_otpSent ? 'Verify & Sign In' : 'Send OTP')
                        : 'Sign In',
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
