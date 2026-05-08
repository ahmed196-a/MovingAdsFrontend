import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/request.dart';
import '../../services/requestApiService.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {

  List<Request> allRequests = [];
  List<Request> filteredRequests = [];

  bool isLoading = true;
  int? userId;

  String selectedStatus = "pending"; // Default filter

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');

    if (userId != null) {
      allRequests =
      await RequestApiService.getReceivedRequests(userId!);
      _applyFilter();
    }

    setState(() {
      isLoading = false;
    });
  }

  void _applyFilter() {
    filteredRequests = allRequests
        .where((r) => r.status!.toLowerCase() == selectedStatus)
        .toList();
  }

  Future<void> _updateStatus(
      Request request, String status) async {

    bool success =
    await RequestApiService.updateRequestStatus(
      reqId: request.reqID!,
      requestedTo: userId!,
      status: status,
      adId: request.adId,
      agencyId: request.agencyId,
    );

    if (success) {

      setState(() {
        request.status = status;
        _applyFilter();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Request $status successfully"),
          backgroundColor:
          status == "accepted"
              ? Colors.green
              : Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update status"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFilterButton(String status) {
    bool isSelected = selectedStatus == status;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedStatus = status;
            _applyFilter();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xff18B6A3)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color:
                isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        title: const Text("Received Requests"),
        backgroundColor: const Color(0xff18B6A3),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          /// 🔹 FILTER SECTION
          Padding(
            padding:
            const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterButton("pending"),
                const SizedBox(width: 8),
                _buildFilterButton("accepted"),
                const SizedBox(width: 8),
                _buildFilterButton("rejected"),
              ],
            ),
          ),

          /// 🔹 REQUEST LIST
          Expanded(
            child: filteredRequests.isEmpty
                ? const Center(
                child: Text(
                    "No Requests Found"))
                : ListView.builder(
              padding:
              const EdgeInsets.symmetric(
                  horizontal: 16),
              itemCount:
              filteredRequests.length,
              itemBuilder:
                  (context, index) {

                final request =
                filteredRequests[index];

                return Card(
                  margin:
                  const EdgeInsets.only(
                      bottom: 16),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding:
                    const EdgeInsets.all(
                        16),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [

                        Text(
                          "From: ${request.fromUser}",
                          style:
                          const TextStyle(
                              fontWeight:
                              FontWeight
                                  .bold,
                              fontSize:
                              16),
                        ),

                        const SizedBox(
                            height: 6),

                        Text(
                          "Agency: ${request.agencyId}",
                        ),

                        const SizedBox(
                            height: 6),

                        Text(
                          "Ad: ${request.adTitle}",
                        ),

                        const SizedBox(
                            height: 6),

                        Text(
                          "Status: ${request.status}",
                          style: TextStyle(
                            color:
                            request.status ==
                                "accepted"
                                ? Colors.green
                                : request.status ==
                                "rejected"
                                ? Colors.red
                                : Colors.orange,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                            height: 12),

                        /// 🔹 SHOW BUTTONS ONLY IF PENDING
                        if (request.status ==
                            "pending")
                          Row(
                            children: [

                              Expanded(
                                child:
                                ElevatedButton(
                                  onPressed:
                                      () =>
                                      _updateStatus(
                                          request,
                                          "accepted"),
                                  style:
                                  ElevatedButton
                                      .styleFrom(
                                    backgroundColor:
                                    Colors.green,
                                  ),
                                  child:
                                  const Text(
                                      "Accept"),
                                ),
                              ),

                              const SizedBox(
                                  width: 10),

                              Expanded(
                                child:
                                ElevatedButton(
                                  onPressed:
                                      () =>
                                      _updateStatus(
                                          request,
                                          "rejected"),
                                  style:
                                  ElevatedButton
                                      .styleFrom(
                                    backgroundColor:
                                    Colors.red,
                                  ),
                                  child:
                                  const Text(
                                      "Reject"),
                                ),
                              ),
                            ],
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}































// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../models/request.dart';
// import '../../services/requestApiService.dart';
//
// class RequestScreen extends StatefulWidget {
//   const RequestScreen({super.key});
//
//   @override
//   State<RequestScreen> createState() => _RequestScreenState();
// }
//
// class _RequestScreenState extends State<RequestScreen> {
//
//   List<Request> requests = [];
//   bool isLoading = true;
//   int? userId;
//
//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//   }
//
//   Future<void> _initialize() async {
//     final prefs = await SharedPreferences.getInstance();
//     userId = prefs.getInt('userId');
//
//     if (userId != null) {
//       requests = await RequestApiService.getReceivedRequests(userId!);
//     }
//
//     setState(() {
//       isLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Received Requests"),
//         backgroundColor: const Color(0xff18B6A3),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : requests.isEmpty
//           ? const Center(child: Text("No Requests Received"))
//           : ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: requests.length,
//         itemBuilder: (context, index) {
//
//           final request = requests[index];
//
//           return Card(
//             margin: const EdgeInsets.only(bottom: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             elevation: 4,
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment:
//                 CrossAxisAlignment.start,
//                 children: [
//
//                   // 👤 Who requested
//                   Text(
//                     "From: ${request.fromUser}",
//                     style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16),
//                   ),
//
//                   const SizedBox(height: 6),
//
//                   // 🚗 Vehicle
//                   Text(
//                     "Vehicle: ${request.vehReg}",
//                     style: const TextStyle(fontSize: 14),
//                   ),
//
//                   const SizedBox(height: 6),
//
//                   // 📢 Ad Title
//                   Text(
//                     "Ad: ${request.adTitle}",
//                     style: const TextStyle(fontSize: 14),
//                   ),
//
//                   const SizedBox(height: 6),
//
//                   // 📌 Status
//                   Text(
//                     "Status: ${request.status}",
//                     style: const TextStyle(
//                         fontSize: 14,
//                         color: Colors.black54),
//                   ),
//
//                   const SizedBox(height: 12),
//
//                   // ✅ Accept & ❌ Reject Buttons
//                   Row(
//                     children: [
//
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: () async{
//                             bool success=await RequestApiService.updateRequestStatus(
//                                 reqId: request.reqID!,
//                                 requestedTo: request.requestedTo,
//                                 adId: request.adId,
//                                 status: "accepted",
//                                 vehReg: request.vehReg);
//                             if(success){
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(content : Text("Request Aceepted Successfully!")),
//                               );
//                             }else{
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(content : Text("Failed to Aceept Request!")),
//                               );
//                             }
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green,
//                           ),
//                           child: const Text("Accept"),
//                         ),
//                       ),
//
//                       const SizedBox(width: 10),
//
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: () async{
//                             bool success=await RequestApiService.updateRequestStatus(
//                                 reqId: request.reqID!, requestedTo: request.requestedTo, adId: request.adId,
//                                 status: "rejected", vehReg: request.vehReg);
//                             if(success){
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(content : Text("Request Aceepted Successfully!")),
//                               );
//                             }
//                             else{
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(content : Text("Failed to Aceept Request!")),
//                               );
//                             }
//                             },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.red,
//                           ),
//                           child: const Text("Reject"),
//                         ),
//                       ),
//                     ],
//                   )
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }