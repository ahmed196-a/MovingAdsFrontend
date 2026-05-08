import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/agency.dart';
import '../../models/vehicle.dart';
import '../../services/VehicleApiService.dart';
import 'ad_simulation_map_screen2.dart';

class SimulationFormScreen extends StatefulWidget {
  final Agency agency;

  const SimulationFormScreen({super.key, required this.agency});

  @override
  State<SimulationFormScreen> createState() => _SimulationFormScreenState();
}

class _SimulationFormScreenState extends State<SimulationFormScreen>
    with SingleTickerProviderStateMixin {
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  bool _loadingVehicles = true;
  String? _error;

  TimeOfDay? _selectedTime;
  DateTime? _simulationStartDateTime;
  Timer? _clockTimer;
  String _liveTimeDisplay = '--:--:--';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadVehicles();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    try {
      final vehicles =
      await VehicleApiService.fetchVehiclesByAgency(widget.agency.agencyId);
      setState(() {
        _vehicles = vehicles;
        _loadingVehicles = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingVehicles = false;
      });
    }
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff00c4aa),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final startDt = DateTime(
          now.year, now.month, now.day, picked.hour, picked.minute, 0);
      setState(() {
        _selectedTime = picked;
        _simulationStartDateTime = startDt;
        _liveTimeDisplay = _formatTime(startDt);
      });
      _startClock(startDt);
    }
  }

  void _startClock(DateTime startDt) {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final elapsed =
          DateTime.now().difference(DateTime.now().copyWith(
              hour: startDt.hour,
              minute: startDt.minute,
              second: startDt.second)) *
              0;
      // Live clock: start from picked time and tick forward in real time
      final tickedTime =
      startDt.add(DateTime.now().difference(_simulationStartDateTime!));
      setState(() => _liveTimeDisplay = _formatTime(tickedTime));
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get _canStart =>
      _selectedTime != null && _selectedVehicle != null;

  void _startSimulation() {
    if (!_canStart) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdSimulationMapScreen2(
          agency: widget.agency,
          vehicle: _selectedVehicle!,
          simulationStartTime: _simulationStartDateTime!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      body: Column(
        children: [
          // ── HEADER ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 52, bottom: 24, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: Color(0xff00c4aa),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Ad Simulation',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.business,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Agency',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                letterSpacing: 0.5)),
                        Text(
                          widget.agency.agencyName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _loadingVehicles
                ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xff00c4aa)))
                : _error != null
                ? _buildError()
                : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── TIME PICKER CARD ──
                    _sectionLabel('Simulation Time', Icons.access_time),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black,
                                blurRadius: 8,
                                offset: Offset(0, 2))
                          ],
                          border: Border.all(
                            color: _selectedTime != null
                                ? const Color(0xff00c4aa)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xff00c4aa)
                                    .withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.schedule,
                                  color: Color(0xff00c4aa),
                                  size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedTime != null
                                        ? 'Start time set'
                                        : 'Tap to set start time',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500]),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedTime != null
                                        ? _formatTimeOfDay(
                                        _selectedTime!)
                                        : '--:--',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        letterSpacing: 1),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedTime != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xff00c4aa)
                                      .withOpacity(0.1),
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer,
                                        size: 14,
                                        color: Color(0xff00c4aa)),
                                    const SizedBox(width: 4),
                                    Text(
                                      _liveTimeDisplay,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xff00c4aa),
                                          fontWeight:
                                          FontWeight.bold,
                                          letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ] else
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── VEHICLE DROPDOWN ──
                    _sectionLabel('Select Vehicle', Icons.directions_car),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black,
                              blurRadius: 8,
                              offset: Offset(0, 2))
                        ],
                        border: Border.all(
                          color: _selectedVehicle != null
                              ? const Color(0xff00c4aa)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Vehicle>(
                          value: _selectedVehicle,
                          isExpanded: true,
                          hint: const Text(
                            'Choose a vehicle',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.black38),
                          ),
                          icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xff00c4aa)),
                          items: _vehicles.isEmpty
                              ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text(
                                  'No vehicles found',
                                  style: TextStyle(
                                      color: Colors.grey)),
                            )
                          ]
                              : _vehicles
                              .map((v) => DropdownMenuItem(
                            value: v,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration:
                                  BoxDecoration(
                                    shape:
                                    BoxShape.circle,
                                    color: v.vehicleStatus
                                        .toLowerCase() ==
                                        'online'
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(
                                    width: 10),
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  mainAxisSize:
                                  MainAxisSize.min,
                                  children: [
                                    Text(
                                      v.vehicleReg,
                                      style: const TextStyle(
                                          fontWeight:
                                          FontWeight
                                              .bold,
                                          fontSize: 14),
                                    ),
                                    Text(
                                      '${v.vehicleModel} · ${v.vehicleType}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors
                                              .grey[500]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedVehicle = v),
                        ),
                      ),
                    ),

                    if (_selectedVehicle != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xff00c4aa)
                              .withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xff00c4aa)
                                  .withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16,
                                color: Color(0xff00c4aa)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_selectedVehicle!.vehicleReg}  ·  ${_selectedVehicle!.vehicleModel}  ·  ${_selectedVehicle!.vehicleType}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff00c4aa),
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 36),

                    // ── HOW IT WORKS ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black,
                              blurRadius: 8,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('How it works',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87)),
                          const SizedBox(height: 12),
                          _step('1', 'Tap points on the map to draw the vehicle route'),
                          _step('2', 'All agency ad fences appear as colored zones'),
                          _step('3', 'Press Start — vehicle drives along your route'),
                          _step('4', 'Ad panel shows active ad based on fence'),
                          _step('5', 'Overlapping fences rotate ads every 3 seconds'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── START BUTTON ──
                    AnimatedOpacity(
                      opacity: _canStart ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 300),
                      child: GestureDetector(
                        onTap: _canStart ? _startSimulation : null,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _canStart
                                ? const Color(0xff00c4aa)
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _canStart
                                ? [
                              BoxShadow(
                                  color: const Color(0xff00c4aa)
                                      .withOpacity(0.4),
                                  blurRadius: 12,
                                  offset:
                                  const Offset(0, 4))
                            ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.map_outlined,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                _canStart
                                    ? 'Open Simulation Map'
                                    : 'Set time & vehicle to continue',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon) => Row(
    children: [
      Icon(icon, size: 17, color: const Color(0xff00c4aa)),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              letterSpacing: 0.3)),
    ],
  );

  Widget _step(String num, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xff00c4aa).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(num,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff00c4aa))),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black54, height: 1.4)),
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
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
                _loadingVehicles = true;
              });
              _loadVehicles();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff00c4aa)),
            child: const Text('Retry',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}