import 'package:ads_frontend/models/simulation_models.dart';
import 'package:flutter/material.dart';

import '../../services/simulation_api_service.dart';

class AdAnalyticsScreen extends StatefulWidget {
  final int adId;
  final String adTitle;

  const AdAnalyticsScreen({
    super.key,
    required this.adId,
    required this.adTitle,
  });

  @override
  State<AdAnalyticsScreen> createState() => _AdAnalyticsScreenState();
}

class _AdAnalyticsScreenState extends State<AdAnalyticsScreen> {
  AdAnalyticsResponse? _analytics;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
      await SimulationApiService.getAdAnalytics(widget.adId);
      setState(() {
        _analytics = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(color: Color(0xff00c4aa)),
      )
          : _error != null
          ? _buildError()
          : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 52),
            const SizedBox(height: 14),
            const Text(
              'Failed to load analytics',
              style:
              TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadAnalytics,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff00c4aa),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final a = _analytics!;
    final consumedPct = a.allocatedMinutes > 0
        ? (a.consumedMinutes / a.allocatedMinutes).clamp(0.0, 1.0)
        : 0.0;

    return CustomScrollView(
      slivers: [
        // ── APP BAR ──────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 130,
          pinned: true,
          backgroundColor: const Color(0xff00c4aa),
          foregroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding:
            const EdgeInsets.only(left: 56, bottom: 14),
            title: Text(
              a.adTitle.isNotEmpty ? a.adTitle : 'Ad #${a.adId}',
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            background: Container(color: const Color(0xff00c4aa)),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── SUMMARY CARDS ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xff00c4aa),
                        label: 'Allocated',
                        value:
                        '${_fmtMins(a.allocatedMinutes)} hrs',
                        sub: '${a.allocatedMinutes.toInt()} mins',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        icon: Icons.play_circle_outline,
                        iconColor: Colors.orange,
                        label: 'Consumed',
                        value:
                        '${_fmtMins(a.consumedMinutes)} hrs',
                        sub: '${a.consumedMinutes.toStringAsFixed(1)} mins',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        icon: Icons.hourglass_bottom_outlined,
                        iconColor: Colors.blue,
                        label: 'Remaining',
                        value:
                        '${_fmtMins(a.remainingMinutes)} hrs',
                        sub: '${a.remainingMinutes.toStringAsFixed(1)} mins',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        icon: Icons.route_outlined,
                        iconColor: Colors.purple,
                        label: 'Total Distance',
                        value:
                        '${a.totalValidKm.toStringAsFixed(2)} km',
                        sub: 'valid coverage',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── PROGRESS BAR ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Time Usage',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          Text(
                            '${(consumedPct * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Color(0xff00c4aa),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: consumedPct,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xff00c4aa)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${a.consumedMinutes.toStringAsFixed(1)} mins used',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            '${a.allocatedMinutes.toInt()} mins total',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── DAILY TRIPS HEADER ────────────────────────────────────
                Row(
                  children: [
                    const Text(
                      'Daily Trip Log',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xff00c4aa).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${a.dailyTrips.length} trips',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff00c4aa),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── DAILY TRIP CARDS ──────────────────────────────────────
                if (a.dailyTrips.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No trip data available yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...a.dailyTrips
                      .map((t) => _tripCard(t))
                      .toList(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _tripCard(DailyTripSummary t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip ID + Date row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Trip #${t.tripId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Vehicle reg badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xff00c4aa).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t.vehicleReg,
                      style: const TextStyle(
                        color: Color(0xff00c4aa),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                _fmtDate(t.tripDate),
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xffeeeeee)),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _tripStat(
                  icon: Icons.access_time,
                  iconColor: Colors.orange,
                  value:
                  '${t.validTimeMinutes.toStringAsFixed(1)} min',
                  label: 'Valid Time',
                ),
              ),
              Expanded(
                child: _tripStat(
                  icon: Icons.route,
                  iconColor: Colors.blue,
                  value:
                  '${t.validDistanceKm.toStringAsFixed(2)} km',
                  label: 'Distance',
                ),
              ),
              Expanded(
                child: _tripStat(
                  icon: Icons.grid_on,
                  iconColor: Colors.purple,
                  value: '${t.segmentsCount}',
                  label: 'Segments',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tripStat({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  // Convert minutes → "X.X" hrs string
  String _fmtMins(double mins) =>
      (mins / 60).toStringAsFixed(1);

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}