import 'package:ads_frontend/views/advertiser/republishAdScreen.dart';
import 'package:ads_frontend/views/advertiser/trackDriverScreen.dart';
import 'package:flutter/material.dart';
import '../../models/Ad.dart';
import '../../models/adAssignment.dart';
import '../../services/AdApiService.dart';

class AdDetailsScreen extends StatefulWidget {
  final int adId;

  const AdDetailsScreen({super.key, required this.adId});

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  late Future<Ad?> adFuture;
  late Future<List<AdAssignment>> driversFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    adFuture = AdApiService.getAdById(widget.adId);
    driversFuture = AdApiService.getAssignedDrivers(widget.adId);
  }

  void _refreshData() {
    setState(() {
      _loadData();
    });
  }

  // ================= ACTION METHODS =================

  Future<void> _pauseAd() async {
    bool success = await AdApiService.pauseAd(widget.adId);
    if (success) {
      _refreshData();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Ad Paused")));
    }
  }

  Future<void> _resumeAd() async {
    bool success = await AdApiService.resumeAd(widget.adId);
    if (success) {
      _refreshData();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Ad Resumed")));
    }
  }

  Future<void> _terminateAd() async {
    bool success = await AdApiService.terminateAd(widget.adId);
    if (success) {
      _refreshData();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Ad Terminated")));
    }
  }

  void _confirmTerminate() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Terminate Campaign"),
        content:
        const Text("Are you sure you want to terminate this ad?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _terminateAd();
            },
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Terminate"),
          ),
        ],
      ),
    );
  }

  // ================= UI HELPERS =================

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "active":
        return Colors.green;
      case "paused":
        return Colors.orange;
      case "completed":
        return Colors.red;
      case "inactive":
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButtons(Ad ad) {
    final status = ad.status.toLowerCase();

    if (status == "active") {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _pauseAd,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text("Pause"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _confirmTerminate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text("Terminate"),
            ),
          ),
        ],
      );
    }

    if (status == "paused") {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _resumeAd,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text("Resume"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _confirmTerminate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text("Terminate"),
            ),
          ),
        ],
      );
    }

    if (status == "completed") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RepublishAdScreen(ad: ad),
              ),
            );
          },
          style:
          ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text("Republish Ad"),
        ),
      );
    }

    return const SizedBox();
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const Color(0xff00c4aa),
        title: const Text(
          "Ad Details",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<Ad?>(
        future: adFuture,
        builder: (context, adSnapshot) {
          if (adSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!adSnapshot.hasData || adSnapshot.data == null) {
            return const Center(child: Text("Ad not found"));
          }

          final ad = adSnapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ================= AD CARD =================

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6)
                    ],
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ad.mediaPath,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image, size: 80),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ad.adTitle,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(ad.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ad.status,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActionButtons(ad),
                    ],
                  ),
                ),

                const SizedBox(height: 25),


                // const Text(
                //   "Assigned Drivers",
                //   style:
                //   TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                // ),

                // const SizedBox(height: 12),

                // ================= DRIVERS SECTION =================

                // if (ad.status.toLowerCase() == "inactive")
                //   Container(
                //     padding: const EdgeInsets.all(16),
                //     decoration: BoxDecoration(
                //       color: Colors.white,
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     child: const Center(
                //       child: Text(
                //         "Ad is inactive. No drivers assigned.",
                //         style: TextStyle(color: Colors.grey),
                //       ),
                //     ),
                //   )
                // else
                //   FutureBuilder<List<AdAssignment>>(
                //     future: driversFuture,
                //     builder: (context, driverSnapshot) {
                //       if (driverSnapshot.connectionState ==
                //           ConnectionState.waiting) {
                //         return const Center(
                //             child: CircularProgressIndicator());
                //       }
                //
                //       if (!driverSnapshot.hasData ||
                //           driverSnapshot.data!.isEmpty) {
                //         return Container(
                //           padding: const EdgeInsets.all(16),
                //           decoration: BoxDecoration(
                //             color: Colors.white,
                //             borderRadius: BorderRadius.circular(12),
                //           ),
                //           child: const Center(
                //             child: Text(
                //               "No drivers assigned yet.",
                //               style: TextStyle(color: Colors.grey),
                //             ),
                //           ),
                //         );
                //       }
                //
                //       final drivers = driverSnapshot.data!;
                //
                //       return Column(
                //         children: drivers.map((driver) {
                //           return Container(
                //             margin:
                //             const EdgeInsets.only(bottom: 14),
                //             padding: const EdgeInsets.all(16),
                //             decoration: BoxDecoration(
                //               color: Colors.white,
                //               borderRadius:
                //               BorderRadius.circular(12),
                //               boxShadow: const [
                //                 BoxShadow(
                //                     color: Colors.black12,
                //                     blurRadius: 4)
                //               ],
                //             ),
                //             child: Column(
                //               children: [
                //
                //                 Row(
                //                   children: [
                //                     const CircleAvatar(
                //                       radius: 28,
                //                       backgroundImage:
                //                       AssetImage(
                //                           "assets/profile.png"),
                //                     ),
                //                     const SizedBox(width: 12),
                //                     Expanded(
                //                       child: Column(
                //                         crossAxisAlignment:
                //                         CrossAxisAlignment.start,
                //                         children: [
                //                           Text(
                //                             driver.driverName,
                //                             style: const TextStyle(
                //                                 fontWeight:
                //                                 FontWeight.bold),
                //                           ),
                //                           Text(
                //                             "${driver.vehicleModel} (${driver.vehicleReg})",
                //                           ),
                //                         ],
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //
                //                 const SizedBox(height: 12),
                //
                //                 // TRACK BUTTON ALWAYS
                //                 SizedBox(
                //                   width: double.infinity,
                //                   child: ElevatedButton(
                //                     onPressed: () {
                //                       Navigator.push(
                //                         context,
                //                         MaterialPageRoute(
                //                           builder: (_) =>
                //                               TrackDriverScreen(
                //                                 assignment: driver,
                //                                 adId: widget.adId,
                //                               ),
                //                         ),
                //                       );
                //                     },
                //                     style: ElevatedButton.styleFrom(
                //                       backgroundColor: Colors.green,
                //                     ),
                //                     child:
                //                     const Text("Track Driver"),
                //                   ),
                //                 )
                //               ],
                //             ),
                //           );
                //         }).toList(),
                //       );
                //     },
                //   ),
              ],
            ),
          );
        },
      ),
    );
  }
}