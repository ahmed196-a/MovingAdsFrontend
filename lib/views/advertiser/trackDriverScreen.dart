// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../../models/adAssignment.dart';
//
// class TrackDriverScreen extends StatefulWidget {
//   final AdAssignment assignment;
//   final int adId;
//
//   const TrackDriverScreen({
//     super.key,
//     required this.assignment,
//     required this.adId,
//   });
//
//   @override
//   State<TrackDriverScreen> createState() => _TrackDriverScreenState();
// }
//
// class _TrackDriverScreenState extends State<TrackDriverScreen> {
//
//   GoogleMapController? mapController;
//
//   final LatLng _dummyPosition = const LatLng(33.6844, 73.0479);
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
//           "AD Tracker",
//           style: TextStyle(color: Colors.black),
//         ),
//       ),
//
//       body: Column(
//         children: [
//
//           // ================= DRIVER INFO CARD =================
//
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             child: Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: const [
//                   BoxShadow(color: Colors.black12, blurRadius: 4),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   const CircleAvatar(
//                     radius: 26,
//                     backgroundImage: AssetImage("assets/profile.png"),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           widget.assignment.driverName,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 15,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           "${widget.assignment.vehicleModel} (${widget.assignment.vehicleReg})",
//                           style: const TextStyle(color: Colors.black54),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           "Tracking Ad ID: ${widget.adId}",
//                           style: const TextStyle(color: Colors.grey, fontSize: 12),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // ================= STATS ROW =================
//
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//               decoration: BoxDecoration(
//                 color: const Color(0xff00c4aa),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _statItem("Km's Driven", "10"),
//                   _statItem("Total Time", "2h 15m"),
//                   _statItem("Total Amount", "RS 1000"),
//                 ],
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 16),
//
//           // ================= GOOGLE MAP =================
//
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: GoogleMap(
//                   initialCameraPosition: CameraPosition(
//                     target: _dummyPosition,
//                     zoom: 14,
//                   ),
//                   onMapCreated: (controller) {
//                     mapController = controller;
//                   },
//                   markers: {
//                     Marker(
//                       markerId: const MarkerId("driver"),
//                       position: _dummyPosition,
//                       infoWindow: InfoWindow(
//                         title: widget.assignment.driverName,
//                         snippet:
//                         "${widget.assignment.vehicleModel} (${widget.assignment.vehicleReg})",
//                       ),
//                     ),
//                   },
//                   myLocationEnabled: false,
//                   myLocationButtonEnabled: false,
//                   zoomControlsEnabled: false,
//                 ),
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
//
//   Widget _statItem(String label, String value) {
//     return Column(
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 12,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }
// }