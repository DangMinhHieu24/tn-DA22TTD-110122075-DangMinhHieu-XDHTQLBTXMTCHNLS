import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/entities/revenue_report.dart';
import '../../../domain/usecases/get_revenue_report.dart';
import '../bloc/revenue_report_bloc.dart';
import '../bloc/revenue_report_event.dart';
import '../bloc/revenue_report_state.dart';

enum _ReportRange {
  sevenDays,
  thirtyDays,
  thisMonth,
  custom,
}

enum _ReportTab {
  services,
  daily,
  technicians,
}

enum _ServiceRange {
  today,
  week,
  month,
}

class AdminRevenueReportPage extends StatefulWidget {
  const AdminRevenueReportPage({super.key});

  @override
  State<AdminRevenueReportPage> createState() => _AdminRevenueReportPageState();
}

class _AdminRevenueReportPageState extends State<AdminRevenueReportPage> {
  _ReportRange _selectedRange = _ReportRange.sevenDays;
  _ReportTab _selectedTab = _ReportTab.services;
  _ServiceRange _serviceRange = _ServiceRange.week;
  DateTimeRange? _customRange;
  RevenueReport? _latestReport;
  bool _initialLoadFired = false;
  // Map technician id -> completed orders for current month
  Map<String, int> _monthlyTechnicianCompleted = {};
  bool _isMonthlyLoading = true;
  int _selectedServiceIndex = -1;
  int _selectedBarIndex = -1;
  /// Điểm đang chọn trên biểu đồ đường (tháng / khoảng dài).
  int? _lineChartTouchIndex;
  bool _isServiceRangeLoading = false;
  final Map<_ServiceRange, List<ServiceBreakdown>> _serviceRangeCache = {};

  static const int _maxServices = 6;

  DateTimeRange _resolveRange() {
    final now = DateTime.now();
    switch (_selectedRange) {
      case _ReportRange.sevenDays:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 6),
          end: DateTime(now.year, now.month, now.day),
        );
      case _ReportRange.thirtyDays:
        // Use previous calendar month (month before the current date)
        final prevMonthStart = DateTime(now.year, now.month - 1, 1);
        final prevMonthEnd = DateTime(now.year, now.month, 0);
        return DateTimeRange(start: prevMonthStart, end: prevMonthEnd);
      case _ReportRange.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day),
        );
      case _ReportRange.custom:
        return _customRange ?? DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 6),
          end: DateTime(now.year, now.month, now.day),
        );
    }
  }

  DateTimeRange _resolveServiceRange(_ServiceRange range) {
    final now = DateTime.now();
    switch (range) {
      case _ServiceRange.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day),
        );
      case _ServiceRange.week:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 6),
          end: DateTime(now.year, now.month, now.day),
        );
      case _ServiceRange.month:
        // Use last 30 days for "Tháng" to show a meaningful recent window
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 29),
          end: DateTime(now.year, now.month, now.day),
        );
    }
  }

  void _loadReport() {
    final range = _resolveRange();
    context.read<RevenueReportBloc>().add(
      LoadRevenueReport(start: range.start, end: range.end),
    );
  }

  Future<void> _performInitialLoad() async {
    // Ensure we fetch the monthly technician summary first so the UI can
    // display accurate "hoàn thành tháng" counts on first render.
    await _loadMonthlyTechnicianSummary();
    if (!mounted) return;
    _loadReport();
    unawaited(_loadServiceRange(_serviceRange));
  }

  Future<void> _loadServiceRange(_ServiceRange range) async {
    if (_serviceRangeCache.containsKey(range)) {
      setState(() {
        _serviceRange = range;
        _selectedServiceIndex = -1;
        _isServiceRangeLoading = false;
      });
      return;
    }

    setState(() {
      _serviceRange = range;
      _selectedServiceIndex = -1;
      _isServiceRangeLoading = true;
    });

    try {
      final getReport = GetIt.instance<GetRevenueReport>();
      final serviceRange = _resolveServiceRange(range);
      final result = await getReport(start: serviceRange.start, end: serviceRange.end);
      result.fold((failure) {
        // ignore: avoid_print
        print('GetServiceRange failed: $failure');
        if (mounted) {
          setState(() {
            _isServiceRangeLoading = false;
          });
        }
      }, (report) {
        _serviceRangeCache[range] = report.topServices;
        // debug log the top services retrieved
        // ignore: avoid_print
        print('ServiceRange ${range.toString()} fetched: ${report.topServices.map((s) => '${s.name}:${s.revenue}').toList()}');
        if (mounted) {
          setState(() {
            _isServiceRangeLoading = false;
          });
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isServiceRangeLoading = false;
        });
      }
    }
  }

  Future<void> _loadMonthlyTechnicianSummary() async {
    try {
      setState(() => _isMonthlyLoading = true);
      // Determine which calendar month to request. Use the month that contains
      // the currently selected report range start so the "hoàn thành tháng"
      // reflects the same month the admin is viewing (avoids showing current
      // month's zeroes when viewing historical ranges like May).
      final range = _resolveRange();
      final monthStart = DateTime(range.start.year, range.start.month, 1);
      final monthEnd = DateTime(range.start.year, range.start.month + 1, 0);
      final getReport = GetIt.instance<GetRevenueReport>();
      final result = await getReport(start: monthStart, end: monthEnd);
      result.fold((failure) {
        // Log failure for debugging
        // ignore: avoid_print
        print('GetMonthlyTechnicianSummary failed: $failure');
        if (mounted) setState(() => _isMonthlyLoading = false);
      }, (report) {
        final map = <String, int>{};
        for (final tech in report.technicians) {
          map[tech.id] = tech.orders;
        }
        // Log the range and map so we can verify what the backend returned
        // ignore: avoid_print
        print('Monthly technician summary for ${monthStart.toIso8601String()} - ${monthEnd.toIso8601String()}: $map');
        if (mounted) setState(() {
          _monthlyTechnicianCompleted = map;
          _isMonthlyLoading = false;
        });
      });
    } catch (_) {
      if (mounted) setState(() => _isMonthlyLoading = false);
    }
  }

  Future<void> _selectRange(_ReportRange range) async {
    if (range == _ReportRange.custom) {
      final picked = await _showCustomRangePicker();
      if (picked == null) return;
      setState(() {
        _selectedRange = range;
        _customRange = picked;
        _lineChartTouchIndex = null;
      });
    } else {
      setState(() {
        _selectedRange = range;
        _lineChartTouchIndex = null;
      });
    }
    _loadReport();
  }

  void _selectTab(_ReportTab tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  Future<DateTimeRange?> _showCustomRangePicker() {
    final now = DateTime.now();
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: now,
      initialDateRange: _customRange ?? DateTimeRange(
        start: DateTime(now.year, now.month, now.day - 6),
        end: DateTime(now.year, now.month, now.day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = _maybeBloc(context);
    if (existing == null) {
      return BlocProvider(
        create: (_) => GetIt.instance<RevenueReportBloc>(),
        child: Builder(
          builder: (context) => _buildScaffold(context),
        ),
      );
    }

    return _buildScaffold(context);
  }

  RevenueReportBloc? _maybeBloc(BuildContext context) {
    try {
      return BlocProvider.of<RevenueReportBloc>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  Widget _buildScaffold(BuildContext context) {
    final range = _resolveRange();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF006E2F),
                onRefresh: () => _handleRefresh(context),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: BlocBuilder<RevenueReportBloc, RevenueReportState>(
                    builder: (context, state) {
                      if (state is RevenueReportInitial && !_initialLoadFired) {
                        _initialLoadFired = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _performInitialLoad();
                        });
                      }
                      final report = state is RevenueReportLoaded
                          ? state.report
                          : _emptyReport(range.start, range.end);
                      if (state is RevenueReportLoaded) {
                        _latestReport = state.report;
                      }
                      final isLoading = state is RevenueReportLoading || state is RevenueReportInitial;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLoading) const LinearProgressIndicator(minHeight: 2),
                          if (isLoading) const SizedBox(height: 10),
                          const SizedBox(height: 16),
                          _buildSummaryCards(report),
                          const SizedBox(height: 16),
                          _buildFilterChips(),
                          const SizedBox(height: 16),
                          _buildRevenueChartCard(context, report),
                          const SizedBox(height: 16),
                          _buildSegmentedTabs(),
                          const SizedBox(height: 16),
                          _buildTabBody(report),
                          const SizedBox(height: 24),
                          _buildExportButton(context, report),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF006E2F)),
          ),
          const Expanded(
            child: Text(
              'Báo cáo doanh thu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF006E2F),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              final report = _latestReport;
              if (report == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chưa có dữ liệu để xuất.')),
                );
                return;
              }
              _copyReportCsv(context, report);
            },
            icon: const Icon(Icons.file_download_outlined, color: Color(0xFF006E2F)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final customLabel = _customRange == null
        ? 'Tùy chỉnh'
        : 'Tùy chỉnh ${_formatRangeLabel(_customRange!.start, _customRange!.end)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _chip(
              '7 ngày',
              selected: _selectedRange == _ReportRange.sevenDays,
              onTap: () => _selectRange(_ReportRange.sevenDays),
            ),
            const SizedBox(width: 10),
            _chip(
              'Tháng trước',
              selected: _selectedRange == _ReportRange.thirtyDays,
              onTap: () => _selectRange(_ReportRange.thirtyDays),
            ),
            const SizedBox(width: 10),
            _chip(
              'Tháng này',
              selected: _selectedRange == _ReportRange.thisMonth,
              onTap: () => _selectRange(_ReportRange.thisMonth),
            ),
            const SizedBox(width: 10),
            _chip(
              customLabel,
              selected: _selectedRange == _ReportRange.custom,
              icon: Icons.calendar_month,
              onTap: () => _selectRange(_ReportRange.custom),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    String label, {
    bool selected = false,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    final bg = selected ? const Color(0xFF006E2F) : const Color(0xFFFFFFFF);
    final fg = selected ? Colors.white : const Color(0xFF3D4A3D);
    final border = selected ? Colors.transparent : const Color(0xFFEEF1F3);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 1),
          boxShadow: [
            if (!selected)
              BoxShadow(
                color: const Color(0xFF191C1E).withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 16, color: fg),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChartCard(BuildContext context, RevenueReport report) {
    final rawPoints = report.dailyRevenue;
    final points = _aggregatePointsForRange(rawPoints);
    final values = points.isNotEmpty
        ? points.map((e) => e.revenue).toList()
        : <double>[0, 0, 0, 0, 0, 0, 0];
    final labels = points.isNotEmpty
        ? _buildChartLabels(points)
        : const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final maxValue = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final maxIndex = values.isEmpty ? -1 : values.indexOf(maxValue);
    final total = report.totalRevenue;
    final growth = report.growthPercent;
    final useMonthlySpline =
        points.length > 7 &&
        (_selectedRange == _ReportRange.thirtyDays || _selectedRange == _ReportRange.thisMonth);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F3F2), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006E2F).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(builder: (context) {
            final headerTitle = _selectedRange == _ReportRange.thirtyDays
              ? 'Doanh thu tháng trước'
                : _rangeTitle(report);
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(headerTitle, style: const TextStyle(fontSize: 16, color: Color(0xFF3D4A3D))),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_formatMillions(total), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF191C1E))),
                          const SizedBox(width: 6),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text('VND', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: growth >= 0 ? const Color(0xFFE9FBEE) : const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(growth >= 0 ? Icons.trending_up : Icons.trending_down, size: 14, color: growth >= 0 ? const Color(0xFF006E2F) : const Color(0xFFB42318)),
                      const SizedBox(width: 6),
                      Text(_formatPercent(growth), style: TextStyle(color: growth >= 0 ? const Color(0xFF006E2F) : const Color(0xFFB42318), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          // If there is no revenue data (all zeros), show an empty state.
          if (values.every((v) => v <= 0))
            SizedBox(
              height: 230,
              child: Center(
                child: _buildEmptyState('Chưa có dữ liệu doanh thu trong giai đoạn này.'),
              ),
            )
          else
            rawPoints.length <= 7
                ? SizedBox(
                    height: 230,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _DashedTrendPainter(),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          // Render bars for every value entry; labels may be a reduced set
                          // used only for the axis ticks below.
                          children: List.generate(values.length, (index) {
                              final value = values[index];
                              final height = maxValue <= 0 ? 0.0 : (value / maxValue);
                              final isMax = index == maxIndex && value > 0;
                              final isSelected = index == _selectedBarIndex;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedBarIndex = isSelected ? -1 : index),
                                  child: SizedBox(
                                    height: 200,
                                    child: Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        // tooltip only when selected
                                        if (isSelected)
                                          Positioned(
                                            top: 0,
                                            child: _buildTooltip(value, points[index].orders),
                                          ),
                                        // diamond marker when selected
                                        if (isSelected)
                                          Positioned(
                                            top: 44,
                                            child: Transform.rotate(
                                              angle: 0.785398, // 45deg
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                color: const Color(0xFF2D3133),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          bottom: 22,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 280),
                                            curve: Curves.easeOutCubic,
                                            height: 120 * height,
                                            width: isSelected ? 44 : 36,
                                            decoration: BoxDecoration(
                                              gradient: isSelected
                                                  ? const LinearGradient(
                                                      begin: Alignment.bottomCenter,
                                                      end: Alignment.topCenter,
                                                      colors: [
                                                        Color(0x33006E2F),
                                                        Color(0xFF006E2F),
                                                      ],
                                                    )
                                                  : const LinearGradient(
                                                      begin: Alignment.bottomCenter,
                                                      end: Alignment.topCenter,
                                                      colors: [
                                                        Color(0xFFEEF1F3),
                                                        Color(0xFFEEF1F3),
                                                      ],
                                                    ),
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                              boxShadow: [
                                                if (isSelected)
                                                  BoxShadow(
                                                    color: const Color(0xFF006E2F).withValues(alpha: 0.22),
                                                    blurRadius: 18,
                                                    offset: const Offset(0, 8),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ),
                      ],
                    ),
                  )
                : useMonthlySpline
                    ? _buildMonthlySplineChart(points)
                    : _buildDenseDailyLineChart(points, labels, maxValue),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Doanh thu tích lũy theo ngày — khớp phác thảo (đường cong lên, tổng = header).
  List<_ChartPoint> _toCumulativePoints(List<_ChartPoint> dailyPoints) {
    var running = 0.0;
    return dailyPoints
        .map(
          (point) {
            running += point.revenue;
            return _ChartPoint(
              startDate: point.startDate,
              endDate: point.endDate,
              revenue: running,
              orders: point.orders,
            );
          },
        )
        .toList();
  }

  List<int> _monthMarkerIndices(int pointCount) {
    if (pointCount <= 0) return const [];
    if (pointCount == 1) return const [0];
    final last = pointCount - 1;
    return {0, 9.clamp(0, last), 19.clamp(0, last), last}.toList()..sort();
  }

  void _onLineChartTap(double localX, double chartWidth, int pointCount) {
    if (pointCount <= 0) return;
    final index = pointCount <= 1
        ? 0
        : ((localX / chartWidth).clamp(0.0, 1.0) * (pointCount - 1)).round().clamp(0, pointCount - 1);
    setState(() {
      _lineChartTouchIndex = _lineChartTouchIndex == index ? null : index;
    });
  }

  LineChartData _buildSplineLineChartData({
    required List<_ChartPoint> chartPoints,
    required List<int> markerIndices,
    required int? selectedIndex,
    required double maxValue,
  }) {
    return LineChartData(
      minX: 0,
      maxX: (chartPoints.length - 1).toDouble(),
      minY: 0,
      maxY: maxValue <= 0 ? 1 : maxValue * 1.06,
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(
        verticalLines: selectedIndex == null
            ? []
            : [
                VerticalLine(
                  x: selectedIndex.toDouble(),
                  color: const Color(0xFF006E2F).withValues(alpha: 0.25),
                  strokeWidth: 1.5,
                  dashArray: [5, 5],
                ),
              ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: chartPoints
              .asMap()
              .entries
              .map((entry) => FlSpot(entry.key.toDouble(), entry.value.revenue))
              .toList(),
          isCurved: true,
          curveSmoothness: 0.42,
          preventCurveOverShooting: true,
          color: const Color(0xFF006E2F),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final isSelected = index == selectedIndex;
              if (isSelected) {
                return FlDotCirclePainter(
                  radius: 7,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: const Color(0xFF006E2F),
                );
              }
              if (!markerIndices.contains(index)) {
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                );
              }
              return FlDotCirclePainter(
                radius: 5,
                color: Colors.white,
                strokeWidth: 2.5,
                strokeColor: const Color(0xFF006E2F),
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF006E2F).withValues(alpha: 0.24),
                const Color(0xFF006E2F).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: const LineTouchData(enabled: false),
    );
  }

  /// Chiều cao cố định: chart + nhãn trục X, tooltip nổi trên chart (không đẩy layout).
  Widget _buildInteractiveLineChartShell({
    required int pointCount,
    required Widget chart,
    required Widget axisLabels,
    Widget? touchOverlay,
  }) {
    return SizedBox(
      height: 228,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chartWidth = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => _onLineChartTap(
                    event.localPosition.dx,
                    chartWidth,
                    pointCount,
                  ),
                  child: IgnorePointer(child: chart),
                ),
              ),
              if (touchOverlay != null)
                Positioned(
                  top: 6,
                  left: 0,
                  right: 0,
                  child: touchOverlay,
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: axisLabels,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthlySplineChart(List<_ChartPoint> dailyPoints) {
    final chartPoints = _toCumulativePoints(dailyPoints);
    final values = chartPoints.map((e) => e.revenue).toList();
    final maxValue = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final markerIndices = _monthMarkerIndices(chartPoints.length);
    final selectedIndex = _lineChartTouchIndex;

    return _buildInteractiveLineChartShell(
      pointCount: dailyPoints.length,
      chart: LineChart(
        _buildSplineLineChartData(
          chartPoints: chartPoints,
          markerIndices: markerIndices,
          selectedIndex: selectedIndex,
          maxValue: maxValue,
        ),
      ),
      axisLabels: _buildMonthAxisLabelRow(dailyPoints),
      touchOverlay: selectedIndex != null && selectedIndex < dailyPoints.length
          ? _buildLineChartTouchDetailCard(
              dailyPoints: dailyPoints,
              chartPoints: chartPoints,
              index: selectedIndex,
              cumulative: true,
            )
          : null,
    );
  }

  Widget _buildLineChartTouchDetailCard({
    required List<_ChartPoint> dailyPoints,
    required List<_ChartPoint> chartPoints,
    required int index,
    required bool cumulative,
  }) {
    final daily = dailyPoints[index];
    final chartValue = chartPoints[index];
    final dayLabel = DateFormat('dd/MM/yyyy').format(daily.startDate);

    return Material(
      elevation: 6,
      shadowColor: const Color(0xFF191C1E).withValues(alpha: 0.2),
      color: const Color(0xFF2D3133),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _lineChartTouchIndex = null),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFB0B8B4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (cumulative)
                      Text(
                        'Tích lũy: ${_formatMillions(chartValue.revenue)} VND',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    Text(
                      cumulative
                          ? 'Trong ngày: +${_formatMillions(daily.revenue)} · ${daily.orders} đơn'
                          : '${_formatMillions(daily.revenue)} VND · ${daily.orders} đơn',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFE8EDEA),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.close, size: 16, color: Color(0xFFB0B8B4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDenseDailyLineChart(
    List<_ChartPoint> points,
    List<String> labels,
    double maxValue,
  ) {
    final markerIndices = _denseKeyPointIndices(points.length);
    final selectedIndex = _lineChartTouchIndex;

    return _buildInteractiveLineChartShell(
      pointCount: points.length,
      chart: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: maxValue <= 0 ? 1 : maxValue * 1.18,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            verticalLines: selectedIndex == null
                ? []
                : [
                    VerticalLine(
                      x: selectedIndex.toDouble(),
                      color: const Color(0xFF006E2F).withValues(alpha: 0.25),
                      strokeWidth: 1.5,
                      dashArray: [5, 5],
                    ),
                  ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: points
                  .asMap()
                  .entries
                  .map((entry) => FlSpot(entry.key.toDouble(), entry.value.revenue))
                  .toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              color: const Color(0xFF006E2F),
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final isSelected = index == selectedIndex;
                  if (isSelected) {
                    return FlDotCirclePainter(
                      radius: 7,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: const Color(0xFF006E2F),
                    );
                  }
                  if (!markerIndices.contains(index)) {
                    return FlDotCirclePainter(
                      radius: 0,
                      color: Colors.transparent,
                      strokeWidth: 0,
                      strokeColor: Colors.transparent,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 4.5,
                    color: Colors.white,
                    strokeWidth: 2.5,
                    strokeColor: const Color(0xFF006E2F),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF006E2F).withValues(alpha: 0.16),
                    const Color(0xFF006E2F).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
      axisLabels: _buildAxisLabelRow(points, labels),
      touchOverlay: selectedIndex != null && selectedIndex < points.length
          ? _buildLineChartTouchDetailCard(
              dailyPoints: points,
              chartPoints: points,
              index: selectedIndex,
              cumulative: false,
            )
          : null,
    );
  }

  Widget _buildTooltip(double value, int orders) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3133),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '${_formatMillions(value)} VND',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 1),
                Text(
                  '(${orders} đơn)',
                  style: const TextStyle(color: Color(0xFFEFF1F3), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF2D3133),
              shape: BoxShape.rectangle,
            ),
            transform: Matrix4.rotationZ(0.785398),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(RevenueReport report) {
    final last7Revenue = _sumLastDays(report.dailyRevenue, 7);
    final previous7Revenue = _sumPreviousDays(report.dailyRevenue, 7);
    final weekGrowth = _calculateGrowth(last7Revenue, previous7Revenue);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B7A3B),
            Color(0xFF2EC35E),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B7A3B).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng doanh thu ${_rangeMonthLabel(report)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _formatMillions(report.totalRevenue),
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(width: 12),
              _growthPill(report.growthPercent, isLight: true),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryMetric(
                  title: 'Doanh thu 7 ngày qua',
                  value: _formatMillions(last7Revenue),
                  valueColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _summaryMetric(
                  title: 'So với tuần trước',
                  value: _formatPercent(weekGrowth),
                  valueColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _growthPill(double growth, {bool isLight = false}) {
    final bg = isLight
        ? Colors.white.withValues(alpha: 0.2)
        : growth >= 0
            ? const Color(0xFF6BFF8F).withValues(alpha: 0.2)
            : const Color(0xFFFF8B7C).withValues(alpha: 0.2);
    final fg = isLight
        ? Colors.white
        : growth >= 0
            ? const Color(0xFF006E2F)
            : const Color(0xFFB42318);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(
            growth >= 0 ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            _formatPercent(growth),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85)),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildSegmentedTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6F2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE7E2), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006E2F).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _tab(
            'Dịch vụ',
            selected: _selectedTab == _ReportTab.services,
            onTap: () => _selectTab(_ReportTab.services),
          ),
          _tab(
            'Theo ngày',
            selected: _selectedTab == _ReportTab.daily,
            onTap: () => _selectTab(_ReportTab.daily),
          ),
          _tab(
            'Kỹ thuật viên',
            selected: _selectedTab == _ReportTab.technicians,
            onTap: () => _selectTab(_ReportTab.technicians),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, {bool selected = false, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF006E2F) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: const Color(0xFF006E2F).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF1F2A24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBody(RevenueReport report) {
    switch (_selectedTab) {
      case _ReportTab.services:
        return _buildPopularServices(report.topServices);
      case _ReportTab.daily:
        return _buildDailyBreakdown(report.dailyRevenue);
      case _ReportTab.technicians:
        return _buildTechnicianBreakdown(report.technicians);
    }
  }

  Widget _buildPopularServices(List<ServiceBreakdown> services) {
    final serviceData = _serviceRangeCache[_serviceRange] ?? services;
    if (serviceData.isEmpty && _isServiceRangeLoading) {
      return _buildServiceRangeLoading();
    }
    if (serviceData.isEmpty) return _buildServiceRangeEmpty();

    final visibleServices = serviceData.take(_maxServices).toList();
    final total = visibleServices.fold<double>(0.0, (s, e) => s + e.revenue);
    final sections = visibleServices.asMap().entries.map((entry) {
      final idx = entry.key;
      final svc = entry.value;
      return PieChartSectionData(
        color: _serviceColor(idx),
        value: svc.revenue <= 0 ? 0.0 : svc.revenue,
        radius: _selectedServiceIndex == idx ? 46 : 40,
        title: '',
      );
    }).toList();

    String _fmtShort(double v) {
      if (v <= 0) return '0đ';
      final formatter = NumberFormat('#,###', 'vi_VN');
      if (v >= 1000000) {
        final millionValue = v / 1000000;
        final text = millionValue % 1 == 0 ? millionValue.toStringAsFixed(0) : millionValue.toStringAsFixed(1);
        return '${text.replaceAll('.', ',')}tr';
      }
      return '${formatter.format(v).replaceAll(',', '.')}đ';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F4F2), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006E2F).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dịch vụ phổ biến',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF191C1E)),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _serviceRangeChip(_ServiceRange.today, 'Ngày'),
                  const SizedBox(width: 8),
                  _serviceRangeChip(_ServiceRange.week, 'Tuần'),
                  const SizedBox(width: 8),
                  _serviceRangeChip(_ServiceRange.month, 'Tháng'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 10),
          Center(
            child: SizedBox(
              width: 176,
              height: 176,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 44,
                      sectionsSpace: 3,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          if (pieTouchResponse == null || pieTouchResponse.touchedSection == null) return;
                          final touched = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          setState(() {
                            _selectedServiceIndex = touched == _selectedServiceIndex ? -1 : touched;
                          });
                        },
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Tổng cộng', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      const SizedBox(height: 4),
                      Text(_formatMillions(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF191C1E))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Column(
            children: visibleServices.asMap().entries.map((entry) {
              final idx = entry.key;
              final svc = entry.value;
              final color = _serviceColor(idx);
              final isSelected = _selectedServiceIndex == idx;
              return GestureDetector(
                onTap: () => setState(() => _selectedServiceIndex = isSelected ? -1 : idx),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          svc.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF191C1E)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 72,
                        child: Text(
                          _fmtShort(svc.revenue),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFF006E2F) : const Color(0xFF191C1E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRangeLoading() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Dịch vụ phổ biến', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF191C1E))),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _serviceRangeChip(_ServiceRange.today, 'Ngày'),
                  const SizedBox(width: 8),
                  _serviceRangeChip(_ServiceRange.week, 'Tuần'),
                  const SizedBox(width: 8),
                  _serviceRangeChip(_ServiceRange.month, 'Tháng'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: const Color(0xFFEFF3F1),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 160,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRangeEmpty() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F4F2), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006E2F).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dịch vụ phổ biến',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF191C1E)),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _serviceRangeChip(_ServiceRange.today, 'Ngày'),
                  const SizedBox(width: 8),
                  _serviceRangeChip(_ServiceRange.week, 'Tuần'),
                  const SizedBox(width: 8),
                  _serviceRangeChip(_ServiceRange.month, 'Tháng'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: const Color(0xFFEFF3F1),
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            alignment: Alignment.center,
            child: const Text(
              'Chưa có dữ liệu dịch vụ cho mốc thời gian này.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRangeDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE7E2), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_ServiceRange>(
          value: _serviceRange,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF1F2A24)),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2A24)),
          onChanged: (value) {
            if (value == null) return;
            _loadServiceRange(value);
          },
          items: const [
            DropdownMenuItem(value: _ServiceRange.today, child: Text('Hôm nay')),
            DropdownMenuItem(value: _ServiceRange.week, child: Text('Tuần')),
            DropdownMenuItem(value: _ServiceRange.month, child: Text('Tháng')),
          ],
        ),
      ),
    );
  }

  Widget _serviceRangeChip(_ServiceRange value, String label) {
    final selected = _serviceRange == value;
    final bg = selected ? const Color(0xFFF2F6F3) : const Color(0xFFFFFFFF);
    final fg = selected ? const Color(0xFF006E2F) : const Color(0xFF3D4A3D);
    final border = selected ? const Color(0xFF006E2F) : const Color(0xFFE6ECE8);
    return InkWell(
      onTap: () => _loadServiceRange(value),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ),
      ),
    );
  }

  Widget _buildDailyBreakdown(List<RevenuePoint> points) {
    if (points.isEmpty) {
      return _buildEmptyState('Chưa có dữ liệu doanh thu theo ngày.');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Theo ngày',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF191C1E)),
          ),
          const SizedBox(height: 12),
          // Show newest date first
          ...((([...points]..sort((a, b) => b.date.compareTo(a.date))).map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(point.date),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF3D4A3D)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatMillions(point.revenue),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${point.orders} đơn',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ],
                ),
              ))).toList()),
        ],
      ),
    );
  }

  Widget _buildTechnicianBreakdown(List<TechnicianBreakdown> technicians) {
    if (technicians.isEmpty) {
      return _buildEmptyState('Chưa có dữ liệu kỹ thuật viên trong giai đoạn này.');
    }

    final sortedTechnicians = [...technicians];
    sortedTechnicians.sort(
      (a, b) => b.activeOrders != a.activeOrders
          ? b.activeOrders - a.activeOrders
          : b.revenue.compareTo(a.revenue),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kỹ thuật viên',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF191C1E)),
          ),
          const SizedBox(height: 12),
          ...List.generate(sortedTechnicians.length * 2 - 1, (index) {
            if (index.isOdd) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Divider(
                  height: 12,
                  thickness: 0.8,
                  color: Color(0xFFE8ECEF),
                ),
              );
            }

            final tech = sortedTechnicians[index ~/ 2];
            // Prefer the monthly summary map if available (ensures correct counts from
            // the separate monthly report). If the monthly map hasn't arrived yet,
            // show a loading placeholder instead of falling back to the current
            // range's `tech.orders` which can be misleading.
            final bool monthlyAvailable = !_isMonthlyLoading;
            final int completedThisMonthValue = _monthlyTechnicianCompleted[tech.id] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                  collapsedIconColor: const Color(0xFF9AA5A0),
                  iconColor: const Color(0xFF006E2F),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFEFFAF1),
                    child: Text(
                      tech.name.isNotEmpty ? tech.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Color(0xFF006E2F), fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(
                    tech.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF191C1E)),
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatMillions(tech.revenue),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${tech.activeOrders} đang thực hiện',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF006E2F), fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _isMonthlyLoading
                            ? 'Đang tải...'
                            : '$completedThisMonthValue hoàn thành tháng',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Hoàn thành trong kỳ: ${tech.orders}', style: const TextStyle(color: Color(0xFF556B5E))),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006E2F)),
                          child: const Text('Xem chi tiết', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Gọi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF1F3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, RevenueReport report) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _copyReportCsv(context, report),
        icon: const Icon(Icons.description_outlined, size: 18),
        label: const Text('Xuất báo cáo PDF/CSV'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006E2F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 6,
        ),
      ),
    );
  }

  String _formatMillions(double value) {
    if (value <= 0) return '0.0M';
    final millions = value / 1000000;
    return '${millions.toStringAsFixed(1)}M';
  }

  double _sumLastDays(List<RevenuePoint> points, int days) {
    if (points.isEmpty || days <= 0) return 0;
    final startIndex = (points.length - days).clamp(0, points.length);
    var total = 0.0;
    for (var index = startIndex; index < points.length; index++) {
      total += points[index].revenue;
    }
    return total;
  }

  double _sumPreviousDays(List<RevenuePoint> points, int days) {
    if (points.isEmpty || days <= 0) return 0;
    final endIndex = (points.length - days).clamp(0, points.length);
    final startIndex = (endIndex - days).clamp(0, endIndex);
    if (startIndex >= endIndex) return 0;
    var total = 0.0;
    for (var index = startIndex; index < endIndex; index++) {
      total += points[index].revenue;
    }
    return total;
  }

  double _calculateGrowth(double current, double previous) {
    if (previous > 0) return ((current - previous) / previous) * 100;
    if (current > 0) return 100;
    return 0;
  }

  List<_ChartPoint> _aggregateRevenueByWeek(List<RevenuePoint> points) {
    if (points.length <= 7) {
      return points
          .map(
            (point) => _ChartPoint(
              startDate: point.date,
              endDate: point.date,
              revenue: point.revenue,
              orders: point.orders,
            ),
          )
          .toList();
    }

    final buckets = <_ChartPoint>[];
    for (var index = 0; index < points.length; index += 7) {
      final endIndex = (index + 7).clamp(0, points.length);
      final slice = points.sublist(index, endIndex);
      var revenue = 0.0;
      var orders = 0;
      for (final point in slice) {
        revenue += point.revenue;
        orders += point.orders;
      }
      buckets.add(
        _ChartPoint(
          startDate: slice.first.date,
          endDate: slice.last.date,
          revenue: revenue,
          orders: orders,
        ),
      );
    }
    return buckets;
  }

  String _formatPercent(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }

  String _rangeTitle(RevenueReport report) {
    final rangeLabel = _formatRangeLabel(report.rangeStart, report.rangeEnd);
    return 'Doanh thu\n$rangeLabel';
  }

  String _rangeMonthLabel(RevenueReport report) {
    final start = report.rangeStart;
    final end = report.rangeEnd;
    if (start.year == end.year && start.month == end.month) {
      return 'Tháng ${end.month}';
    }
    return _formatRangeLabel(start, end);
  }

  List<int> _denseLabelIndices(int length) {
    if (length <= 7) return List.generate(length, (index) => index);
    final indices = <int>{0, length - 1};
    if (length > 10) {
      indices.add((length / 3).round());
      indices.add((length * 2 / 3).round());
    } else {
      indices.add((length / 2).round());
    }
    return indices.toList()..sort();
  }

  int _denseTickInterval(int length) {
    if (length <= 7) return 1;
    if (length <= 14) return 3;
    return 7;
  }

  List<int> _denseKeyPointIndices(int length) {
    if (length <= 7) return List.generate(length, (index) => index);
    final indices = <int>{0, length - 1};
    if (length > 2) {
      indices.add((length / 2).round());
    }
    return indices.toList()..sort();
  }

  Widget _buildDenseRangeInsights(List<_ChartPoint> points, double maxValue) {
    final nonZeroDays = points.where((point) => point.revenue > 0).length;
    _ChartPoint? peakPoint;
    var revenueSum = 0.0;
    for (final point in points) {
      revenueSum += point.revenue;
      if (peakPoint == null || point.revenue > peakPoint.revenue) {
        peakPoint = point;
      }
    }
    final averageRevenue = points.isEmpty ? 0.0 : revenueSum / points.length;

    return Row(
      children: [
        Expanded(
          child: _denseInsightChip(
            icon: Icons.bolt_outlined,
            label: 'Ngày có doanh thu',
            value: '$nonZeroDays/${points.length}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _denseInsightChip(
            icon: Icons.emoji_events_outlined,
            label: 'Đỉnh doanh thu',
            value: peakPoint == null ? '0' : _formatMillions(peakPoint.revenue),
            subtitle: peakPoint == null ? '' : peakPoint.label,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _denseInsightChip(
            icon: Icons.auto_graph_outlined,
            label: 'Trung bình/ngày',
            value: _formatMillions(averageRevenue),
            subtitle: maxValue > 0 ? 'từ ${_formatMillions(maxValue)} max' : '',
          ),
        ),
      ],
    );
  }

  Widget _denseInsightChip({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0B0B0B).withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: const Color(0xFFF0FBF5), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: const Color(0xFF006E2F)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF191C1E)))),
              if (subtitle != null && subtitle.isNotEmpty)
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF8C9A94))),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRangeLabel(DateTime start, DateTime end) {
    final formatter = DateFormat('dd/MM');
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return formatter.format(start);
    }
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  String _formatPointLabel(_ChartPoint point) {
    if (point.startDate == point.endDate) {
      return _weekdayLabel(point.startDate);
    }
    return point.label;
  }

  List<String> _buildChartLabels(List<_ChartPoint> points) {
    if (points.isEmpty) return const [];

    if (points.length <= 7) {
      return points.map((e) => _weekdayLabel(e.startDate)).toList();
    }

    const targetTicks = 5;
    final step = (points.length - 1) / (targetTicks - 1);
    return List.generate(targetTicks, (i) {
      final index = (i * step).round().clamp(0, points.length - 1);
      return points[index].label;
    });
  }

  Widget _buildAxisLabelRow(List<_ChartPoint> points, List<String> labels) {
    if (points.isEmpty) return const SizedBox.shrink();

    final displayLabels = points.length <= 7
        ? labels
        : labels.take(5).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: displayLabels.map((label) {
        return Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        );
      }).toList(),
    );
  }

  Widget _buildMonthAxisLabelRow(List<_ChartPoint> points) {
    const labelStyle = TextStyle(fontSize: 11, color: Color(0xFF6B7280));
    final lastDay = points.isEmpty ? 30 : points.last.startDate.day;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Ngày 1', style: labelStyle),
        const Text('Ngày 10', style: labelStyle),
        const Text('Ngày 20', style: labelStyle),
        Text('Ngày $lastDay', style: labelStyle),
      ],
    );
  }

  String _weekdayLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  List<_ChartPoint> _aggregatePointsForRange(List<RevenuePoint> points) {
    if (points.length <= 7) {
      return points
          .map(
            (point) => _ChartPoint(
              startDate: point.date,
              endDate: point.date,
              revenue: point.revenue,
              orders: point.orders,
            ),
          )
          .toList();
    }
    if (_selectedRange == _ReportRange.thirtyDays) {
      return points
          .map(
            (point) => _ChartPoint(
              startDate: point.date,
              endDate: point.date,
              revenue: point.revenue,
              orders: point.orders,
            ),
          )
          .toList();
    }
    return _aggregateRevenueByWeek(points);
  }

  Color _serviceColor(int index) {
    const colors = [
      Color(0xFF006E2F),
      Color(0xFF0058BE),
      Color(0xFFFF8B7C),
      Color(0xFFBCCBB9),
      Color(0xFF7C3AED),
      Color(0xFF16A34A),
    ];
    return colors[index % colors.length];
  }

  RevenueReport _emptyReport(DateTime start, DateTime end) {
    final days = (end.difference(start).inDays).abs() + 1;
    final points = List.generate(days, (index) {
      final date = DateTime(start.year, start.month, start.day + index);
      return RevenuePoint(date: date, revenue: 0, orders: 0);
    });
    return RevenueReport(
      rangeStart: start,
      rangeEnd: end,
      totalRevenue: 0,
      previousTotalRevenue: 0,
      growthPercent: 0,
      totalOrders: 0,
      dailyRevenue: points,
      topServices: const [],
      technicians: const [],
    );
  }

  Future<void> _copyReportCsv(BuildContext context, RevenueReport report) async {
    final buffer = StringBuffer();
    buffer.writeln('range,${_formatRangeLabel(report.rangeStart, report.rangeEnd)}');
    buffer.writeln('total_revenue,${report.totalRevenue}');
    buffer.writeln('growth_percent,${report.growthPercent}');
    buffer.writeln('total_orders,${report.totalOrders}');
    buffer.writeln('');
    buffer.writeln('date,revenue,orders');
    for (final point in report.dailyRevenue) {
      buffer.writeln('${DateFormat('yyyy-MM-dd').format(point.date)},${point.revenue},${point.orders}');
    }
    buffer.writeln('');
    buffer.writeln('service,revenue,percent');
    for (final service in report.topServices) {
      buffer.writeln('${service.name},${service.revenue},${service.percent.toStringAsFixed(2)}');
    }
    buffer.writeln('');
    buffer.writeln('technician,revenue,orders');
    for (final tech in report.technicians) {
      buffer.writeln('${tech.name},${tech.revenue},${tech.orders}');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã copy báo cáo CSV vào clipboard.')),
    );
  }

  Future<void> _handleRefresh(BuildContext context) async {
    final bloc = context.read<RevenueReportBloc>();
    final range = _resolveRange();
    final completer = Completer<void>();
    final sub = bloc.stream.listen((state) {
      if (state is RevenueReportLoaded) {
        if (!completer.isCompleted) completer.complete();
      }
      if (state is RevenueReportError) {
        if (!completer.isCompleted) completer.complete();
      }
    });
    bloc.add(LoadRevenueReport(start: range.start, end: range.end));
    try {
      await completer.future.timeout(const Duration(seconds: 5));
    } catch (_) {
      // timeout - just return
    }
    await sub.cancel();
  }
}

class _ChartPoint {
  final DateTime startDate;
  final DateTime endDate;
  final double revenue;
  final int orders;

  const _ChartPoint({
    required this.startDate,
    required this.endDate,
    required this.revenue,
    required this.orders,
  });

  String get label {
    if (startDate.year == endDate.year && startDate.month == endDate.month && startDate.day == endDate.day) {
      return DateFormat('dd/MM').format(startDate);
    }
    return '${DateFormat('dd/MM').format(startDate)} - ${DateFormat('dd/MM').format(endDate)}';
  }
}

class _DashedTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBCCBB9).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.5, size.width * 0.45, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.4, size.width * 0.85, size.height * 0.2);

    const dashWidth = 6.0;
    const dashSpace = 6.0;
    double distance = 0.0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final segment = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
