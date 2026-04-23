import 'package:ads_frontend/models/request.dart';
import 'package:ads_frontend/services/requestApiService.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/vehicle.dart';
import '../../models/matched_driver_grouped_dto.dart';
import '../../services/AdFenceApiService.dart';
import '../../services/VehicleApiService.dart';

class MatchedDriversScreen extends StatefulWidget {
  final int adId;

  const MatchedDriversScreen({super.key, required this.adId});

  @override
  State<MatchedDriversScreen> createState() => _MatchedDriversScreenState();
}

class _MatchedDriversScreenState extends State<MatchedDriversScreen> {
  // Holds matched vehicles paired with their slot data
  List<Map<String, dynamic>> matchedData = [];
  bool isLoading = true;
  int? userId;

  Map<String, bool> requestStatus = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUser();
    await _loadMatchedDrivers();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');
  }

  Future<void> _loadMatchedDrivers() async {
    try {
      // 1️⃣ Fetch grouped DTOs (vehicleReg + slots)
      List<MatchedDriverGroupedDTO> dtoList =
      await AdFenceApiService.matchDrivers3(widget.adId);

      // 2️⃣ Extract just the regs to fetch vehicle details
      List<String> regs = dtoList.map((d) => d.vehicleReg).toList();

      List<Vehicle> vehicles =
      await VehicleApiService.fetchVehiclesByRegs(regs);

      // 3️⃣ Merge vehicle details with slot data
      List<Map<String, dynamic>> merged = [];
      for (var dto in dtoList) {
        final vehicle = vehicles.firstWhere(
              (v) => v.vehicleReg == dto.vehicleReg,
          orElse: () => Vehicle(vehicleReg: dto.vehicleReg, vehicleModel: '', vehicleType: '', vehicleStatus: '', vehicleOwner: 0, MediaName: '', MediaPath: '', MediaType: ''),
        );
        merged.add({
          'vehicle': vehicle,
          'slots': dto.slots,
        });
      }

      setState(() {
        matchedData = merged;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
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
          "Matched Drivers",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : matchedData.isEmpty
          ? const Center(child: Text("No Matching Drivers Found"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matchedData.length,
        itemBuilder: (context, index) {
          final vehicle =
          matchedData[index]['vehicle'] as Vehicle;
          final slots =
          matchedData[index]['slots'] as List<SlotDayDTO>;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Row: image + vehicle info + button ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🚗 Vehicle Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: vehicle.MediaPath.isNotEmpty
                            ? Image.network(
                          vehicle.MediaPath,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[300],
                          child: const Icon(
                              Icons.directions_car,
                              size: 40),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Vehicle details + button
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.vehicleReg,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              vehicle.vehicleModel,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Owner: ${vehicle.OwnerName}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  vehicle.vehicleStatus,
                                  style: const TextStyle(
                                      fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // ── Request Button ──
                            FutureBuilder<bool>(
                              future: requestStatus.containsKey(
                                  vehicle.vehicleReg)
                                  ? Future.value(requestStatus[
                              vehicle.vehicleReg])
                                  : RequestApiService.existsRequest(
                                Request(
                                  requestedBy: userId!,
                                  requestedTo:
                                  vehicle.vehicleOwner,
                                  adId: widget.adId,
                                  vehReg: vehicle.vehicleReg,
                                ),
                              ),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox(
                                    height: 40,
                                    child: Center(
                                        child:
                                        CircularProgressIndicator()),
                                  );
                                }

                                bool isRequested = snapshot.data!;
                                requestStatus[vehicle.vehicleReg] =
                                    isRequested;

                                if (isRequested) {
                                  return ElevatedButton(
                                    onPressed: null,
                                    style:
                                    ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                            20),
                                      ),
                                    ),
                                    child:
                                    const Text("Requested"),
                                  );
                                }

                                return ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      String result =
                                      await RequestApiService
                                          .createRequest(
                                        Request(
                                          requestedBy: userId!,
                                          requestedTo:
                                          vehicle.vehicleOwner,
                                          adId: widget.adId,
                                          vehReg:
                                          vehicle.vehicleReg,
                                        ),
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                          content:
                                          Text(result)));
                                      setState(() {
                                        requestStatus[
                                        vehicle.vehicleReg] =
                                        true;
                                      });
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                          content: Text(
                                              "Error: $e")));
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xff00c4aa),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text("Request"),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Matched Slots Section ──
                  if (slots.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(thickness: 1),
                    const SizedBox(height: 6),
                    const Text(
                      "Matched Slots",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff18B6A3),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // One slot per line
                    ...slots.map(
                          (slot) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.schedule,
                                size: 16,
                                color: Color(0xff00c4aa)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "${slot.slotName}:  ${slot.days.join(', ')}",
                                style: const TextStyle(
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}




















// import 'package:ads_frontend/models/request.dart';
// import 'package:ads_frontend/services/requestApiService.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../models/vehicle.dart';
// import '../../services/AdFenceApiService.dart';
// import '../../services/VehicleApiService.dart';
//
// class MatchedDriversScreen extends StatefulWidget {
//   final int adId;
//
//   const MatchedDriversScreen({super.key, required this.adId});
//
//   @override
//   State<MatchedDriversScreen> createState() => _MatchedDriversScreenState();
// }
//
// class _MatchedDriversScreenState extends State<MatchedDriversScreen> {
//
//   List<Vehicle> matchedVehicles = [];
//   bool isLoading = true;
//   int? userId;
//
//   // ✅ Store request status per vehicle
//   Map<String, bool> requestStatus = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//   }
//
//   Future<void> _initialize() async {
//     await _loadUser();
//     await _loadMatchedDrivers();
//   }
//
//   Future<void> _loadUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     userId = prefs.getInt('userId');
//   }
//
//   Future<void> _loadMatchedDrivers() async {
//     try {
//       List<String> regs =
//       await AdFenceApiService.matchDrivers(widget.adId);
//
//       List<Vehicle> vehicles =
//       await VehicleApiService.fetchVehiclesByRegs(regs);
//
//       setState(() {
//         matchedVehicles = vehicles;
//         isLoading = false;
//       });
//
//     } catch (e) {
//       setState(() => isLoading = false);
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text("Error: $e")));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[200],
//
//       appBar: AppBar(
//         backgroundColor: const Color(0xff18B6A3),
//         leading: const BackButton(color: Colors.black),
//         title: const Text(
//           "Matched Drivers",
//           style: TextStyle(color: Colors.black),
//         ),
//       ),
//
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : matchedVehicles.isEmpty
//           ? const Center(child: Text("No Matching Drivers Found"))
//           : ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: matchedVehicles.length,
//         itemBuilder: (context, index) {
//
//           final vehicle = matchedVehicles[index];
//
//           return Card(
//             margin: const EdgeInsets.only(bottom: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             elevation: 4,
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Row(
//                 children: [
//
//                   // 🚗 Vehicle Image
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: vehicle.MediaPath.isNotEmpty
//                         ? Image.network(
//                       vehicle.MediaPath,
//                       width: 90,
//                       height: 90,
//                       fit: BoxFit.cover,
//                     )
//                         : Container(
//                       width: 90,
//                       height: 90,
//                       color: Colors.grey[300],
//                       child: const Icon(
//                           Icons.directions_car,
//                           size: 40),
//                     ),
//                   ),
//
//                   const SizedBox(width: 16),
//
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                       children: [
//
//                         Text(
//                           vehicle.vehicleReg,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//
//                         const SizedBox(height: 6),
//
//                         Text(
//                           vehicle.vehicleModel,
//                           style: const TextStyle(
//                             fontSize: 15,
//                             color: Colors.black54,
//                           ),
//                         ),
//
//                         const SizedBox(height: 6),
//
//                         Text(
//                           "Owner: ${vehicle.OwnerName}",
//                           style: const TextStyle(
//                             fontSize: 14,
//                           ),
//                         ),
//
//                         const SizedBox(height: 6),
//
//                         Row(
//                           children: [
//                             const Icon(Icons.star,
//                                 color: Colors.amber, size: 18),
//                             const SizedBox(width: 4),
//                             Text(
//                               vehicle.vehicleStatus,
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                           ],
//                         ),
//
//                         const SizedBox(height: 10),
//
//                         // ✅ Updated Button Logic
//                         FutureBuilder<bool>(
//                           future: requestStatus.containsKey(vehicle.vehicleReg)
//                               ? Future.value(requestStatus[vehicle.vehicleReg])
//                               : RequestApiService.existsRequest(
//                             Request(
//                               requestedBy: userId!,
//                               requestedTo: vehicle.vehicleOwner,
//                               adId: widget.adId,
//                               vehReg: vehicle.vehicleReg,
//                             ),
//                           ),
//                           builder: (context, snapshot) {
//
//                             if (!snapshot.hasData) {
//                               return const SizedBox(
//                                 height: 40,
//                                 child: Center(
//                                     child:
//                                     CircularProgressIndicator()),
//                               );
//                             }
//
//                             bool isRequested = snapshot.data!;
//
//                             requestStatus[vehicle.vehicleReg] =
//                                 isRequested;
//
//                             if (isRequested) {
//                               return ElevatedButton(
//                                 onPressed: null,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.grey,
//                                   foregroundColor: Colors.white,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius:
//                                     BorderRadius.circular(20),
//                                   ),
//                                 ),
//                                 child: const Text("Requested"),
//                               );
//                             }
//
//                             return ElevatedButton(
//                               onPressed: () async {
//                                 try {
//                                   String result =
//                                   await RequestApiService
//                                       .createRequest(
//                                     Request(
//                                       requestedBy: userId!,
//                                       requestedTo:
//                                       vehicle.vehicleOwner,
//                                       adId: widget.adId,
//                                       vehReg:
//                                       vehicle.vehicleReg,
//                                     ),
//                                   );
//
//                                   ScaffoldMessenger.of(context)
//                                       .showSnackBar(
//                                     SnackBar(
//                                         content:
//                                         Text(result)),
//                                   );
//
//                                   setState(() {
//                                     requestStatus[
//                                     vehicle.vehicleReg] =
//                                     true;
//                                   });
//
//                                 } catch (e) {
//                                   ScaffoldMessenger.of(context)
//                                       .showSnackBar(
//                                     SnackBar(
//                                         content: Text(
//                                             "Error: $e")),
//                                   );
//                                 }
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor:
//                                 const Color(0xff00c4aa),
//                                 foregroundColor: Colors.black,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius:
//                                   BorderRadius.circular(20),
//                                 ),
//                               ),
//                               child: const Text("Request"),
//                             );
//                           },
//                         ),
//
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }