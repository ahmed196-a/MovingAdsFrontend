import 'package:flutter/material.dart';
import '../../models/simulation_models.dart';
import '../../services/simulation_api_service.dart';

class DriverStatsScreen extends StatefulWidget {
  final int? userid;

  const DriverStatsScreen({super.key, required this.userid});

  @override
  State<DriverStatsScreen> createState() => _DriverStatsScreenState();
}

class _DriverStatsScreenState extends State<DriverStatsScreen> {
  List<DriverTripSummary> _trips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    if (widget.userid == null) {
      setState(() {
        _error = 'User ID not available.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final trips =
      await SimulationApiService.getDriverTrips(widget.userid!);
      setState(() {
        _trips = trips;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Derived summary stats ────────────────────────────────────────────────
  double get _totalMinutes =>
      _trips.fold(0.0, (sum, t) => sum + t.validTimeMinutes);

  double get _totalKm =>
      _trips.fold(0.0, (sum, t) => sum + t.validDistanceKm);

  int get _totalSegments =>
      _trips.fold(0, (sum, t) => sum + t.segmentsCount);

  Set<String> get _uniqueAds =>
      _trips.map((t) => t.adTitle).toSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xff00c4aa)),
      )
          : _error != null
          ? _buildError()
          : _buildBody(),
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────
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
              'Failed to load trips',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadTrips,
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

  // ── Main body ────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        // ── APP BAR ────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          backgroundColor: const Color(0xff00c4aa),
          foregroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
            title: const Text(
              'My Trip Stats',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
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
                // ── SUMMARY CARDS ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        icon: Icons.directions_car_outlined,
                        iconColor: const Color(0xff00c4aa),
                        value: '${_trips.length}',
                        label: 'Total Trips',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        icon: Icons.campaign_outlined,
                        iconColor: Colors.orange,
                        value: '${_uniqueAds.length}',
                        label: 'Ads Served',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        icon: Icons.access_time_outlined,
                        iconColor: Colors.blue,
                        value: '${_totalMinutes.toStringAsFixed(1)} min',
                        label: 'Valid Time',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        icon: Icons.route_outlined,
                        iconColor: Colors.purple,
                        value: '${_totalKm.toStringAsFixed(2)} km',
                        label: 'Total Distance',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── TRIPS HEADER ─────────────────────────────────────────
                Row(
                  children: [
                    const Text(
                      'Trip History',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                        const Color(0xff00c4aa).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_trips.length} trips',
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

                // ── TRIP CARDS ────────────────────────────────────────────
                if (_trips.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.directions_car_outlined,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No trips recorded yet.',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  RefreshIndicator(
                    color: const Color(0xff00c4aa),
                    onRefresh: _loadTrips,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _trips.length,
                      itemBuilder: (_, i) => _tripCard(_trips[i]),
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Summary card widget ──────────────────────────────────────────────────
  Widget _summaryCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ── Trip card widget ─────────────────────────────────────────────────────
  Widget _tripCard(DriverTripSummary t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: Trip # badge + Vehicle reg + Date ─────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _badge(
                    label: 'Trip #${t.tripId}',
                    bgColor: Colors.black87,
                    textColor: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  _badge(
                    label: t.vehicleReg,
                    bgColor:
                    const Color(0xff00c4aa).withOpacity(0.12),
                    textColor: const Color(0xff00c4aa),
                  ),
                ],
              ),
              Text(
                _fmtDate(t.tripDate),
                style:
                const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Ad title row ───────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.campaign_outlined,
                  size: 15, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t.adTitle.isNotEmpty
                      ? t.adTitle
                      : 'Ad #${t.adId}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xffeeeeee)),
          const SizedBox(height: 12),

          // ── Stats row ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _statCell(
                  icon: Icons.access_time,
                  iconColor: Colors.orange,
                  value:
                  '${t.validTimeMinutes.toStringAsFixed(1)} min',
                  label: 'Valid Time',
                ),
              ),
              Expanded(
                child: _statCell(
                  icon: Icons.route,
                  iconColor: Colors.blue,
                  value:
                  '${t.validDistanceKm.toStringAsFixed(2)} km',
                  label: 'Distance',
                ),
              ),
              Expanded(
                child: _statCell(
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

  Widget _badge({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statCell({
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

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
}