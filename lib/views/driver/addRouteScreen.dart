import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/vehicle.dart';
import '../../models/VehFence.dart';
import '../../services/VehicleApiService.dart';
import '../../services/VehFenceApiService.dart';

enum RouteFenceMode { polygon, route }

class AddRouteScreen extends StatefulWidget {
  const AddRouteScreen({super.key});

  @override
  State<AddRouteScreen> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  int? userid;
  List<Vehicle> vehicles = [];
  List<String> regnoList = [];
  String? selectedRegNo;

  final TextEditingController _labelController = TextEditingController();
  GoogleMapController? mapController;

  RouteFenceMode _selectedMode = RouteFenceMode.polygon;

  // Polygon state
  List<LatLng> polygonPoints = [];
  Set<Polygon> polygons = {};

  // Route state
  List<LatLng> routePoints = [];
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  static const LatLng initialPosition = LatLng(33.6844, 73.0479);

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  // ─── Load vehicles ────────────────────────────────────────────────────────

  Future<void> _loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    userid = prefs.getInt('userId');

    if (userid != null) {
      List<Vehicle> fetched = await VehicleApiService.fetchVehicles(userid!);
      setState(() {
        vehicles = fetched;
        regnoList = vehicles.map((v) => v.vehicleReg).toList();
      });
    }
  }

  // ─── Mode switching ───────────────────────────────────────────────────────

  Future<void> _onModeChanged(RouteFenceMode newMode) async {
    if (newMode == _selectedMode) return;

    final hasPoints = _selectedMode == RouteFenceMode.polygon
        ? polygonPoints.isNotEmpty
        : routePoints.isNotEmpty;

    if (hasPoints) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Switch Mode?"),
          content: const Text(
              "Switching modes will clear your current drawing. Continue?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Switch", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      _selectedMode = newMode;
      _clearAll();
    });
  }

  // ─── Polygon logic ────────────────────────────────────────────────────────

  void _onMapTappedPolygon(LatLng position) {
    setState(() {
      polygonPoints.add(position);
      polygons = {
        Polygon(
          polygonId: const PolygonId("route_polygon"),
          points: polygonPoints,
          strokeColor: Colors.black,
          strokeWidth: 2,
          fillColor: Colors.blue.withOpacity(0.3),
        ),
      };
    });
  }

  // ─── Route logic ──────────────────────────────────────────────────────────

  void _onMapTappedRoute(LatLng position) {
    setState(() {
      routePoints.add(position);

      markers = routePoints.asMap().entries.map((entry) {
        return Marker(
          markerId: MarkerId("route_point_${entry.key}"),
          position: entry.value,
          infoWindow: InfoWindow(title: "Point ${entry.key + 1}"),
        );
      }).toSet();

      if (routePoints.length >= 2) {
        polylines = {
          Polyline(
            polylineId: const PolylineId("veh_fence_route"),
            points: routePoints,
            color: Colors.blue,
            width: 4,
          ),
        };
      }
    });
  }

  // ─── Clear helpers ────────────────────────────────────────────────────────

  void _clearAll() {
    polygonPoints.clear();
    polygons.clear();
    routePoints.clear();
    markers.clear();
    polylines.clear();
  }

  void _clearCurrent() {
    setState(() {
      if (_selectedMode == RouteFenceMode.polygon) {
        polygonPoints.clear();
        polygons.clear();
      } else {
        routePoints.clear();
        markers.clear();
        polylines.clear();
      }
    });
  }

  bool get _hasPoints => _selectedMode == RouteFenceMode.polygon
      ? polygonPoints.isNotEmpty
      : routePoints.isNotEmpty;

  // ─── Save ─────────────────────────────────────────────────────────────────

  Future<void> _saveFence() async {
    if (selectedRegNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a vehicle")),
      );
      return;
    }

    if (_labelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an Area label")),
      );
      return;
    }

    if (_selectedMode == RouteFenceMode.polygon && polygonPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please draw a polygon")),
      );
      return;
    }

    if (_selectedMode == RouteFenceMode.route && routePoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select at least 2 points for the route")),
      );
      return;
    }

    final List<LatLng> activePoints = _selectedMode == RouteFenceMode.polygon
        ? polygonPoints
        : routePoints;

    List<Map<String, double>> points = activePoints
        .map((e) => {"lat": e.latitude, "lng": e.longitude})
        .toList();

    String polygonJson = jsonEncode(points);

    VehFence fence = VehFence(
      vehicleReg: selectedRegNo!,
      polygon: polygonJson,
      label: _labelController.text,
    );

    try {
      await VehFenceApiService.addFence(fence);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Route added successfully!")),
      );

      setState(() {
        _clearAll();
        _labelController.clear();
        selectedRegNo = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const Color(0xff18B6A3),
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Add New Route",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          // ── Vehicle dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DropdownButtonFormField<String>(
              value: selectedRegNo,
              hint: const Text("Select Vehicle"),
              items: regnoList.map((reg) {
                return DropdownMenuItem(value: reg, child: Text(reg));
              }).toList(),
              onChanged: (value) => setState(() => selectedRegNo = value),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[300],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Label field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _labelController,
              decoration: InputDecoration(
                hintText: "Area Label (e.g. Blue Area)",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.label_important_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _ModeTab(
                    label: "Polygon",
                    icon: Icons.pentagon_outlined,
                    isSelected: _selectedMode == RouteFenceMode.polygon,
                    onTap: () => _onModeChanged(RouteFenceMode.polygon),
                  ),
                  _ModeTab(
                    label: "Route",
                    icon: Icons.route_outlined,
                    isSelected: _selectedMode == RouteFenceMode.route,
                    onTap: () => _onModeChanged(RouteFenceMode.route),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Hint text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  _selectedMode == RouteFenceMode.polygon
                      ? "Tap on the map to draw a polygon area"
                      : "Tap at least 2 points to define a route",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Map
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: initialPosition,
                    zoom: 12,
                  ),
                  onMapCreated: (controller) => mapController = controller,
                  polygons:
                  _selectedMode == RouteFenceMode.polygon ? polygons : {},
                  markers:
                  _selectedMode == RouteFenceMode.route ? markers : {},
                  polylines:
                  _selectedMode == RouteFenceMode.route ? polylines : {},
                  onTap: _selectedMode == RouteFenceMode.polygon
                      ? _onMapTappedPolygon
                      : _onMapTappedRoute,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff18B6A3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _saveFence,
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),

      // ── Clear FAB
      floatingActionButton: _hasPoints
          ? FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: _clearCurrent,
        child: const Icon(Icons.clear),
      )
          : null,
    );
  }
}

// ─── Mode Tab Widget ──────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xff18B6A3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}