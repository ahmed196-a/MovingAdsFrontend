import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/agency.dart';
import '../../models/vehicle.dart';
import '../../services/VehicleApiService.dart';
import '../../services/agencyApiService.dart';
import '../../services/gpsService.dart';       // ← new
import '../advertiser/accountScreen.dart';
import '../driver/registeredVehiclesScreen.dart';
// import 'activeTripScreen.dart';                // ← new
import 'addRouteScreen.dart';

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
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              // GPS notice
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
      // 1. Get current GPS location
      Position pos;
      try {
        pos = await GpsService.instance.fetchOnce();
      } catch (gpsError) {
        // GPS failed — still link, but pass 0,0 so backend skips fence check
        // You can also block here and show an error if strict GPS is required
        _snack('GPS unavailable: $gpsError. Linking without location.');
        pos = Position(
          latitude: 0, longitude: 0,
          timestamp: DateTime.now(),
          accuracy: 0, altitude: 0, altitudeAccuracy: 0,
          heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
        );
      }

      // 2. Find the full vehicle object
      final vehicle = _userVehicles.firstWhere(
            (v) => v.vehicleReg == vehicleReg,
      );

      // 3. Link + trigger auto-assign (GPS is passed to backend)
      await VehicleApiService.linkVehicleToAgency(
        vehicle:   vehicle,
        agencyId:  agency.agencyId,
        // latitude:  pos.latitude,
        // longitude: pos.longitude,
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
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xff18B6A3),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
          if (index == 3) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AccountScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt), label: 'My Ads'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HEADER ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xff18B6A3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const Center(
                child: Text('Welcome',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              ),
            ),

            const SizedBox(height: 16),

            // ── QUICK ACTIONS ────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Quick Actions',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _quickActionCard(
                      icon: Icons.directions_car,
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
                      icon: Icons.location_on,
                      title: 'Set Routes',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddRouteScreen())),
                    ),
                  ),
                  const SizedBox(width: 12),
                  //Expanded(
                    // child: _quickActionCard(
                    //  icon: Icons.monetization_on,
                    //  title: 'My Earnings',
                    //   onTap: () => Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //           builder: (_) => const MyEarningsScreen())),
                    //  ),
                 // ),
                 // const SizedBox(width: 12),
                  // ── NEW: Go Online button ──────────────────────────────
                  // Expanded(
                  //   child: _quickActionCard(
                  //     icon: Icons.play_circle_outline,
                  //     title: 'Go\nOnline',
                  //     color: Colors.black87,
                  //     iconColor: const Color(0xff18B6A3),
                  //     onTap: () {
                  //       if (_selectedVehicleReg == null) {
                  //         _snack('Please select a vehicle first.');
                  //         return;
                  //       }
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) => ActiveTripScreen(
                        //       vehicleReg: _selectedVehicleReg!,
                        //       userId: _userId!,
                        //     ),
                        //   ),
                        // );
                      // },
                    // ),
                  // ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── AGENCIES TITLE ───────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Available Agencies',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),

            // ── VEHICLE FILTER DROPDOWN ──────────────────────────────────
            if (_userVehicles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedVehicleReg,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xff18B6A3)),
                      hint: const Text('Select a vehicle'),
                      items: _userVehicles
                          .map((v) => DropdownMenuItem(
                        value: v.vehicleReg,
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car,
                                size: 18,
                                color: Color(0xff18B6A3)),
                            const SizedBox(width: 8),
                            Text(
                              '${v.vehicleReg}  •  ${v.vehicleModel}',
                              style:
                              const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ))
                          .toList(),
                      onChanged: (val) async {
                        if (val == null ||
                            val == _selectedVehicleReg) return;
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

            // ── AGENCIES LIST ────────────────────────────────────────────
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
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 40),
                      const SizedBox(height: 10),
                      Text(_agenciesError!,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
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
                            const Color(0xff18B6A3)),
                        child: const Text('Retry',
                            style: TextStyle(
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              )
                  : _agencies.isEmpty
                  ? const Center(
                  child: Text('No agencies available.',
                      style: TextStyle(color: Colors.grey)))
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  itemCount: _agencies.length,
                  itemBuilder: (_, i) =>
                      _buildAgencyCard(_agencies[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AGENCY CARD ─────────────────────────────────────────────────────────────
  Widget _buildAgencyCard(Agency agency) {
    final bool isJoined =
        _selectedVehicleLinkedMap[agency.agencyId] == true;
    final bool isJoining = _joiningAgencyId == agency.agencyId;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5)
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: const Color(0xff18B6A3).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business,
                color: Color(0xff18B6A3), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agency.agencyName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis),
                if (agency.agencyDescription.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(agency.agencyDescription,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 3),
                Text(agency.ownerName,
                    style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
                if (isJoined && _selectedVehicleReg != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '🚗 $_selectedVehicleReg',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff18B6A3),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
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
                : ElevatedButton(
              onPressed: isJoined ||
                  isJoining ||
                  _selectedVehicleReg == null
                  ? null
                  : () => _showJoinDialog(agency),
              style: ElevatedButton.styleFrom(
                backgroundColor: isJoined
                    ? Colors.grey.shade300
                    : const Color(0xff18B6A3),
                foregroundColor:
                isJoined ? Colors.black54 : Colors.black,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: isJoined ? 0 : 2,
              ),
              child: isJoining
                  ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white))
                  : Text(
                isJoined ? 'Joined' : 'Join',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = const Color(0xff18B6A3),
    Color iconColor = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 5)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: iconColor == Colors.black
                        ? Colors.black
                        : Colors.white)),
          ],
        ),
      ),
    );
  }
}