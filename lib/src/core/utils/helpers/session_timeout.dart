import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/routing/app_routes.dart';
import '../../../features/sign_out/presentation/cubit/sign_out_cubit.dart';

class SessionTimeout extends StatefulWidget {
  const SessionTimeout({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<SessionTimeout> createState() => _SessionTimeoutState();
}

class _SessionTimeoutState extends State<SessionTimeout> {
  Timer? _timer;
  Timer? _countdownTimer;
  int _remainingTime = 600; // 10 minutes

  void _startTimer() {
    // Cancel any existing timers
    _timer?.cancel();
    _countdownTimer?.cancel();

    // Reset remaining time to 10 minutes
    _remainingTime = 600;

    // Start the periodic countdown timer to print remaining time every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        _remainingTime--;
      } else {
        timer.cancel(); // Cancel countdown timer when it reaches 0
      }
    });

    // Start the main timer to sign out after 10 minutes
    _timer = Timer(
      const Duration(seconds: 600),
      () {
        context.read<SignOutCubit>().signOut(context);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _startTimer();
      },
      child: BlocConsumer<SignOutCubit, SignOutState>(
        listener: (context, state) {
          if (state is SignOutSuccessful) {
            Navigator.of(context).pushNamedAndRemoveUntil(Routes.signIn, (route) => false);
          }
        },
        builder: (context, state) {
          return widget.child;
        },
      ),
    );
  }
}
