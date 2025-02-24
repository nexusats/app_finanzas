import 'package:flutter/material.dart';
import 'package:app_finanzas/config/pallete.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback onPressed; // Agregamos la función de callback
  final String label;

  const GradientButton({super.key, required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Pallete.gradient1,
            Pallete.gradient2,
            Pallete.gradient3,
          ],
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: ElevatedButton(
        onPressed: onPressed, // Llamamos la función pasada
        style: ElevatedButton.styleFrom(
          fixedSize: const Size.fromHeight(55),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}
