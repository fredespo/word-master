import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProgressDialog extends StatefulWidget {
  final ValueListenable<double> progress;
  final String message;

  const ProgressDialog({
    super.key,
    required this.progress,
    required this.message,
  });

  @override
  State<ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<ProgressDialog> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: Text(widget.message),
        content: ValueListenableBuilder<double>(
          valueListenable: widget.progress,
          builder: (context, value, child) {
            if (value >= 1.0) {
              Navigator.of(context).pop();
            }
            return LinearProgressIndicator(
              value: value,
            );
          },
        ),
      ),
    );
  }
}
