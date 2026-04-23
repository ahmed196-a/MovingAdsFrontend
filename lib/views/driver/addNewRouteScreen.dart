import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/vehicle.dart';
import '../../models/VehFence.dart';
import '../../services/VehicleApiService.dart';
import '../../services/VehFenceApiService.dart';

class AddNewRouteScreen extends StatefulWidget {
  const AddNewRouteScreen({super.key});

  @override
  State<AddNewRouteScreen> createState() => _AddNewRouteScreenState();
}

class _AddNewRouteScreenState extends State<AddNewRouteScreen> {

  int? userid;
  List<Vehicle> vehicles = [];
  List<String> regnoList = [];
  String? selectedRegNo;
  final TextEditingController _labelController = TextEditingController();
  GoogleMapController? mapController;

  List<LatLng> polygonPoints = [];
  Set<Polygon> polygons = {};

  static const LatLng initialPosition =
  LatLng(33.6844, 73.0479);

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    userid = prefs.getInt('userId');

    if (userid != null) {
      List<Vehicle> fetched =
      await VehicleApiService.fetchVehicles(userid!);

      setState(() {
        vehicles = fetched;
        regnoList =
            vehicles.map((v) => v.vehicleReg).toList();
      });
    }
  }

  void onMapTapped(LatLng position) {
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

  void clearPolygon() {
    setState(() {
      polygonPoints.clear();
      polygons.clear();
    });
  }

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
    }

    if (polygonPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please draw a route")),
      );
      return;
    }

    // Convert polygon points to JSON string
    List<Map<String, double>> points = polygonPoints
        .map((e) => {
      "lat": e.latitude,
      "lng": e.longitude,
    }).toList();

    String polygonJson = jsonEncode(points);

    // Create full object
    VehFence fence = VehFence(
      vehicleReg: selectedRegNo!,
      polygon: polygonJson,
      label: _labelController.text
    );

    try {
      await VehFenceApiService.addFence(fence);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Route added successfully!")),
      );

      clearPolygon();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

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

          /// 🔽 VEHICLE DROPDOWN
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: selectedRegNo,
              hint: const Text("Select Vehicle"),
              items: regnoList.map((reg) {
                return DropdownMenuItem(
                  value: reg,
                  child: Text(reg),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRegNo = value;
                });
              },
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          const SizedBox(height: 16),
          /// 🗺 MAP
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
                  onMapCreated: (controller) {
                    mapController = controller;
                  },
                  polygons: polygons,
                  onTap: onMapTapped,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// 🔵 ADD BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _saveFence,
                child: const Text(
                  "Add",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),

      floatingActionButton: polygonPoints.isNotEmpty
          ? FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: clearPolygon,
        child: const Icon(Icons.clear),
      )
          : null,
    );
  }
}
