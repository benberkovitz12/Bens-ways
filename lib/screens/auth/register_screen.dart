import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'auth_widgets.dart';

// ─────────────────────────────────────────────────────────────────
//  REGISTER SCREEN
//  Create a new account: name + email + password (+ confirm).
//  The name is saved as the Firebase displayName, which feeds the
//  home greeting ("שלום <name>").
//
//  On success, the auth gate swaps to HomeScreen automatically — we
//  just pop back so the gate (now seeing a logged-in user) takes over.
// ─────────────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    // Client-side checks for instant feedback.
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'נא למלא את כל השדות.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'כתובת המייל אינה תקינה.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'הסיסמה חייבת להכיל לפחות 6 תווים.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'הסיסמאות אינן תואמות.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final err = await AuthService.instance.register(
      name: name,
      email: email,
      password: pass,
    );

    if (!mounted) return;

    if (err == null) {
      // Success — pop back to the gate, which now sees a logged-in
      // user and shows HomeScreen.
      Navigator.pop(context);
    } else {
      setState(() {
        _loading = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Back button — visual left ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.accentDark,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, size: 19),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'יצירת חשבון',
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
                      'הצטרפו והתחילו לגלות מסלולים',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.font,
                        fontSize: 15,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Name ──────────────────────────────────
                    AuthField(
                      controller: _nameCtrl,
                      hint: 'שם מלא',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 14),

                    // ── Email ─────────────────────────────────
                    AuthField(
                      controller: _emailCtrl,
                      hint: 'אימייל',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),

                    // ── Password ──────────────────────────────
                    AuthField(
                      controller: _passCtrl,
                      hint: 'סיסמה (לפחות 6 תווים)',
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
                    const SizedBox(height: 14),

                    // ── Confirm password ──────────────────────
                    AuthField(
                      controller: _confirmCtrl,
                      hint: 'אימות סיסמה',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                    ),

                    // ── Error ─────────────────────────────────
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

                    // ── Submit ────────────────────────────────
                    AuthButton(
                      label: 'הרשמה',
                      loading: _loading,
                      onTap: _submit,
                    ),
                    const SizedBox(height: 20),

                    // ── Back to login ─────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _loading ? null : () => Navigator.pop(context),
                          child: const Text(
                            'התחברות',
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
                          'כבר יש לכם חשבון?',
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
          ],
        ),
      ),
    );
  }
}
