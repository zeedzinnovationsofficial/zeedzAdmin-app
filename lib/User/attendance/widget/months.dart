import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class Months extends StatefulWidget {
  final Function(int)? onMonthSelected;
  const Months({super.key, this.onMonthSelected});

  @override
  State<Months> createState() => _MonthsState();
}

class _MonthsState extends State<Months> {
  int selectedIndex = DateTime.now().month - 1;

  final List<String> months = const [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentMonthIndex = DateTime.now().month - 1;

    return SizedBox(
      height: size.height * 0.04,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: months.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          final isFutureMonth = index > currentMonthIndex;

          return GestureDetector(
            onTap: isFutureMonth
                ? null
                : () {
                    setState(() {
                      selectedIndex = index;
                    });
                    widget.onMonthSelected?.call(index + 1);
                    context.read<PunchProvider>().setSelectedMonth(
  DateTime(DateTime.now().year, index + 1),
);

                    // showModalBottomSheet(
                    //   context: context,
                    //   isScrollControlled: true,
                    //   shape: const RoundedRectangleBorder(
                    //     borderRadius: BorderRadius.vertical(
                    //       top: Radius.circular(25),
                    //     ),
                    //   ),
                    //   builder: (context) {
                    //     return MonthsStats(month: months[index]);
                    //   },
                    // );
                  },
            child: Opacity(
              opacity: isFutureMonth ? 0.4 : 1,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.royalblue
                      : AppColors.shadowgrey,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  months[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.black,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
