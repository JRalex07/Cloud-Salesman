import 'package:flutter/material.dart';

class KpiCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color baseColor;
  final String? subtitle;
  final double? progressPercentage; // e.g. 0.85 (85%)
  final double? trendPercentage; // e.g. 5.4 (+5.4%) or -2.3 (-2.3%)

  const KpiCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.baseColor = const Color(0xFF1E3A8A),
    this.subtitle,
    this.progressPercentage,
    this.trendPercentage,
  }) : super(key: key);

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Determine trend widget
    Widget? trendWidget;
    if (widget.trendPercentage != null) {
      final double trend = widget.trendPercentage!;
      final bool isPositive = trend >= 0;
      final Color trendColor = isPositive ? Colors.green : Colors.red;
      final IconData trendIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
      
      trendWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trendIcon, size: 10, color: trendColor),
          const SizedBox(width: 2),
          Text(
            '${isPositive ? "+" : ""}${trend.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: trendColor,
            ),
          ),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)), // Standardized Slate 200
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: widget.baseColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B), // Standardized Slate 500
                        letterSpacing: 1,
                      ),
                    ),
                    Icon(widget.icon, color: widget.baseColor, size: 18),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (trendWidget != null) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: trendWidget,
                      ),
                    ],
                  ],
                ),
                if (widget.progressPercentage != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.progressPercentage,
                      backgroundColor: const Color(0xFFF1F5F9), // Standardized Slate 100
                      valueColor: AlwaysStoppedAnimation<Color>(widget.baseColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

