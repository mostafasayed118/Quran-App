import 'package:flutter/material.dart';

class DownloadProgressLabel extends StatelessWidget {
  const DownloadProgressLabel({
    super.key,
    required this.received,
    required this.total,
    this.format,
    this.width = 132,
    this.gap = 6,
    this.labelStyle,
  });

  final int received;
  final int total;
  final String Function(int received, int total)? format;
  final double width;
  final double gap;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            format?.call(received, total) ?? '$received/$total',
            style: labelStyle,
          ),
          SizedBox(height: gap),
          LinearProgressIndicator(
            value:
                total > 0 ? (received / total).clamp(0.0, 1.0) : null,
          ),
        ],
      ),
    );
  }
}
