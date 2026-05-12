import 'package:flutter/material.dart';
import '../../services/billingApiService.dart';

class AgencyPaymentsScreens extends StatefulWidget {
  final int agencyId;

  const AgencyPaymentsScreens({
    super.key,
    required this.agencyId,
  });

  @override
  State<AgencyPaymentsScreens> createState() =>
      _AgencyPaymentsScreensState();
}

class _AgencyPaymentsScreensState
    extends State<AgencyPaymentsScreens>
    with SingleTickerProviderStateMixin {
  // ─── Summary ───
  Map<String, dynamic>? _summary;
  bool _summaryLoading = true;
  String? _summaryError;

  // ─── Advertiser detail ───
  List<dynamic> _advertiserList = [];
  bool _advertiserLoading = false;
  bool _advertiserLoaded = false;
  String? _advertiserError;

  // ─── Driver detail ───
  List<dynamic> _driverList = [];
  bool _driverLoading = false;
  bool _driverLoaded = false;
  String? _driverError;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0 && !_advertiserLoaded) {
      _loadAdvertisers();
    } else if (_tabController.index == 1 && !_driverLoaded) {
      _loadDrivers();
    }
  }

  // ─── Loaders ───
  Future<void> _loadSummary() async {
    setState(() {
      _summaryLoading = true;
      _summaryError = null;
    });
    try {
      final data =
      await BillingApiService.getAgencyBilling(widget.agencyId);
      setState(() {
        _summary = data;
        _summaryLoading = false;
      });
    } catch (e) {
      setState(() {
        _summaryError = e.toString();
        _summaryLoading = false;
      });
    }
  }

  Future<void> _loadAdvertisers() async {
    setState(() {
      _advertiserLoading = true;
      _advertiserError = null;
    });
    try {
      final data =
      await BillingApiService.getAgencyBillingforAdvertisers(
          widget.agencyId);
      setState(() {
        _advertiserList = data;
        _advertiserLoading = false;
        _advertiserLoaded = true;
      });
    } catch (e) {
      setState(() {
        _advertiserError = e.toString();
        _advertiserLoading = false;
        _advertiserLoaded = true;
      });
    }
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _driverLoading = true;
      _driverError = null;
    });
    try {
      final data =
      await BillingApiService.getAgencyBillingforDrivers(
          widget.agencyId);
      setState(() {
        _driverList = data;
        _driverLoading = false;
        _driverLoaded = true;
      });
    } catch (e) {
      setState(() {
        _driverError = e.toString();
        _driverLoading = false;
        _driverLoaded = true;
      });
    }
  }

  Future<void> _refreshAll() async {
    _advertiserLoaded = false;
    _driverLoaded = false;
    await _loadSummary();
    if (_tabController.index == 0) {
      await _loadAdvertisers();
    } else {
      await _loadDrivers();
    }
  }

  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: _summaryLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xff00c4aa),
        ),
      )
          : _summaryError != null
          ? _buildError(_summaryError!, _loadSummary)
          : _buildBody(),
    );
  }

  // ─── Error widget ───
  Widget _buildError(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.red, size: 52),
            const SizedBox(height: 14),
            const Text(
              'Failed to load data',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
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

  // ─── Main body ───
  Widget _buildBody() {
    final s = _summary!;

    return RefreshIndicator(
      color: const Color(0xff00c4aa),
      onRefresh: _refreshAll,
      child: CustomScrollView(
        slivers: [
          // ─── App Bar ───
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xff00c4aa),
            foregroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
              const EdgeInsets.only(left: 56, bottom: 14),
              title: const Text(
                'Agency Billing',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background:
              Container(color: const Color(0xff00c4aa)),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Agency info card ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6)
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xff00c4aa)
                              .withOpacity(0.15),
                          child: const Icon(Icons.business,
                              color: Color(0xff00c4aa), size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['AgencyName'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _badge(
                                    label:
                                    'Adv. Rate: Rs ${s['AdvertiserRate']}',
                                    bgColor: const Color(0xff00c4aa)
                                        .withOpacity(0.12),
                                    textColor:
                                    const Color(0xff00c4aa),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _badge(
                                    label:
                                    'Driver. Rate: Rs ${s['DriverRate']}',
                                    bgColor: const Color(0xff00c4aa)
                                        .withOpacity(0.12),
                                    textColor:
                                    const Color(0xff00c4aa),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ─── Summary grid ───
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.campaign_outlined,
                          iconColor: const Color(0xff00c4aa),
                          value: '${s['TotalAdTrips']}',
                          label: 'Ad Trips',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.directions_car_outlined,
                          iconColor: Colors.orange,
                          value: '${s['TotalDriverTrips']}',
                          label: 'Driver Trips',
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
                          value:
                          '${_fmt(s['TotalAdMinutes'])} min',
                          label: 'Ad Time',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.access_time_outlined,
                          iconColor: Colors.purple,
                          value:
                          '${_fmt(s['TotalDriverMinutes'])} min',
                          label: 'Driver Time',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ─── Financial cards ───
                  Row(
                    children: [
                      Expanded(
                        child: _financeCard(
                          label: 'Revenue',
                          value:
                          'Rs ${_fmt2(s['TotalRevenueFromAds'])}',
                          icon: Icons.trending_up,
                          gradient: [
                            const Color(0xff00c4aa),
                            const Color(0xff00a991)
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _financeCard(
                          label: 'Payouts',
                          value:
                          'Rs ${_fmt2(s['TotalPayoutToDrivers'])}',
                          icon: Icons.payments_outlined,
                          gradient: [
                            Colors.orange.shade400,
                            Colors.orange.shade600
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ─── Net profit ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade400,
                          Colors.green.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6)
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 34),
                        const SizedBox(height: 12),
                        const Text(
                          'Net Profit',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rs ${_fmt2(s['NetProfit'])}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Tab header ───
                  const Text(
                    'Billing Breakdown',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // ─── Tab bar ───
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4)
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      onTap: (index) {
                        if (index == 0 && !_advertiserLoaded) {
                          _loadAdvertisers();
                        } else if (index == 1 &&
                            !_driverLoaded) {
                          _loadDrivers();
                        }
                      },
                      indicator: BoxDecoration(
                        color: const Color(0xff00c4aa),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black54,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.campaign_outlined),
                          text: 'Advertisers',
                        ),
                        Tab(
                          icon:
                          Icon(Icons.directions_car_outlined),
                          text: 'Drivers',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── Tab content ───
                  SizedBox(
                    height: 800, // enough to show list; scrollable via outer
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAdvertiserTab(),
                        _buildDriverTab(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Advertiser Tab ───
  Widget _buildAdvertiserTab() {
    if (_advertiserLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
              color: Color(0xff00c4aa)),
        ),
      );
    }
    if (_advertiserError != null) {
      return _buildError(
          _advertiserError!, _loadAdvertisers);
    }
    if (!_advertiserLoaded) {
      // not loaded yet; show placeholder until tab is tapped
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
              color: Color(0xff00c4aa)),
        ),
      );
    }
    if (_advertiserList.isEmpty) {
      return _buildEmpty('No advertiser billing data found.');
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _advertiserList.length,
      itemBuilder: (_, i) =>
          _advertiserCard(_advertiserList[i]),
    );
  }

  // ─── Driver Tab ───
  Widget _buildDriverTab() {
    if (_driverLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
              color: Color(0xff00c4aa)),
        ),
      );
    }
    if (_driverError != null) {
      return _buildError(_driverError!, _loadDrivers);
    }
    if (!_driverLoaded) {
      return const SizedBox.shrink();
    }
    if (_driverList.isEmpty) {
      return _buildEmpty('No driver billing data found.');
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _driverList.length,
      itemBuilder: (_, i) => _driverCard(_driverList[i]),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                color: Colors.grey.shade400, size: 52),
            const SizedBox(height: 12),
            Text(msg,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ─── Advertiser Card ───
  Widget _advertiserCard(dynamic ad) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _badge(
                    label: 'Ad #${ad['AdId']}',
                    bgColor: Colors.black87,
                    textColor: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  _badge(
                    label: ad['Category'],
                    bgColor: const Color(0xff00c4aa)
                        .withOpacity(0.12),
                    textColor: const Color(0xff00c4aa),
                  ),
                ],
              ),
              _badge(
                label: ad['AdStatus'],
                bgColor: Colors.green.withOpacity(0.12),
                textColor: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Advertiser info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                const Color(0xff00c4aa).withOpacity(0.15),
                child: const Icon(Icons.person,
                    color: Color(0xff00c4aa), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad['AdvertiserName'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    Text(
                      ad['AdvertiserEmail'],
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            ad['AdTitle'],
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xffeeeeee)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _statCell(
                  icon: Icons.directions_car,
                  iconColor: Colors.orange,
                  value: '${ad['TotalTrips']}',
                  label: 'Trips',
                ),
              ),
              Expanded(
                child: _statCell(
                  icon: Icons.route,
                  iconColor: Colors.blue,
                  value:
                  '${_fmt2d(ad['TotalDistanceKm'])} km',
                  label: 'Distance',
                ),
              ),
              Expanded(
                child: _statCell(
                  icon: Icons.access_time,
                  iconColor: Colors.purple,
                  value:
                  '${_fmt(ad['TotalTimeMinutes'])} min',
                  label: 'Time',
                ),
              ),
              Expanded(
                child: _statCell(
                  icon: Icons.monetization_on_outlined,
                  iconColor: const Color(0xff00c4aa),
                  value: 'Rs ${ad['AdvertiserRate']}',
                  label: 'Rate/hr',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color:
              const Color(0xff00c4aa).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text('Billed to Advertiser',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54)),
                const SizedBox(height: 4),
                Text(
                  'Rs ${_fmt2d(ad['TotalBilledToAdvertiser'])}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff00c4aa),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Driver Card ───
  Widget _driverCard(dynamic drv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver info row
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                Colors.orange.withOpacity(0.15),
                child: const Icon(Icons.person,
                    color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      drv['DriverName'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    Text(
                      drv['DriverEmail'],
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _badge(
                label:
                'Rate: Rs ${drv['DriverRate']}/hr',
                bgColor: Colors.orange.withOpacity(0.12),
                textColor: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Vehicle info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car,
                    color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        drv['VehicleModel'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      Text(
                        drv['VehicleReg'],
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xffeeeeee)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _statCell(
                  icon: Icons.directions_car,
                  iconColor: Colors.orange,
                  value: '${drv['TotalTrips']}',
                  label: 'Trips',
                ),
              ),
              Expanded(
                child: _statCell(
                  icon: Icons.route,
                  iconColor: Colors.blue,
                  value:
                  '${_fmt2d(drv['TotalDistanceKm'])} km',
                  label: 'Distance',
                ),
              ),
              Expanded(
                child: _statCell(
                  icon: Icons.access_time,
                  iconColor: Colors.purple,
                  value:
                  '${_fmt(drv['TotalTimeMinutes'])} min',
                  label: 'Time',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text('Paid to Driver',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54)),
                const SizedBox(height: 4),
                Text(
                  'Rs ${_fmt2d(drv['TotalPaidToDriver'])}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Summary Card ───
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
          BoxShadow(color: Colors.black12, blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  // ─── Finance Card ───
  Widget _financeCard({
    required String label,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  // ─── Badge ───
  Widget _badge({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 4),
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

  // ─── Stat Cell ───
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
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // ─── Helpers ───
  String _fmt(dynamic v) {
    if (v == null) return '0';
    return double.parse(v.toString()).toStringAsFixed(1);
  }

  String _fmt2(dynamic v) {
    if (v == null) return '0.00';
    return double.parse(v.toString()).toStringAsFixed(2);
  }

  String _fmt2d(dynamic v) {
    if (v == null) return '0.00';
    return double.parse(v.toString()).toStringAsFixed(2);
  }
}