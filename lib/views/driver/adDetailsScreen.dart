import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/Ad.dart';
import '../../models/vehicle.dart';
import '../../models/request.dart';
import '../../services/VehicleApiService.dart';
import '../../services/RequestApiService.dart';
import 'package:intl/intl.dart';

class AdDetailsScreen extends StatefulWidget {
  final Ad ad;

  const AdDetailsScreen({super.key, required this.ad});

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {

  int? userid;
  List<Vehicle> vehicles = [];
  List<String> regnoList = [];
  String? selectedRegNo;

  // ✅ Store request status per vehicle
  Map<String, bool> requestStatus = {};

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
        regnoList = vehicles.map((v) => v.vehicleReg).toList();
      });
    }
  }

  Future<void> _applyRequest() async {
    if (selectedRegNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a vehicle")),
      );
      return;
    }

    if (userid == null) return;

    try {
      String result = await RequestApiService.createRequest(
        Request(
          requestedBy: userid!,
          requestedTo: widget.ad.userId,
          adId: widget.ad.adId,
          vehReg: selectedRegNo!,
        ),
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));

      setState(() {
        requestStatus[selectedRegNo!] = true;
      });

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {

    final ad = widget.ad;

    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        backgroundColor: const Color(0xff18B6A3),
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Ad Details",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🖼 AD IMAGE
            Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  ad.mediaPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image, size: 50),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              ad.adTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            /// 📅 DETAILS CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6)
                ],
              ),
              child: Column(
                children: [

                  Row(
                    children: [
                      const Icon(Icons.calendar_month),
                      const SizedBox(width: 8),
                      Text(
                        "StartDate: ${DateFormat("dd MMM yyyy").format(ad.StartingDate)}",
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(width: 8),
                      Expanded(child: Text(ad.adTitle)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.category),
                      const SizedBox(width: 8),
                      Expanded(child: Text(ad.Category)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔽 VEHICLE DROPDOWN
            DropdownButtonFormField<String>(
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

            const SizedBox(height: 24),

            /// 🔵 CONDITIONAL APPLY BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: selectedRegNo == null
                  ? ElevatedButton(
                onPressed: null,
                child: const Text("Apply"),
              )
                  : FutureBuilder<bool>(
                future: requestStatus.containsKey(selectedRegNo)
                    ? Future.value(requestStatus[selectedRegNo])
                    : RequestApiService.existsRequest(
                  Request(
                    requestedBy: userid!,
                    requestedTo: ad.userId,
                    adId: ad.adId,
                    vehReg: selectedRegNo!,
                  ),
                ),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  bool isApplied = snapshot.data!;
                  requestStatus[selectedRegNo!] = isApplied;

                  if (isApplied) {
                    return ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text(
                        "Applied",
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return ElevatedButton(
                    onPressed: _applyRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      "Apply",
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}