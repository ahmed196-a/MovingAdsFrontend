import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/matched_agency_dto.dart';
import '../../models/request.dart';
import '../../services/AdFenceApiService.dart';
import '../../services/requestApiService.dart';

class MatchedDriversScreen extends StatefulWidget {
  final int adId;

  const MatchedDriversScreen({super.key, required this.adId});

  @override
  State<MatchedDriversScreen> createState() => _MatchedDriversScreenState();
}

class _MatchedDriversScreenState extends State<MatchedDriversScreen> {
  List<MatchedAgencyDTO> agencies = [];
  bool isLoading = true;
  int? userId;

  Map<int, bool> requestStatus = {}; // key = agencyId

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUser();
    await _loadMatchedAgencies();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');
  }

  Future<void> _loadMatchedAgencies() async {
    try {
      final data =
      await AdFenceApiService.matchDrivers3(widget.adId);

      setState(() {
        agencies = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const Color(0xff18B6A3),
        title: const Text("Matched Agencies",
            style: TextStyle(color: Colors.black)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : agencies.isEmpty
          ? const Center(child: Text("No Matches Found"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: agencies.length,
        itemBuilder: (context, index) {
          final agency = agencies[index];

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

                  /// 🔷 Agency Header
                  Row(
                    children: [
                      const Icon(Icons.business,
                          color: Color(0xff18B6A3)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          agency.agencyName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff18B6A3),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (agency.agencyDescription.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        agency.agencyDescription,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54),
                      ),
                    ),

                  const SizedBox(height: 10),

                  /// 🔷 Request Button (AGENCY LEVEL)
                  FutureBuilder<bool>(
                    future: requestStatus
                        .containsKey(agency.agencyId)
                        ? Future.value(
                        requestStatus[agency.agencyId])
                        : RequestApiService.existsRequest(
                      Request(
                        requestedBy: userId!,
                        requestedTo: agency.userId,
                        adId: widget.adId,
                        agencyId: agency.agencyId,
                      ),
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child:
                            CircularProgressIndicator());
                      }

                      final isRequested = snapshot.data!;
                      requestStatus[agency.agencyId] =
                          isRequested;

                      return ElevatedButton(
                        onPressed: isRequested
                            ? null
                            : () async {
                          try {
                            final result =
                            await RequestApiService
                                .createRequest(
                              Request(
                                requestedBy: userId!,
                                requestedTo:
                                agency.userId,
                                adId: widget.adId,
                                agencyId:
                                agency.agencyId,
                              ),
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(
                                  context)
                                  .showSnackBar(
                                  SnackBar(
                                      content:
                                      Text(
                                          result)));
                            }

                            setState(() {
                              requestStatus[
                              agency.agencyId] = true;
                            });
                          } catch (e) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                                content:
                                Text("Error: $e")));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRequested
                              ? Colors.grey
                              : const Color(0xff00c4aa),
                        ),
                        child: Text(
                            isRequested ? "Requested" : "Request"),
                      );
                    },
                  ),

                  const Divider(height: 20),

                  /// 🔷 Vehicles List
                  ...agency.vehicles.map((vehicle) {
                    return Padding(
                      padding:
                      const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [

                          /// Vehicle Reg
                          Text(
                            vehicle.vehicleReg,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          /// Slots
                          ...vehicle.slots.map((slot) {
                            return Padding(
                              padding:
                              const EdgeInsets.only(
                                  bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule,
                                      size: 14,
                                      color:
                                      Color(0xff00c4aa)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "${slot.slotName}: ${slot.days.join(', ')}",
                                      style: const TextStyle(
                                          fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}