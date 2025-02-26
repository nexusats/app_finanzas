import 'package:flutter/material.dart';
import 'package:app_finanzas/config/pallete.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final double horizontalPadding;

  const SocialButton({
    super.key,
    required this.iconPath,
    required this.label,
    this.horizontalPadding = 100,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      child: TextButton.icon(
        onPressed: () {},
        icon: SvgPicture.asset(
          iconPath,
          width: 25,
          colorFilter: const ColorFilter.mode(Pallete.whiteColor, BlendMode.srcIn),
        ),
        label: Text(
          label,
          style: const TextStyle(
            color: Pallete.whiteColor,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: horizontalPadding),
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              color: Pallete.borderColor,
              width: 2.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
