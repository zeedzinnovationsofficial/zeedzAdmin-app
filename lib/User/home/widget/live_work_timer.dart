import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class LiveWorkTimer extends StatefulWidget {
  const LiveWorkTimer({super.key});

  @override
  State<LiveWorkTimer> createState() => _LiveWorkTimerState();
}

class _LiveWorkTimerState extends State<LiveWorkTimer> {
  Timer? _timer;
  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _checkAndStart();
  }

  void _checkAndStart() {
    final provider = context.read<PunchProvider>();

    if (provider.isRunning && provider.punchInTime != null) {
      _startTimer(provider.punchInTime!);
    } else if (!provider.isRunning &&
        provider.punchInTime != null &&
        provider.punchOutTime != null) {
      _setFinalDuration(
          provider.punchInTime!, provider.punchOutTime!);
    }
  }

  void _startTimer(DateTime punchIn) {
    _timer?.cancel();

    duration = _safeDifference(punchIn);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final provider = context.read<PunchProvider>();

      if (provider.isRunning &&
          provider.punchInTime != null) {
        setState(() {
          duration =
              _safeDifference(provider.punchInTime!);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _setFinalDuration(
      DateTime punchIn, DateTime punchOut) {
    _timer?.cancel();
    setState(() {
      duration = punchOut.difference(punchIn);
    });
  }

  Duration _safeDifference(DateTime start) {
    final diff =
        DateTime.now().difference(start);
    return diff.isNegative ? Duration.zero : diff;
  }

  String format(Duration d) {
    return "${d.inHours.toString().padLeft(2, '0')}:"
        "${(d.inMinutes % 60).toString().padLeft(2, '0')}:"
        "${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PunchProvider>();

    // Only react to state changes, not every build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkAndStart();
    });

    return Text(
      format(duration),
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}