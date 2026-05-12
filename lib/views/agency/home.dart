import 'package:ads_frontend/models/simulation_models.dart';
import 'package:ads_frontend/views/agency/simulation_form_screen.dart';
import 'package:ads_frontend/views/agency/ad_analytics_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/adAssignment.dart';
import '../../models/agency.dart';
import '../../services/agencyApiService.dart';
import '../advertiser/requestsScreen.dart';
import '../advertiser/accountScreen.dart';
import '../../services/simulation_api_service.dart';
import 'agency_billing_screen.dart';
import 'agency_payments_screens.dart';

class AgencyHomeScreen extends StatefulWidget {
  const AgencyHomeScreen({super.key});

  @override
  State<AgencyHomeScreen> createState() => _AgencyHomeScreenState();
}

class _AgencyHomeScreenState extends State<AgencyHomeScreen> {
  int? _userId;
  Agency? _agency;
  List<AdAssignment> _assignments = [];

  bool _loadingAgency = true;
  bool _loadingAssignments = false;
  bool _loadingAllocated = false;
  String? _error;
  String? _allocatedError;

  int _currentIndex = 0;
  Map<int, AllocatedTimeResponse> _allocatedTimes = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');

    if (_userId == null) {
      setState(() {
        _error = 'User not logged in.';
        _loadingAgency = false;
      });
      return;
    }

    try {
      final agency = await AgencyApiService.getAgencyByUserId(_userId!);
      setState(() {
        _agency = agency;
        _loadingAgency = false;
        _loadingAssignments = true;
      });

      final assignments =
      await AgencyApiService.getAssignmentsByAgency(agency.agencyId);

      setState(() {
        _assignments = assignments;
        _loadingAssignments = false;
      });

      // ✅ FIX: always load allocated times after assignments succeed
      await _loadAllocatedTimes();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingAgency = false;
        _loadingAssignments = false;
      });
    }
  }

  Future<void> _reload() async {
    if (_agency == null) return;
    setState(() {
      _loadingAssignments = true;
      _error = null;
      _allocatedError = null;
      _allocatedTimes = {};
    });
    try {
      final assignments =
      await AgencyApiService.getAssignmentsByAgency(_agency!.agencyId);
      setState(() {
        _assignments = assignments;
        _loadingAssignments = false;
      });
      await _loadAllocatedTimes();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingAssignments = false;
      });
    }
  }

  Future<void> _loadAllocatedTimes() async {
    if (_assignments.isEmpty) return;

    setState(() => _loadingAllocated = true);

    for (final ad in _assignments) {
      try {
        final data = await SimulationApiService.getAllocatedTime(ad.adId);
        if (mounted) {
          setState(() => _allocatedTimes[ad.adId] = data);
        }
      } catch (e) {
        debugPrint('⚠️ Failed to load allocated time for adId=${ad.adId}: $e');
        // Continue loading others even if one fails
      }
    }

    if (mounted) setState(() => _loadingAllocated = false);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xff00c4aa);
      case 'completed':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAgency) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xff00c4aa)),
        ),
      );
    }

    if (_error != null && _agency == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _loadingAgency = true;
                    });
                    _init();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff00c4aa)),
                  child: const Text('Retry',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xff00c4aa),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => BillingScreen(agencyId: _agency!.agencyId)),
            );
          }
          else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AgencyPaymentsScreens(agencyId: _agency!.agencyId)),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Billing'),
          BottomNavigationBarItem(
              icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            color: const Color(0xff00c4aa),
            child: Column(
              children: [
                const Text(
                  'Agency Dashboard',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                if (_agency != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _agency!.agencyName,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── QUICK ACTION ROW ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RequestScreen()),
                      );
                    },
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xff00c4aa),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 5)
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'Requests',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (_agency != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SimulationFormScreen(agency: _agency!),
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 5)
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt_outlined, color: Color(0xff00c4aa)),
                          SizedBox(width: 8),
                          Text(
                            'Ad Simulation',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Assigned Ads',
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_loadingAllocated)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xff00c4aa),
                    ),
                  ),
              ],
            ),
          ),

          if (_error != null && _agency != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red.shade400, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

          // ── ASSIGNMENTS LIST ───────────────────────────────────────────
          Expanded(
            child: _loadingAssignments
                ? const Center(
              child: CircularProgressIndicator(color: Color(0xff00c4aa)),
            )
                : _assignments.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No assigned ads yet.',
                    style:
                    TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: const Color(0xff00c4aa),
              onRefresh: _reload,
              child: ListView.builder(
                padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _assignments.length,
                itemBuilder: (_, i) =>
                    _buildCard(_assignments[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(AdAssignment a) {
    final allocated = _allocatedTimes[a.adId];

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdAnalyticsScreen(
              adId: a.adId,
              adTitle: a.adTitle,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
            // Title + Status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    a.adTitle.isNotEmpty ? a.adTitle : 'Ad #${a.adId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(a.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    a.status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(a.status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ✅ FIX: backend sends StartDate → mapped as assignedAt
            if (a.assignedAt != null)
              _infoRow(
                icon: Icons.calendar_today_outlined,
                iconColor: Colors.grey,
                label: 'Assigned: ${_fmt(a.assignedAt!)}',
              ),

            // Allocated time section
            if (_loadingAllocated && allocated == null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xff00c4aa)),
                  ),
                  const SizedBox(width: 8),
                  Text('Loading schedule...',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ] else if (allocated != null) ...[
              const SizedBox(height: 6),

              if (allocated.startDate != null)
                _infoRow(
                  icon: Icons.date_range,
                  iconColor: Colors.black54,
                  label:
                  'Start: ${_fmt(allocated.startDate!)}',
                ),

              const SizedBox(height: 4),

              if (allocated.endDate != null)
                _infoRow(
                  icon: Icons.event,
                  iconColor: Colors.black54,
                  label: 'End: ${_fmt(allocated.endDate!)}',
                )
              else
                _infoRow(
                  icon: Icons.event,
                  iconColor: Colors.black38,
                  label: 'End: Not set',
                  labelColor: Colors.black38,
                ),

              const SizedBox(height: 10),

              Row(
                children: [
                  _chip(
                    label:
                    '${allocated.allocatedMinutes.toInt()} mins',
                    bgColor:
                    const Color(0xff00c4aa).withOpacity(0.12),
                    textColor: const Color(0xff00c4aa),
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    label:
                    '${allocated.allocatedHours.toStringAsFixed(1)} hrs',
                    bgColor: Colors.black12,
                    textColor: Colors.black87,
                  ),
                ],
              ),
            ],

            // Tap hint
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View Analytics',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xff00c4aa),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios,
                    size: 11, color: Color(0xff00c4aa)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    Color? labelColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, color: labelColor ?? Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: textColor),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}