import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'auth_widgets.dart';
import 'register_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  LOGIN SCREEN
//  Email + password sign-in. On success, the auth gate (in main.dart)
//  automatically swaps to HomeScreen — this screen doesn't navigate
//  itself; it just calls signIn and lets the gate react.
//
//  Validation is client-side first (empty / obviously-bad email) for
//  instant feedback, then Firebase's own errors (wrong password, etc.)
//  come back as friendly Hebrew strings from AuthService.
// ─────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    // Quick client-side checks for instant feedback.
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'נא למלא מייל וסיסמה.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'כתובת המייל אינה תקינה.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final err = await AuthService.instance.signIn(email: email, password: pass);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err; // null = success; the gate handles navigation.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // ── Brand mark ──────────────────────────────────
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Icon(Icons.hiking_rounded,
                      size: 44, color: AppTheme.black),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ברוכים השבים',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'התחברו כדי להמשיך לטייל',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 15,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 30),

                // ── Email ───────────────────────────────────────
                AuthField(
                  controller: _emailCtrl,
                  hint: 'אימייל',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                // ── Password ────────────────────────────────────
                AuthField(
                  controller: _passCtrl,
                  hint: 'סיסמה',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),

                // ── Error message ───────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: 13,
                      color: Color(0xFFC0392B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Submit ──────────────────────────────────────
                AuthButton(
                  label: 'התחברות',
                  loading: _loading,
                  onTap: _submit,
                ),
                const SizedBox(height: 20),

                // ── Go to register ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _loading
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              ),
                      child: const Text(
                        'הרשמה',
                        style: TextStyle(
                          fontFamily: AppTheme.font,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.tagText,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'אין לכם חשבון?',
                      style: TextStyle(
                        fontFamily: AppTheme.font,
                        fontSize: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
