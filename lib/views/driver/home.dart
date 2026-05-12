import 'package:ads_frontend/views/driver/driver_billing_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/agency.dart';
import '../../models/vehicle.dart';
import '../../services/VehicleApiService.dart';
import '../../services/agencyApiService.dart';
import '../advertiser/accountScreen.dart';
import '../driver/registeredVehiclesScreen.dart';
import 'addRouteScreen.dart';
import 'driver_stats_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;

  int? _userId;
  List<Vehicle> _userVehicles = [];
  List<Agency> _agencies = [];

  String? _selectedVehicleReg;
  Map<int, bool> _selectedVehicleLinkedMap = {};
  Map<int, String> _linkedMap = {};

  bool _loadingAgencies = true;
  bool _loadingLinkedStatus = false;
  String? _agenciesError;
  int? _joiningAgencyId;

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
        _agenciesError = 'User not logged in.';
        _loadingAgencies = false;
      });
      return;
    }

    try {
      _userVehicles = await VehicleApiService.fetchVehicles(_userId!);
      final agencies = await AgencyApiService.getAllAgencies();

      if (_userVehicles.isNotEmpty) {
        _selectedVehicleReg = _userVehicles.first.vehicleReg;
        await _loadLinkedStatusForSelected(agencies);
      }

      setState(() {
        _agencies = agencies;
        _loadingAgencies = false;
      });
    } catch (e) {
      setState(() {
        _agenciesError = e.toString();
        _loadingAgencies = false;
      });
    }
  }

  Future<void> _loadLinkedStatusForSelected(List<Agency> agencies) async {
    if (_selectedVehicleReg == null) return;
    setState(() => _loadingLinkedStatus = true);

    final results = await Future.wait(
      agencies.map((a) => VehicleApiService.isVehicleLinkedToAgency(
        vehicleReg: _selectedVehicleReg!,
        agencyId: a.agencyId,
      )),
    );

    final map = <int, bool>{};
    for (int i = 0; i < agencies.length; i++) {
      map[agencies[i].agencyId] = results[i];
    }

    setState(() {
      _selectedVehicleLinkedMap = map;
      _loadingLinkedStatus = false;
    });
  }

  // ── JOIN DIALOG ─────────────────────────────────────────────────────────────
  Future<void> _showJoinDialog(Agency agency) async {
    if (_userVehicles.isEmpty) {
      _snack('You have no registered vehicles.');
      return;
    }

    final availableVehicles = _userVehicles
        .where((v) => !_linkedMap.values.contains(v.vehicleReg))
        .toList();

    if (availableVehicles.isEmpty) {
      _snack('All your vehicles are already linked to an agency.');
      return;
    }

    String? selectedReg =
    availableVehicles.any((v) => v.vehicleReg == _selectedVehicleReg)
        ? _selectedVehicleReg
        : availableVehicles.first.vehicleReg;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Join ${agency.agencyName}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select vehicle to link:',
                  style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedReg,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: availableVehicles
                    .map((v) => DropdownMenuItem(
                  value: v.vehicleReg,
                  child: Text(
                    '${v.vehicleReg}  •  ${v.vehicleModel}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ))
                    .toList(),
                onChanged: (val) =>
                    setDialogState(() => selectedReg = val),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xff18B6A3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 16, color: Color(0xff18B6A3)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your current location will be used to match available ads.',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _joinAgency(agency, selectedReg!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff18B6A3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  // ── JOIN AGENCY (with GPS fetch) ────────────────────────────────────────────
  Future<void> _joinAgency(Agency agency, String vehicleReg) async {
    setState(() => _joiningAgencyId = agency.agencyId);

    try {
      final vehicle = _userVehicles.firstWhere(
            (v) => v.vehicleReg == vehicleReg,
      );

      await VehicleApiService.linkVehicleToAgency(
        vehicle:   vehicle,
        agencyId:  agency.agencyId,
      );

      setState(() {
        _linkedMap[agency.agencyId] = vehicleReg;
        if (vehicleReg == _selectedVehicleReg) {
          _selectedVehicleLinkedMap[agency.agencyId] = true;
        }
        _joiningAgencyId = null;
      });

      _snack('$vehicleReg linked to ${agency.agencyName}!');
    } catch (e) {
      setState(() => _joiningAgencyId = null);
      _snack(e.toString());
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
      isError ? Colors.red : const Color(0xff18B6A3),
    ));
  }

  // ── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f4f4),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex.clamp(0, 2),
        selectedItemColor: const Color(0xff18B6A3),
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle:
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              break;

            case 1:
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverBillingScreen(vehicleOwnerId: _userId!),
                  ));
              break;

            case 2:
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverStatsScreen(userid: _userId),
                  ));
              break;

            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountScreen(),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Earning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── HEADER ──────────────────────────────────────────────────────────
          _buildHeader(),

          const SizedBox(height: 20),

          // ── QUICK ACTIONS ────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xff1a1a2e),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.directions_car_rounded,
                    title: 'Registered\nVehicles',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const RegisteredVehiclesScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.route_rounded,
                    title: 'Set Routes',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddRouteScreen())),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── AGENCIES TITLE ───────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Available Agencies',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xff1a1a2e),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── VEHICLE FILTER DROPDOWN ──────────────────────────────────────────
          if (_userVehicles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedVehicleReg,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xff18B6A3)),
                    hint: const Text('Select a vehicle'),
                    items: _userVehicles
                        .map((v) => DropdownMenuItem(
                      value: v.vehicleReg,
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car_rounded,
                              size: 18, color: Color(0xff18B6A3)),
                          const SizedBox(width: 8),
                          Text(
                            '${v.vehicleReg}  •  ${v.vehicleModel}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ))
                        .toList(),
                    onChanged: (val) async {
                      if (val == null || val == _selectedVehicleReg) return;
                      setState(() {
                        _selectedVehicleReg = val;
                        _selectedVehicleLinkedMap = {};
                      });
                      await _loadLinkedStatusForSelected(_agencies);
                    },
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── AGENCIES LIST ────────────────────────────────────────────────────
          Expanded(
            child: _loadingAgencies
                ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xff18B6A3)))
                : _agenciesError != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade300, size: 48),
                    const SizedBox(height: 10),
                    Text(_agenciesError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loadingAgencies = true;
                          _agenciesError = null;
                        });
                        _init();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xff18B6A3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12))),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
                : _agencies.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No agencies available.',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: const Color(0xff18B6A3),
              onRefresh: () async {
                setState(() {
                  _loadingAgencies = true;
                  _agenciesError = null;
                });
                await _init();
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _agencies.length,
                itemBuilder: (_, i) =>
                    _buildAgencyCard(_agencies[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.only(top: 52, left: 20, right: 20, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff18B6A3), Color(0xff0e9a89)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "DRIVER",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.75),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "Welcome back 👋",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ── AGENCY CARD ─────────────────────────────────────────────────────────────
  Widget _buildAgencyCard(Agency agency) {
    final bool isJoined =
        _selectedVehicleLinkedMap[agency.agencyId] == true;
    final bool isJoining = _joiningAgencyId == agency.agencyId;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isJoined || isJoining || _selectedVehicleReg == null
          ? null
          : () => _showJoinDialog(agency),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Agency icon
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: const Color(0xff18B6A3).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.business_rounded,
                    color: Color(0xff18B6A3), size: 28),
              ),
              const SizedBox(width: 14),

              // Agency info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agency.agencyName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xff1a1a2e)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (agency.agencyDescription.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        agency.agencyDescription,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          agency.ownerName,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    if (isJoined && _selectedVehicleReg != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xff18B6A3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_car_rounded,
                                size: 11, color: Color(0xff18B6A3)),
                            const SizedBox(width: 4),
                            Text(
                              _selectedVehicleReg!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xff18B6A3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Join button
              SizedBox(
                width: 76,
                height: 36,
                child: _loadingLinkedStatus
                    ? const Center(
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xff18B6A3)),
                  ),
                )
                    : isJoined
                    ? Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'Joined',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black45),
                    ),
                  ),
                )
                    : GestureDetector(
                  onTap: isJoining ||
                      _selectedVehicleReg == null
                      ? null
                      : () => _showJoinDialog(agency),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff18B6A3),
                          Color(0xff0e9a89),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff18B6A3)
                              .withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isJoining
                          ? const SizedBox(
                          height: 16,
                          width: 16,
                          child:
                          CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                          : const Text(
                        'Join',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── QUICK ACTION CARD ────────────────────────────────────────────────────────
  Widget _quickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff18B6A3), Color(0xff0e9a89)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff18B6A3).withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}