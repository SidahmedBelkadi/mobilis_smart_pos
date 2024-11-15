import 'package:flutter/material.dart';

class ExitConfirmation extends StatefulWidget {
  const ExitConfirmation({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ExitConfirmation> createState() => _ExitConfirmationState();
}

class _ExitConfirmationState extends State<ExitConfirmation> {
  Future<bool> _onPopInvoked() async {
    final shouldExit = await showExitConfirmationDialog(context);
    return shouldExit ?? false;
  }

  static Future<bool?> showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Are you sure you want to exit?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Exit'),
              onPressed: () {},
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (isPopped) async {
        if (mounted) {
          final shouldExit = await _onPopInvoked();
          if (shouldExit) {
            Navigator.of(context).pop(true); // Close the app
          } else {
            Navigator.of(context).pop(false); // Do not close the app
          }
        }
      },
      child: widget.child,
    );
  }
}
