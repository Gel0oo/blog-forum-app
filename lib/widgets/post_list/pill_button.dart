// lib/widgets/post_list/pill_button.dart

import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

class PillButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool filled;
  final VoidCallback? onTap;

  const PillButton({
    super.key,
    required this.icon,
    this.label,
    this.filled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = filled ? Colors.white : null;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: iconColor),
        if (label != null) ...[
          const SizedBox(width: 6),
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : null,
              height: 1.0,
            ),
          ),
        ],
      ],
    );

    final button = filled
        ? shadcn.PrimaryButton(
            density: shadcn.ButtonDensity.dense,
            onPressed: onTap,
            child: content,
          )
        : shadcn.OutlineButton(
            density: shadcn.ButtonDensity.dense,
            onPressed: onTap,
            child: content,
          );

    return SizedBox(height: 32, child: button);
  }
}