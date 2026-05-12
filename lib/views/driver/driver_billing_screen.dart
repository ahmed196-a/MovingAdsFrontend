import 'package:flutter/material.dart';

import '../../services/billingApiService.dart';


class DriverBillingScreen extends StatefulWidget {
  final int vehicleOwnerId;

  const DriverBillingScreen({
    super.key,
    required this.vehicleOwnerId,
  });

  @override
  State<DriverBillingScreen> createState() =>
      _DriverBillingScreenState();
}

class _DriverBillingScreenState
    extends State<DriverBillingScreen> {
  Map<String, dynamic>? _billingData;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBilling();
  }

  Future<void> _loadBilling() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await BillingApiService.getDriverBilling(
        widget.vehicleOwnerId,
      );

      setState(() {
        _billingData = data;
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
        child: CircularProgressIndicator(
          color: Color(0xff00c4aa),
        ),
      )
          : _error != null
          ? _buildError()
          : _buildBody(),
    );
  }

  // ───────────────── ERROR STATE ─────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 52,
            ),
            const SizedBox(height: 14),
            const Text(
              'Failed to load billing',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadBilling,
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

  // ───────────────── MAIN BODY ─────────────────
  Widget _buildBody() {
    final data = _billingData!;

    return RefreshIndicator(
      color: const Color(0xff00c4aa),
      onRefresh: _loadBilling,
      child: CustomScrollView(
        slivers: [
          // ───────────────── APP BAR ─────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xff00c4aa),
            foregroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
              const EdgeInsets.only(left: 56, bottom: 14),
              title: const Text(
                'Driver Billing',
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
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // ───────────────── DRIVER INFO CARD ─────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                              const Color(0xff00c4aa)
                                  .withOpacity(0.15),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xff00c4aa),
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  Text(
                                    data['DriverName']
                                        ?.toString() ??
                                        '',
                                    style:
                                    const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['DriverEmail']
                                        ?.toString() ??
                                        '',
                                    style:
                                    const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            _badge(
                              label:
                              'Agency: ${data['AgencyName']}',
                              bgColor: const Color(
                                  0xff00c4aa)
                                  .withOpacity(0.12),
                              textColor:
                              const Color(0xff00c4aa),
                            ),
                            const SizedBox(width: 8),
                            _badge(
                              label:
                              'Rate: Rs ${data['DriverRate']}',
                              bgColor:
                              Colors.orange.withOpacity(
                                  0.12),
                              textColor: Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ───────────────── SUMMARY HEADER ─────────────────
                  Row(
                    children: [
                      const Text(
                        'Billing Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff00c4aa)
                              .withOpacity(0.15),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xff00c4aa),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ───────────────── SUMMARY CARDS ─────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          icon:
                          Icons.directions_car_outlined,
                          iconColor:
                          const Color(0xff00c4aa),
                          value:
                          '${data['TotalTrips']}',
                          label: 'Total Trips',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.route_outlined,
                          iconColor: Colors.purple,
                          value:
                          '${double.parse(data['TotalDistanceKm'].toString()).toStringAsFixed(2)} km',
                          label: 'Distance',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          icon:
                          Icons.access_time_outlined,
                          iconColor: Colors.blue,
                          value:
                          '${double.parse(data['TotalTimeMinutes'].toString()).toStringAsFixed(1)} min',
                          label: 'Valid Time',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          icon:
                          Icons.payments_outlined,
                          iconColor: Colors.green,
                          value:
                          'Rs ${double.parse(data['TotalEarned'].toString()).toStringAsFixed(2)}',
                          label: 'Total Earned',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          icon:
                          Icons.timelapse_outlined,
                          iconColor: Colors.orange,
                          value:
                          '${double.parse(data['TotalTimeHours'].toString()).toStringAsFixed(2)} hrs',
                          label: 'Hours',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.person_outline,
                          iconColor: Colors.redAccent,
                          value:
                          '#${data['DriverId']}',
                          label: 'Driver ID',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ───────────────── TOTAL EARNING CARD ─────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff00c4aa),
                          Color(0xff00a991),
                        ],
                      ),
                      borderRadius:
                      BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.black,
                          size: 34,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Total Earnings',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rs ${double.parse(data['TotalEarned'].toString()).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── SUMMARY CARD ─────────────────
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
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── BADGE ─────────────────
  Widget _badge({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
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
}