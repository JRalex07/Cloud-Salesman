import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../repositories/auth_repository.dart';
import '../../providers/global_providers.dart';

class QuickLoginAccount {
  final String email;
  final String password;
  final String name;
  final String? photoUrl;
  final String lastLogin;

  QuickLoginAccount({
    required this.email,
    required this.password,
    required this.name,
    this.photoUrl,
    required this.lastLogin,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'name': name,
        'photoUrl': photoUrl,
        'lastLogin': lastLogin,
      };

  factory QuickLoginAccount.fromJson(Map<String, dynamic> json) =>
      QuickLoginAccount(
        email: json['email'] as String,
        password: json['password'] as String,
        name: json['name'] as String,
        photoUrl: json['photoUrl'] as String?,
        lastLogin: json['lastLogin'] as String,
      );
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isQuickLogin = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<QuickLoginAccount> _savedAccounts = [];
  bool _saveToQuickLogin = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('quick_login_accounts');
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        setState(() {
          _savedAccounts = decoded
              .map((item) =>
                  QuickLoginAccount.fromJson(item as Map<String, dynamic>))
              .toList();
          if (_savedAccounts.isNotEmpty) {
            _isQuickLogin = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading saved accounts: $e');
    }
  }

  Future<void> _saveAccount(
      String email, String password, String name, String? photoUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedAccounts
          .removeWhere((acc) => acc.email.toLowerCase() == email.toLowerCase());

      _savedAccounts.insert(
        0,
        QuickLoginAccount(
          email: email,
          password: password,
          name: name,
          photoUrl: photoUrl,
          lastLogin: DateTime.now().toIso8601String(),
        ),
      );

      if (_savedAccounts.length > 5) {
        _savedAccounts = _savedAccounts.sublist(0, 5);
      }

      final jsonStr =
          jsonEncode(_savedAccounts.map((acc) => acc.toJson()).toList());
      await prefs.setString('quick_login_accounts', jsonStr);
      setState(() {});
    } catch (e) {
      debugPrint('Error saving account: $e');
    }
  }

  Future<void> _removeAccount(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedAccounts
          .removeWhere((acc) => acc.email.toLowerCase() == email.toLowerCase());
      final jsonStr =
          jsonEncode(_savedAccounts.map((acc) => acc.toJson()).toList());
      await prefs.setString('quick_login_accounts', jsonStr);
      setState(() {});
    } catch (e) {
      debugPrint('Error removing account: $e');
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      await ref.read(salesmanProfileProvider.notifier).refresh();

      final profile = ref.read(salesmanProfileProvider).valueOrNull;
      final salesmanName = profile?.name ?? 'Sales Executive';
      final salesmanPhoto = profile?.photoUrl;

      if (_saveToQuickLogin) {
        await _saveAccount(
          _emailController.text.trim(),
          _passwordController.text,
          salesmanName,
          salesmanPhoto,
        );
      }

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

  Future<void> _handleQuickLogin(QuickLoginAccount account) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmailAndPassword(
        account.email,
        account.password,
      );

      await ref.read(salesmanProfileProvider.notifier).refresh();

      final profile = ref.read(salesmanProfileProvider).valueOrNull;
      final salesmanName = profile?.name ?? account.name;
      final salesmanPhoto = profile?.photoUrl ?? account.photoUrl;

      await _saveAccount(
          account.email, account.password, salesmanName, salesmanPhoto);

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
                            _isQuickLogin
                                ? Icons.fingerprint_rounded
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
                  // Substantial and Aesthetic Tab Bar Segmented Control
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
                                _isQuickLogin = false;
                                _errorMessage = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isQuickLogin
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: !_isQuickLogin
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
                                      color: !_isQuickLogin
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Email Login',
                                      style: TextStyle(
                                        fontWeight: !_isQuickLogin
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: !_isQuickLogin
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
                                _isQuickLogin = true;
                                _errorMessage = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isQuickLogin
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _isQuickLogin
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
                                      Icons.fingerprint_rounded,
                                      size: 16,
                                      color: _isQuickLogin
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Quick Login',
                                      style: TextStyle(
                                        fontWeight: _isQuickLogin
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: _isQuickLogin
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

                  if (_isQuickLogin) ...[
                    if (_savedAccounts.isEmpty) ...[
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            vertical: 36, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fingerprint_rounded,
                                size: 36,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No Saved Accounts',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Log in using Email first and tick "Save account to recently logged in list" to enable one-tap entry next time.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12.0, left: 4.0),
                        child: Text(
                          'RECENTLY LOGGED IN ACCOUNTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      ..._savedAccounts.map((account) {
                        final initial = account.name.trim().isNotEmpty
                            ? account.name.trim().substring(0, 1).toUpperCase()
                            : 'S';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x04000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _isLoading
                                  ? null
                                  : () => _handleQuickLogin(account),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 14.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.12),
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            account.name,
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E293B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            account.email,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.indigo),
                                            ),
                                          )
                                        : IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 20,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () =>
                                                _removeAccount(account.email),
                                            splashRadius: 20,
                                            tooltip: 'Forget account',
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ] else ...[
                    // Email Login
                    CustomTextField(
                      label: 'Email Address',
                      placeholder: 'salesman@cloudpower.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Email address is required';
                        }
                        if (!v.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _saveToQuickLogin,
                            activeColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            onChanged: (v) {
                              setState(() {
                                _saveToQuickLogin = v ?? true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Save account to recently logged in list',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        child: const Text('Forgot Password?'),
                        onPressed: () => context.push('/forgot-password'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Sign In',
                      isLoading: _isLoading,
                      onPressed: _handleEmailLogin,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
