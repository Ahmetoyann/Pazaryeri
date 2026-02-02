import 'dart:async';
import 'package:flutter/material.dart';

enum StatusType { error, success }

class StatusMessageWidget extends StatefulWidget {
  final String message;
  final StatusType type;
  final VoidCallback onClose;
  final Duration? autoCloseDuration;

  const StatusMessageWidget({
    super.key,
    required this.message,
    required this.type,
    required this.onClose,
    this.autoCloseDuration,
  });

  @override
  State<StatusMessageWidget> createState() => _StatusMessageWidgetState();
}

class _StatusMessageWidgetState extends State<StatusMessageWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoCloseDuration != null) {
      _timer = Timer(widget.autoCloseDuration!, () {
        if (mounted) {
          widget.onClose();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.type == StatusType.error;
    final backgroundColor = isError ? Colors.red.shade50 : Colors.green.shade50;
    final borderColor = isError ? Colors.red.shade200 : Colors.green.shade200;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;
    final iconColor = isError ? Colors.red.shade700 : Colors.green.shade700;
    final textColor = isError ? Colors.red.shade900 : Colors.green.shade900;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.message,
              style: TextStyle(color: textColor),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: textColor),
            onPressed: widget.onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
