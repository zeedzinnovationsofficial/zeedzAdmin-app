import 'package:flutter/material.dart';
import 'package:zeedz_attendance/User/dailydata/widget/punch_detailcard_widget.dart';

class PunchDetailrowWidget extends StatelessWidget {
  final PunchDetailcardWidget leftCard;
  final PunchDetailcardWidget rightCard;

  const PunchDetailrowWidget({
    super.key,
    required this.leftCard,
    required this.rightCard,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Row(
      children: [
        SizedBox(width: size.width * 0.03),

        leftCard,

        SizedBox(width: size.width * 0.02),

        rightCard,
      ],
    );
  }
}
