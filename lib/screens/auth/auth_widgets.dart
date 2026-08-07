import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────
//  SHARED AUTH WIDGETS
//  A rounded text field and a primary button, both styled to the app
//  theme, used by both login_screen and register_screen so the two
//  stay consistent and DRY.
//
//  RTL: inherited app-wide. Fields are right-aligned; the leading icon
//  sits on the visual RIGHT (where the label text starts in RTL).
// ─────────────────────────────────────────────────────────────────

// ── A rounded, labelled text field ─────────────────────────────────
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffix;

  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: const TextStyle(fontFamily: AppTheme.font, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: AppTheme.font,
            fontSize: 14,
            color: Color(0xFFC0C0C0),
          ),
          // Icon on the visual RIGHT in RTL (suffixIcon = trailing =
          // right when direction is rtl).
          suffixIcon: Icon(icon, size: 20, color: AppTheme.textMuted),
          prefixIcon: suffix,
          filled: true,
          fillColor: AppTheme.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ── Primary filled button (with a loading spinner state) ────────────
class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const AuthButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: loading ? AppTheme.accent.withOpacity(0.6) : AppTheme.accent,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          boxShadow: AppTheme.ctaShadow,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: AppTheme.black),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
