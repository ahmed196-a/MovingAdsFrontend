// Driver sees their earnings per vehicle, per ad, per day.
// Accessed from DriverHomeScreen quick actions.
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/billing_record.dart';
import '../../models/vehicle.dart';
import '../../services/BillingApiService.dart';
import '../../services/VehicleApiService.dart';

class MyEarningsScreen extends StatefulWidget {
  const MyEarningsScreen({super.key});

  @override
  State<MyEarningsScreen> createState() => _MyEarningsScreenState();
}

class _MyEarningsScreenState extends State<MyEarningsScreen> {
  List<Vehicle> vehicles = [];
  String? selectedVehReg;
  List<BillingRecord> records = [];
  bool isLoadingVehicles = true;
  bool isLoadingRecords = false;
  int? userId;

  // Totals for selected vehicle
  double get totalEarned =>
      records.fold(0, (sum, r) => sum + r.amountDue);
  double get totalPaid =>
      records.where((r) => r.status == 'paid').fold(0, (sum, r) => sum + r.amountDue);
  double get totalUnpaid =>
      records.where((r) => r.status != 'paid').fold(0, (sum, r) => sum + r.amountDue);

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');

    if (userId != null) {
      final fetched = await VehicleApiService.fetchVehicles(userId!);
      setState(() {
        vehicles = fetched;
        isLoadingVehicles = false;
      });
    }
  }

  Future<void> _loadEarnings(String vehReg) async {
    setState(() {
      isLoadingRecords = true;
      records = [];
    });

    try {
      final data = await BillingApiService.getMyEarnings(vehReg);
      setState(() {
        records = data;
        isLoadingRecords = false;
      });
    } catch (e) {
      setState(() => isLoadingRecords = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
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
          "My Earnings",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: isLoadingVehicles
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          // ── VEHICLE PICKER ───────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: selectedVehReg,
              hint: const Text("Select Vehicle"),
              items: vehicles.map((v) {
                return DropdownMenuItem(
                  value: v.vehicleReg,
                  child: Text("${v.vehicleReg}  •  ${v.vehicleModel}"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedVehReg = value);
                if (value != null) _loadEarnings(value);
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── TOTALS CARD ──────────────────────────────
          if (records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xff18B6A3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _totalItem("Total Earned",
                        "RS ${totalEarned.toStringAsFixed(0)}"),
                    _totalItem(
                        "Paid", "RS ${totalPaid.toStringAsFixed(0)}"),
                    _totalItem("Pending",
                        "RS ${totalUnpaid.toStringAsFixed(0)}"),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ── RECORDS ──────────────────────────────────
          Expanded(
            child: isLoadingRecords
                ? const Center(child: CircularProgressIndicator())
                : selectedVehReg == null
                ? const Center(
                child: Text("Select a vehicle to see earnings"))
                : records.isEmpty
                ? const Center(
                child: Text("No earnings yet"))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                return _buildRecordCard(records[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }

  Widget _buildRecordCard(BillingRecord record) {
    final isPaid = record.status == 'paid';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Date + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat("dd MMM yyyy").format(record.billDate),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isPaid ? Colors.green : Colors.orange),
                  ),
                  child: Text(
                    record.status.toUpperCase(),
                    style: TextStyle(
                      color: isPaid ? Colors.green : Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Ad title
            Text(
              record.adTitle,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),

            const SizedBox(height: 10),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _chip(Icons.directions_car,
                    "${record.validDistanceKm.toStringAsFixed(2)} km"),
                _chip(Icons.timer,
                    "${record.validTimeMinutes.toStringAsFixed(0)} min"),
                _chip(Icons.attach_money,
                    "RS ${record.amountDue.toStringAsFixed(0)}",
                    bold: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, {bool bold = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xff18B6A3)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}


