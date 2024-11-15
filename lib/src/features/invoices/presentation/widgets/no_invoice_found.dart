import 'package:flutter/material.dart';

class NoInvoicesFound extends StatelessWidget {
  const NoInvoicesFound({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No Invoices found.',
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}
