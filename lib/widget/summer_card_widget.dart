// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';

class SummaryCard extends StatefulWidget {
  final String value;
  final String title;
  final Color valueColor;
  final double fontSize;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.value,
    required this.title,
    required this.valueColor,
    this.fontSize = 35,
    this.onTap,
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => isPressed = false),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()
          ..scale(isPressed ? 0.96 : 1.0), // 👇 press effect

        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),

          ///  Dynamic shadow (lift effect)
          boxShadow: [
            BoxShadow(
              color: isPressed
                  ? Colors.black12
                  : Colors.black.withOpacity(0.15),
              blurRadius: isPressed ? 4 : 10,
              offset: Offset(0, isPressed ? 2 : 6),
            ),
          ],
        ),

        child: Container(
          padding: const EdgeInsets.all(12),
          height: size.height * 0.16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),

            /// ✨ Glow border
            border: Border.all(
              color: isPressed
                  ? widget.valueColor.withOpacity(0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.value,
                style: TextStyle(
                  color: widget.valueColor,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: size.height * 0.04),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
