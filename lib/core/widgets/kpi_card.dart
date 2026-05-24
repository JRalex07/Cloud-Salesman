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
      final IconData trendIcon =
          isPositive ? Icons.arrow_upward : Icons.arrow_downward;

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
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: SizedBox(
          height:
              120, // Predictable fixed height constraints to ensure uniform visual style
          child: Card(
            margin: EdgeInsets.zero,
            elevation: _isHovered ? 4.0 : 1.0,
            shadowColor:
                _isHovered ? widget.baseColor.withOpacity(0.4) : Colors.black12,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: widget.baseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(widget.icon,
                              color: widget.baseColor, size: 16),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.value,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                        if (trendWidget != null) ...[
                          const SizedBox(width: 6),
                          trendWidget,
                        ],
                      ],
                    ),
                    if (widget.progressPercentage != null) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: widget.progressPercentage,
                          backgroundColor: Colors.grey[200],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(widget.baseColor),
                          minHeight: 4,
                        ),
                      ),
                    ],
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
