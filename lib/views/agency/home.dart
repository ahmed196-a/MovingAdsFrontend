import 'package:ads_frontend/views/agency/simulation_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/adAssignment.dart';
import '../../models/agency.dart';
import '../../services/agencyApiService.dart';
import '../advertiser/requestsScreen.dart';
import '../advertiser/statsScreen.dart';
import '../advertiser/myAdsScreen.dart';
import '../advertiser/accountScreen.dart';


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
  String? _error;

  int _currentIndex = 0;

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
    });
    try {
      final assignments =
      await AgencyApiService.getAssignmentsByAgency(_agency!.agencyId);
      setState(() {
        _assignments = assignments;
        _loadingAssignments = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingAssignments = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':    return const Color(0xff00c4aa);
      case 'completed': return Colors.blue;
      case 'paused':    return Colors.orange;
      default:          return Colors.grey;
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
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xff00c4aa),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // needed for 5 items
        onTap: (index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);

          if (index == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const StatsScreen()));
          } else if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => SimulationFormScreen(agency: _agency!)));
          } else if (index == 3) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyAdsScreen()));
          } else if (index == 4) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AccountScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Stats'),
          // ── new tab ──────────────────────────────────────────────────
          BottomNavigationBarItem(
              icon: Icon(Icons.bolt_outlined), label: 'Activity'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt), label: 'My Ads'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Account'),
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
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black87),
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
                // Received Requests button
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
                // Activity shortcut button
                const SizedBox(width: 12),
                // Ad Simulation button
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (_agency != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SimulationFormScreen(
                                agency: _agency!),
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

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Assigned Ads',
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          if (_error != null && _agency != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!,
                  style: const TextStyle(
                      color: Colors.red, fontSize: 13)),
            ),

          // ── ASSIGNMENTS LIST ───────────────────────────────────────────
          Expanded(
            child: _loadingAssignments
                ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xff00c4aa)))
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
                    style: TextStyle(
                        color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: const Color(0xff00c4aa),
              onRefresh: _reload,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  a.adTitle.isNotEmpty ? a.adTitle : 'Ad #${a.adId}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                  _statusColor(a.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  a.status.toUpperCase(),
                  style: TextStyle(
                      color: _statusColor(a.status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (a.assignedAt != null)
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Assigned: ${_fmt(a.assignedAt!)}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}