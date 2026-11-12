import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/health_models.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatters.dart';

class ChartSeriesConfig {
  const ChartSeriesConfig({
    required this.label,
    required this.color,
    required this.values,
  });

  final String label;
  final Color color;
  final List<double> values;
}

class ChartReferenceLine {
  const ChartReferenceLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class TrendChartCard extends StatefulWidget {
  const TrendChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.unit,
    required this.timestamps,
    required this.series,
    required this.trendSummary,
    this.secondaryTrendSummary,
    this.dotStatuses = const [],
    this.targetBandMin,
    this.targetBandMax,
    this.referenceLines = const [],
  });

  final String title;
  final String subtitle;
  final String unit;
  final List<String> timestamps;
  final List<ChartSeriesConfig> series;
  final ChartTrendSummary trendSummary;
  final ChartTrendSummary? secondaryTrendSummary;
  final List<String> dotStatuses;
  final double? targetBandMin;
  final double? targetBandMax;
  final List<ChartReferenceLine> referenceLines;

  @override
  State<TrendChartCard> createState() => _TrendChartCardState();
}

class _TrendChartCardState extends State<TrendChartCard> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final count = widget.timestamps.length;
    final activeIdx = count == 0
        ? null
        : (_selectedIndex != null && _selectedIndex! < count
            ? _selectedIndex!
            : count - 1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: widget.series
                  .map(
                    (s) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: s.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            _TrendBanner(trend: widget.trendSummary),
            if (widget.secondaryTrendSummary != null && count >= 2) ...[
              const SizedBox(height: 6),
              _TrendBanner(trend: widget.secondaryTrendSummary!),
            ],
            const SizedBox(height: 14),
            if (count == 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.subtleBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No readings in this period yet. Add readings or switch to Weekly or Monthly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              )
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) => _selectPointAt(
                      details.localPosition.dx,
                      constraints.maxWidth,
                      count,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: CustomPaint(
                        painter: _LineChartPainter(
                          timestamps: widget.timestamps,
                          series: widget.series,
                          dotStatuses: widget.dotStatuses,
                          targetBandMin: widget.targetBandMin,
                          targetBandMax: widget.targetBandMax,
                          referenceLines: widget.referenceLines,
                          selectedIndex: activeIdx,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (activeIdx != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.turquoiseSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.turquoiseBorder),
                  ),
                  child: Text(
                    '${formatDateTimeDisplay(widget.timestamps[activeIdx])}: '
                    '${widget.series.map((s) => '${s.label}: ${formatGlucoseValue(s.values[activeIdx])} ${widget.unit}').join(' · ')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _selectPointAt(double dx, double width, int count) {
    if (count <= 0) return;
    const padLeft = 44.0;
    const padRight = 16.0;
    final plotW = math.max(1.0, width - padLeft - padRight);
    if (count == 1) {
      setState(() => _selectedIndex = 0);
      return;
    }
    final ratio = ((dx - padLeft) / plotW).clamp(0.0, 1.0);
    final idx = (ratio * (count - 1)).round().clamp(0, count - 1);
    setState(() => _selectedIndex = idx);
  }
}

class _TrendBanner extends StatelessWidget {
  const _TrendBanner({required this.trend});

  final ChartTrendSummary trend;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color fg;
    String prefix;

    switch (trend.direction) {
      case 'increasing':
        bg = AppColors.yellowBg;
        border = AppColors.yellowBorder;
        fg = AppColors.yellowText;
        prefix = '↑ Increasing';
      case 'decreasing':
        bg = AppColors.tealSoft;
        border = AppColors.tealAccent;
        fg = AppColors.tealPrimary;
        prefix = '↓ Decreasing';
      case 'steady':
        bg = AppColors.greenBg;
        border = AppColors.greenBorder;
        fg = AppColors.greenText;
        prefix = '→ Steady';
      default:
        bg = AppColors.turquoiseSoft;
        border = AppColors.turquoiseBorder;
        fg = AppColors.tealDark;
        prefix = '• Info';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: fg, fontSize: 14, height: 1.35),
          children: [
            TextSpan(
              text: '$prefix  ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: trend.message),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.timestamps,
    required this.series,
    required this.dotStatuses,
    required this.targetBandMin,
    required this.targetBandMax,
    required this.referenceLines,
    required this.selectedIndex,
  });

  final List<String> timestamps;
  final List<ChartSeriesConfig> series;
  final List<String> dotStatuses;
  final double? targetBandMin;
  final double? targetBandMax;
  final List<ChartReferenceLine> referenceLines;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const padLeft = 44.0;
    const padRight = 16.0;
    const padTop = 14.0;
    const padBottom = 30.0;

    final plotW = math.max(1.0, size.width - padLeft - padRight);
    final plotH = math.max(1.0, size.height - padTop - padBottom);

    final allValues = <double>[];
    for (final s in series) {
      allValues.addAll(s.values);
    }
    if (targetBandMin != null) allValues.add(targetBandMin!);
    if (targetBandMax != null) allValues.add(targetBandMax!);
    for (final r in referenceLines) {
      allValues.add(r.value);
    }

    final rawMin = allValues.isEmpty ? 50.0 : allValues.reduce(math.min);
    final rawMax = allValues.isEmpty ? 180.0 : allValues.reduce(math.max);
    final pad = math.max(10.0, (rawMax - rawMin) * 0.12);
    final yMin = math.max(0.0, ((rawMin - pad) / 10).floor() * 10.0);
    final yMax = ((rawMax + pad) / 10).ceil() * 10.0;
    final ySpan = math.max(1.0, yMax - yMin);

    double xFor(int idx) {
      if (timestamps.length <= 1) return padLeft + plotW / 2;
      return padLeft + (idx / (timestamps.length - 1)) * plotW;
    }

    double yFor(double val) {
      return padTop + (1 - (val - yMin) / ySpan) * plotH;
    }

    if (targetBandMin != null && targetBandMax != null) {
      final topY = yFor(math.min(yMax, targetBandMax!));
      final bottomY = yFor(math.max(yMin, targetBandMin!));
      final bandPaint = Paint()..color = AppColors.greenBg;
      canvas.drawRect(
        Rect.fromLTRB(padLeft, topY, size.width - padRight, bottomY),
        bandPaint,
      );
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final val = yMin + (ySpan * i / 4);
      final y = yFor(val);
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), gridPaint);
      _drawText(
        canvas,
        val.round().toString(),
        Offset(padLeft - 6, y - 7),
        const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
        alignRight: true,
      );
    }

    for (final ref in referenceLines) {
      final y = yFor(ref.value);
      if (y < padTop || y > size.height - padBottom) continue;
      final refPaint = Paint()
        ..color = ref.color
        ..strokeWidth = 1.4;
      const dashWidth = 6.0;
      const dashGap = 4.0;
      double startX = padLeft;
      while (startX < size.width - padRight) {
        final endX = math.min(startX + dashWidth, size.width - padRight);
        canvas.drawLine(Offset(startX, y), Offset(endX, y), refPaint);
        startX += dashWidth + dashGap;
      }
    }

    for (final s in series) {
      if (s.values.length >= 2) {
        final path = Path();
        for (int i = 0; i < s.values.length; i++) {
          final pt = Offset(xFor(i), yFor(s.values[i]));
          if (i == 0) {
            path.moveTo(pt.dx, pt.dy);
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = s.color
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    final step = timestamps.length <= 5 ? 1 : (timestamps.length / 4).ceil();
    for (int i = 0; i < timestamps.length; i++) {
      final cx = xFor(i);
      if (i == 0 || i == timestamps.length - 1 || i % step == 0) {
        _drawText(
          canvas,
          formatShortDate(timestamps[i]),
          Offset(cx, size.height - 20),
          const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
          center: true,
        );
      }

      for (final s in series) {
        final cy = yFor(s.values[i]);
        final isSelected = selectedIndex == i;
        Color dotColor = s.color;
        if (series.length == 1 && i < dotStatuses.length) {
          switch (dotStatuses[i]) {
            case 'urgent':
              dotColor = AppColors.redBorder;
            case 'attention':
              dotColor = AppColors.yellowBorder;
            default:
              dotColor = AppColors.greenText;
          }
        }
        canvas.drawCircle(
          Offset(cx, cy),
          isSelected ? 7.5 : 5,
          Paint()..color = dotColor,
        );
        canvas.drawCircle(
          Offset(cx, cy),
          isSelected ? 7.5 : 5,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    bool alignRight = false,
    bool center = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = offset.dx;
    if (alignRight) dx -= painter.width;
    if (center) dx -= painter.width / 2;
    painter.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.timestamps != timestamps ||
        oldDelegate.series != series ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

