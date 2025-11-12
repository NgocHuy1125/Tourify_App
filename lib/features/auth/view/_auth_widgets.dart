import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kBrand = Color(0xFFFF5B00);
const kGray = Color(0xFF8E8E93);

TextStyle headingStyle(BuildContext ctx) =>
    GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700);

InputDecoration authInput(String label, {Widget? suffix}) => InputDecoration(
  labelText: label,
  floatingLabelBehavior: FloatingLabelBehavior.auto,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: kBrand, width: 2),
  ),
  suffixIcon: suffix,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
);

class SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
