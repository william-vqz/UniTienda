import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

String _abbrev(String name) {
  final parts = name.split(' ');
  if (parts.length <= 2) return name;
  return '${parts.first} ${parts[1][0]}.';
}

String _formatCompact(double amount) {
  if (amount >= 1000) return '\$${(amount / 1000).toStringAsFixed(1)}k';
  return '\$${amount.toInt()}';
}

enum _Period { day, week, fortnight, month }

extension _PeriodExt on _Period {
  String get label {
    switch (this) {
      case _Period.day:       return 'Hoy';
      case _Period.week:      return 'Semana';
      case _Period.fortnight: return 'Quincena';
      case _Period.month:     return 'Mes';
    }
  }
  Duration get duration {
    switch (this) {
      case _Period.day:       return const Duration(days: 1);
      case _Period.week:      return const Duration(days: 7);
      case _Period.fortnight: return const Duration(days: 15);
      case _Period.month:     return const Duration(days: 30);
    }
  }
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _Period _period = _Period.week;

  List<Order> _filtered(List<Order> all) {
    final cutoff = DateTime.now().subtract(_period.duration);
    return all.where((o) => !o.isCancelled && o.createdAt.isAfter(cutoff)).toList();
  }

  /// Top ventas con nombre completo para detalle
  Map<String, List<_SaleItem>> _topSalesDetail(List<Order> orders) {
    final Map<String, List<_SaleItem>> data = {};
    for (final o in orders) {
      for (final item in o.items) {
        final key = '${item.name} T.${item.size}';
        data.putIfAbsent(key, () => []);
        data[key]!.add(_SaleItem(name: item.name, size: item.size, qty: item.quantity));
      }
    }
    final sorted = data.entries.toList()..sort((a, b) {
      final sumA = a.value.fold(0, (s, i) => s + i.qty);
      final sumB = b.value.fold(0, (s, i) => s + i.qty);
      return sumB.compareTo(sumA);
    });
    return Map.fromEntries(sorted);
  }

  /// Top ventas: version abreviada para la grafica (primeras 6)
  Map<String, int> _topSales(Map<String, List<_SaleItem>> detail) {
    final sorted = detail.entries.take(6);
    return Map.fromEntries(sorted.map((e) {
      final total = e.value.fold(0, (s, i) => s + i.qty);
      final parts = e.key.split(' T.');
      final short = _abbrev(parts.first);
      return MapEntry('$short T.${parts.last}', total);
    }));
  }

  /// Ingresos por día separados en digital vs efectivo
  Map<String, _DayRevenue> _revenueByDay(List<Order> orders) {
    final Map<String, _DayRevenue> data = {};
    for (final o in orders) {
      final key = '${o.createdAt.day}/${o.createdAt.month}';
      data[key] ??= _DayRevenue();
      if (o.paymentMethod == PaymentMethod.cash) {
        data[key]!.cash += o.total;
      } else {
        data[key]!.digital += o.total;
      }
    }
    return data;
  }

  void _showTopSalesDetail(Map<String, List<_SaleItem>> detail) {
    final sorted = detail.entries.toList()..sort((a, b) {
      final sumA = a.value.fold(0, (s, i) => s + i.qty);
      final sumB = b.value.fold(0, (s, i) => s + i.qty);
      return sumB.compareTo(sumA);
    });
    Navigator.of(context).push(_detailRoute(
      'Top Ventas Detallado',
      Icons.bar_chart,
      sorted.isEmpty
          ? Center(child: Text('Sin ventas en este período',
              style: GoogleFonts.nunito(color: AppColors.textSecondary)))
          : Column(children: sorted.map((e) {
              final total = e.value.fold(0, (s, i) => s + i.qty);
              return _DetailRow(
                rank: sorted.indexOf(e) + 1,
                label: e.key,
                value: '$total uds.',
                color: AppColors.primary,
              );
            }).toList()),
    ));
  }

  void _showRevenueDetail(Map<String, _DayRevenue> revenue, List<Order> orders) {
    final totalRev = orders.fold(0.0, (s, o) => s + o.total);
    final digitalRev = orders
        .where((o) => o.paymentMethod != PaymentMethod.cash)
        .fold(0.0, (s, o) => s + o.total);
    final cashRev = totalRev - digitalRev;

    Navigator.of(context).push(_detailRoute(
      'Flujo de Ingresos Detallado',
      Icons.show_chart,
      ListView(children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            Expanded(child: _MiniKpi(label: 'Total', value: '\$${totalRev.toStringAsFixed(0)}', color: AppColors.primary)),
            const SizedBox(width: 8),
            Expanded(child: _MiniKpi(label: 'Digital', value: '\$${digitalRev.toStringAsFixed(0)}', color: AppColors.alertInfo)),
            const SizedBox(width: 8),
            Expanded(child: _MiniKpi(label: 'Efectivo', value: '\$${cashRev.toStringAsFixed(0)}', color: AppColors.secondary)),
          ]),
        ),
        ...revenue.entries.map((e) {
          final d = e.value;
          return _DetailRow(
            rank: 0,
            label: e.key,
            value: 'Dig: \$${d.digital.toStringAsFixed(0)} / Efe: \$${d.cash.toStringAsFixed(0)}',
            color: AppColors.primary,
          );
        }),
      ]),
    ));
  }

  Route<void> _detailRoute(String title, IconData icon, Widget body) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(title)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: body,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all        = context.watch<OrderProvider>().orders;
    final orders     = _filtered(all);
    final detail     = _topSalesDetail(orders);
    final topSales   = _topSales(detail);
    final revenue    = _revenueByDay(orders);

    final totalRev   = orders.fold(0.0, (s, o) => s + o.total);
    final digitalRev = orders
        .where((o) => o.paymentMethod != PaymentMethod.cash)
        .fold(0.0, (s, o) => s + o.total);
    final cashRev    = totalRev - digitalRev;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Analíticas BI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 20),

          Row(children: [
            _MiniKpi(label: 'Ingresos',  value: '\$${totalRev.toStringAsFixed(0)}',   color: AppColors.primary),
            const SizedBox(width: 10),
            _MiniKpi(label: 'Pedidos',   value: '${orders.length}',                   color: AppColors.secondary),
            const SizedBox(width: 10),
            _MiniKpi(label: 'Digital',   value: '\$${digitalRev.toStringAsFixed(0)}', color: AppColors.alertInfo),
          ]),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: detail.isEmpty ? null : () => _showTopSalesDetail(detail),
            child: _ChartCard(
              title: 'Top Ventas por Prenda y Talla',
              subtitle: 'Toca para ver detalle completo',
              icon: Icons.bar_chart,
              child: topSales.isEmpty
                  ? _empty('Sin ventas en este período')
                  : SizedBox(height: 220, child: _buildBarChart(topSales)),
            ),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: revenue.isEmpty ? null : () => _showRevenueDetail(revenue, orders),
            child: _ChartCard(
              title: 'Flujo de Ingresos',
              subtitle: 'Toca para ver detalle completo · ${_period.label}',
              icon: Icons.show_chart,
              child: revenue.isEmpty
                  ? _empty('Sin transacciones en este período')
                  : SizedBox(height: 220, child: _buildLineChart(revenue)),
            ),
          ),
          const SizedBox(height: 20),

          _ChartCard(
            title: 'Desglose por Método de Pago',
            subtitle: 'Distribución de ingresos',
            icon: Icons.pie_chart_outline,
            child: SizedBox(height: 180, child: _buildPaymentBreakdown(digitalRev, cashRev, totalRev)),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: _Period.values.map((p) {
        final sel = p == _period;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _period = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? AppColors.primary : AppColors.border),
              ),
              child: Center(
                child: Text(p.label,
                  style: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    final keys   = data.keys.toList();
    final values = data.values.toList();
    final maxY = math.max(5, (values.reduce(math.max) * 1.3).ceil()).toDouble();

    return BarChart(BarChartData(
      maxY: maxY,
      gridData: FlGridData(
        show: true, drawVerticalLine: false,
        horizontalInterval: (maxY / 4).ceilToDouble(),
        getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 28,
          getTitlesWidget: (v, _) => Text('${v.toInt()}',
            style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textSecondary)),
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 38,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= keys.length) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(keys[i],
                style: GoogleFonts.nunito(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center, maxLines: 2),
            );
          },
        )),
      ),
      barGroups: List.generate(keys.length, (i) => BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(
          toY: values[i].toDouble(),
          color: i == 0 ? AppColors.primary : AppColors.primaryLight,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true, toY: maxY, color: AppColors.surfaceVariant),
        )],
      )),
    ));
  }

  Widget _buildLineChart(Map<String, _DayRevenue> data) {
    final days    = data.keys.toList();
    final digital = data.values.map((d) => d.digital).toList();
    final cash    = data.values.map((d) => d.cash).toList();
    final allVals = [...digital, ...cash];
    final maxY    = math.max(500.0, allVals.reduce(math.max) * 1.3);

    FlSpot spotAt(int i, List<double> vals) => FlSpot(i.toDouble(), vals[i]);

    return LineChart(LineChartData(
      maxY: maxY, minY: 0,
      gridData: FlGridData(
        show: true, drawVerticalLine: false,
        horizontalInterval: _niceInterval(maxY),
        getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 36,
          getTitlesWidget: (v, _) => Text(_formatCompact(v),
            style: GoogleFonts.nunito(fontSize: 9, color: AppColors.textSecondary)),
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 24,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= days.length) return const SizedBox.shrink();
            return Text(days[i],
              style: GoogleFonts.nunito(fontSize: 9, color: AppColors.textSecondary));
          },
        )),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(digital.length, (i) => spotAt(i, digital)),
          isCurved: true, color: AppColors.primary, barWidth: 3,
          belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.08)),
          dotData: const FlDotData(show: true),
        ),
        LineChartBarData(
          spots: List.generate(cash.length, (i) => spotAt(i, cash)),
          isCurved: true, color: AppColors.secondary, barWidth: 3,
          belowBarData: BarAreaData(show: true, color: AppColors.secondary.withValues(alpha: 0.08)),
          dotData: const FlDotData(show: true),
        ),
      ],
    ));
  }

  double _niceInterval(double maxY) {
    if (maxY <= 500) return 100;
    if (maxY <= 2000) return 500;
    if (maxY <= 5000) return 1000;
    if (maxY <= 10000) return 2000;
    return (maxY / 5).roundToDouble();
  }

  Widget _buildPaymentBreakdown(double digital, double cash, double total) {
    if (total == 0) return _empty('Sin ingresos en este período');
    final dPct = (digital / total * 100).round();
    final cPct = 100 - dPct;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _PaymentBar(label: 'Digital / Tarjeta', amount: digital, pct: dPct, color: AppColors.primary),
      const SizedBox(height: 20),
      _PaymentBar(label: 'Efectivo / OXXO',   amount: cash,    pct: cPct, color: AppColors.secondary),
    ]);
  }

  Widget _empty(String msg) => SizedBox(
    height: 120,
    child: Center(child: Text(msg, style: GoogleFonts.nunito(color: AppColors.textSecondary))),
  );
}

/// ── Nuevos widgets auxiliares ────────────────────────────────────────────────

class _SaleItem {
  final String name;
  final String size;
  final int qty;
  const _SaleItem({required this.name, required this.size, required this.qty});
}

class _DetailRow extends StatelessWidget {
  final int rank;
  final String label, value;
  final Color color;
  const _DetailRow({required this.rank, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        if (rank > 0)
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(child: Text('$rank',
                style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
        if (rank > 0) const SizedBox(width: 10),
        Expanded(child: Text(label,
            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        Text(value,
            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Widget child;
  const _ChartCard({required this.title, required this.subtitle, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(subtitle, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
          ])),
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniKpi({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(value, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _PaymentBar extends StatelessWidget {
  final String label;
  final double amount;
  final int pct;
  final Color color;
  const _PaymentBar({required this.label, required this.amount, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ]),
        Text('\$${amount.toStringAsFixed(2)} ($pct%)',
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: pct / 100,
          backgroundColor: color.withValues(alpha: 0.12),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 10,
        ),
      ),
    ]);
  }
}

class _DayRevenue {
  double digital = 0;
  double cash    = 0;
}
