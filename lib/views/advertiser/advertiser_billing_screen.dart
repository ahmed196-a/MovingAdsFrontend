import 'package:flutter/material.dart';

import '../../services/billingApiService.dart';


class AdvertiserBillingScreen extends StatefulWidget {
  final int userId;

  const AdvertiserBillingScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AdvertiserBillingScreen> createState() =>
      _AdvertiserBillingScreenState();
}

class _AdvertiserBillingScreenState
    extends State<AdvertiserBillingScreen> {
  List<dynamic> _billingList = [];

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
      final data =
      await BillingApiService.getAdvertiserBilling(
        widget.userId,
      );

      setState(() {
        _billingList = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ───────────────── TOTAL BILL ─────────────────
  double get _totalBill {
    return _billingList.fold(
      0.0,
          (sum, item) =>
      sum +
          double.parse(
            item['TotalBill'].toString(),
          ),
    );
  }

  double get _totalDistance {
    return _billingList.fold(
      0.0,
          (sum, item) =>
      sum +
          double.parse(
            item['TotalDistanceKm'].toString(),
          ),
    );
  }

  double get _totalMinutes {
    return _billingList.fold(
      0.0,
          (sum, item) =>
      sum +
          double.parse(
            item['TotalTimeMinutes'].toString(),
          ),
    );
  }

  int get _totalTrips {
    return _billingList.fold(
      0,
          (sum, item) =>
      sum + int.parse(item['TotalTrips'].toString()),
    );
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

  // ───────────────── ERROR ─────────────────
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

  // ───────────────── BODY ─────────────────
  Widget _buildBody() {
    final first = _billingList.first;

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
                'Advertiser Billing',
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
                  // ───────────────── USER INFO ─────────────────
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
                                    first['AdvertiserName'],
                                    style:
                                    const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    first[
                                    'AdvertiserEmail'],
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
                              'Agency: ${first['AgencyName']}',
                              bgColor: const Color(
                                  0xff00c4aa)
                                  .withOpacity(0.12),
                              textColor:
                              const Color(0xff00c4aa),
                            ),
                            const SizedBox(width: 8),
                            _badge(
                              label:
                              'Rate: Rs ${first['AdvertiserRate']}',
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

                  // ───────────────── SUMMARY ─────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          icon:
                          Icons.campaign_outlined,
                          iconColor:
                          const Color(0xff00c4aa),
                          value:
                          '${_billingList.length}',
                          label: 'Total Ads',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.route_outlined,
                          iconColor: Colors.purple,
                          value:
                          '${_totalDistance.toStringAsFixed(2)} km',
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
                          '${_totalMinutes.toStringAsFixed(1)} min',
                          label: 'Valid Time',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          icon:
                          Icons.directions_car_outlined,
                          iconColor: Colors.orange,
                          value: '$_totalTrips',
                          label: 'Trips',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ───────────────── TOTAL BILL CARD ─────────────────
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
                          'Total Bill',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rs ${_totalBill.toStringAsFixed(2)}',
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

                  // ───────────────── ADS HEADER ─────────────────
                  Row(
                    children: [
                      const Text(
                        'Billing By Ads',
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
                        child: Text(
                          '${_billingList.length} ads',
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

                  // ───────────────── AD CARDS ─────────────────
                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    itemCount: _billingList.length,
                    itemBuilder: (_, i) =>
                        _adCard(_billingList[i]),
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

  // ───────────────── AD CARD ─────────────────
  Widget _adCard(dynamic ad) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // TOP ROW
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
                    textColor:
                    const Color(0xff00c4aa),
                  ),
                ],
              ),
              _badge(
                label: ad['AdStatus'],
                bgColor:
                Colors.green.withOpacity(0.12),
                textColor: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            ad['AdTitle'],
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          const Divider(
            height: 1,
            color: Color(0xffeeeeee),
          ),

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
                  '${double.parse(ad['TotalDistanceKm'].toString()).toStringAsFixed(2)} km',
                  label: 'Distance',
                ),
              ),
              Expanded(
                child: _statCell(
                  icon: Icons.access_time,
                  iconColor: Colors.purple,
                  value:
                  '${double.parse(ad['TotalTimeMinutes'].toString()).toStringAsFixed(1)} min',
                  label: 'Time',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xff00c4aa)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text(
                  'Ad Bill',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${double.parse(ad['TotalBill'].toString()).toStringAsFixed(2)}',
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

  // ───────────────── BADGE ─────────────────
  Widget _badge({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
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

  // ───────────────── STAT CELL ─────────────────
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
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}