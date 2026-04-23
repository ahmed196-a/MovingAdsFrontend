// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
//
// import '../../services/AdApiService.dart';
// import '../../services/AdFenceApiService.dart';
// import '../../services/VehFenceApiService.dart';
//
// // ───────── AD MODEL ─────────
// class _QueuedAd {
//   final int adId;
//   final String adTitle;
//   final String mediaPath;
//
//   _QueuedAd({
//     required this.adId,
//     required this.adTitle,
//     required this.mediaPath,
//   });
// }
//
// class AdSimulationScreen extends StatefulWidget {
//   const AdSimulationScreen({super.key});
//
//   @override
//   State<AdSimulationScreen> createState() => _AdSimulationScreenState();
// }
//
// class _AdSimulationScreenState extends State<AdSimulationScreen>
//     with TickerProviderStateMixin {
//
//   GoogleMapController? _mapController;
//
//   // ───────── STATE ─────────
//   bool _isLoading = true;
//   String? _errorMessage;
//   bool _isRunning = false;
//   bool _inOverlapZone = false;
//
//   List<LatLng> _route = [];
//   int _currentStep = 0;
//
//   LatLng get _carPosition => _route[_currentStep];
//
//   Timer? _moveTimer;
//   Timer? _adRotateTimer;
//   Timer? _countdownTimer;
//
//   List<_QueuedAd> _adQueue = [];
//   int _currentAdIndex = 0;
//
//   Map<int, List<LatLng>> _adFenceMap = {};
//   List<LatLng> _vehicleFence = [];
//   List<int> _activeRotationAds = [];
//   String _vehicleReg = "";
//
//   int _secondsLeft = 30;
//   static const int _rotationSeconds = 30;
//
//   late AnimationController _slideController;
//   late Animation<Offset> _slideAnimation;
//
//   // ───────── INIT ─────────
//   @override
//   void initState() {
//     super.initState();
//     _slideController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 400),
//     );
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
//
//     _loadData();
//   }
//
//   @override
//   void dispose() {
//     _moveTimer?.cancel();
//     _adRotateTimer?.cancel();
//     _countdownTimer?.cancel();
//     _slideController.dispose();
//     super.dispose();
//   }
//
//   // ───────── SAFE INT PARSE ─────────
//   // Handles backend returning adId as "23" (String) or 23 (int)
//   int _toInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     if (value is double) return value.toInt();
//     if (value is String) return int.tryParse(value) ?? 0;
//     return 0;
//   }
//
//   // ───────── PARSE POLYGON ─────────
//   // Handles both [{"lat":33.6,"lng":73.0}] and [[lng, lat]] GeoJSON formats
//   List<LatLng> _parsePolygon(dynamic raw) {
//     try {
//       List data;
//       if (raw is String) {
//         data = jsonDecode(raw) as List;
//       } else if (raw is List) {
//         data = raw;
//       } else {
//         debugPrint("Unknown polygon format: ${raw.runtimeType}");
//         return [];
//       }
//
//       if (data.isEmpty) return [];
//
//       // Format 1: [{"lat": 33.6, "lng": 73.0}, ...]
//       if (data.first is Map) {
//         return data.map<LatLng>((e) {
//           final map = e as Map;
//           final lat = (map['lat'] ?? map['latitude'] ?? 0) as num;
//           final lng = (map['lng'] ?? map['longitude'] ?? 0) as num;
//           return LatLng(lat.toDouble(), lng.toDouble());
//         }).toList();
//       }
//
//       // Format 2: [[lng, lat], ...] GeoJSON
//       if (data.first is List) {
//         return data.map<LatLng>((e) {
//           final arr = e as List;
//           return LatLng(
//             (arr[1] as num).toDouble(),
//             (arr[0] as num).toDouble(),
//           );
//         }).toList();
//       }
//
//       debugPrint("Unrecognized polygon element: ${data.first.runtimeType}");
//       return [];
//     } catch (e) {
//       debugPrint("Polygon parse error: $e  raw=$raw");
//       return [];
//     }
//   }
//
//   // ───────── CENTROID ─────────
//   LatLng _centroid(List<LatLng> polygon) {
//     double lat = 0, lng = 0;
//     for (final p in polygon) {
//       lat += p.latitude;
//       lng += p.longitude;
//     }
//     return LatLng(lat / polygon.length, lng / polygon.length);
//   }
//
//   // ───────── BUILD ROUTE ─────────
//   List<LatLng> _buildRoute(
//       List<LatLng> vehicleFence, Map<int, List<LatLng>> adFenceMap) {
//     final List<LatLng> points = [];
//
//     if (vehicleFence.isNotEmpty) {
//       points.add(_centroid(vehicleFence));
//     }
//
//     for (final poly in adFenceMap.values) {
//       if (poly.isNotEmpty) {
//         final center = _centroid(poly);
//         if (points.isNotEmpty) {
//           final prev = points.last;
//           points.add(LatLng(
//             prev.latitude + (center.latitude - prev.latitude) / 3,
//             prev.longitude + (center.longitude - prev.longitude) / 3,
//           ));
//           points.add(LatLng(
//             prev.latitude + 2 * (center.latitude - prev.latitude) / 3,
//             prev.longitude + 2 * (center.longitude - prev.longitude) / 3,
//           ));
//         }
//         points.add(center);
//       }
//     }
//
//     // One extra step past the last fence to exit it
//     if (points.length >= 2) {
//       final last = points.last;
//       final secondLast = points[points.length - 2];
//       points.add(LatLng(
//         last.latitude + (last.latitude - secondLast.latitude),
//         last.longitude + (last.longitude - secondLast.longitude),
//       ));
//     }
//
//     return points;
//   }
//
//   // ───────── LOAD DATA ─────────
//   Future<void> _loadData() async {
//     try {
//       // 1️⃣ Fetch all ads → filter active
//       final allAds = await AdApiService.fetchAds();
//       final activeAds =
//       allAds.where((a) => a.status.toLowerCase() == 'active').toList();
//
//       if (activeAds.isEmpty) {
//         setState(() {
//           _errorMessage = "No active ads found.";
//           _isLoading = false;
//         });
//         return;
//       }
//
//       debugPrint("Active ads: ${activeAds.map((a) => a.adId).toList()}");
//
//       // 2️⃣ Get assigned drivers for ALL active ads → distinct vehicleRegs
//       final Set<String> distinctVehicleRegs = {};
//
//       for (final ad in activeAds) {
//         try {
//           final adId = _toInt(ad.adId);
//           final assignments = await AdApiService.getAssignedDrivers(adId);
//           for (final a in assignments) {
//             final reg = a.vehicleReg?.trim() ?? '';
//             if (reg.isNotEmpty) distinctVehicleRegs.add(reg);
//           }
//         } catch (e) {
//           debugPrint("Assignments error for adId=${ad.adId}: $e");
//         }
//       }
//
//       if (distinctVehicleRegs.isEmpty) {
//         setState(() {
//           _errorMessage = "No vehicles assigned to active ads.";
//           _isLoading = false;
//         });
//         return;
//       }
//
//       final vehicleReg = distinctVehicleRegs.first;
//       debugPrint("Using vehicleReg: $vehicleReg");
//
//       // 3️⃣ Fetch vehicle fence
//       List<LatLng> vehicleFence = [];
//       try {
//         final vehFences =
//         await VehFenceApiService.getFenceByVehicle(vehicleReg);
//         debugPrint("VehFences count: ${vehFences.length}");
//         if (vehFences.isNotEmpty) {
//           vehicleFence = _parsePolygon(vehFences.first.polygon);
//           debugPrint("Vehicle fence points: ${vehicleFence.length}");
//         }
//       } catch (e) {
//         debugPrint("Vehicle fence error for $vehicleReg: $e");
//         // Non-fatal: simulation can proceed without vehicle fence polygon
//       }
//
//       // 4️⃣ Fetch ad fences for each active ad
//       final Map<int, List<LatLng>> adFenceMap = {};
//       final List<_QueuedAd> queue = [];
//
//       for (final ad in activeAds) {
//         try {
//           final adId = _toInt(ad.adId);
//           debugPrint("Fetching fence for adId=$adId");
//           final fences = await AdFenceApiService.getFenceByAd(adId);
//           debugPrint("  → fences count: ${fences.length}");
//
//           if (fences.isNotEmpty) {
//             final polygon = _parsePolygon(fences.first.polygon);
//             debugPrint("  → polygon points: ${polygon.length}");
//             if (polygon.isNotEmpty) {
//               adFenceMap[adId] = polygon;
//               queue.add(_QueuedAd(
//                 adId: adId,
//                 adTitle: ad.adTitle,
//                 mediaPath: ad.mediaPath,
//               ));
//             }
//           }
//         } catch (e) {
//           debugPrint("Ad fence error for adId=${ad.adId}: $e");
//         }
//       }
//
//       if (adFenceMap.isEmpty) {
//         setState(() {
//           _errorMessage = "No ad fences found for active ads.";
//           _isLoading = false;
//         });
//         return;
//       }
//
//       // 5️⃣ Build route through all fences
//       final route = _buildRoute(vehicleFence, adFenceMap);
//       debugPrint("Route length: ${route.length}");
//
//       if (route.length < 2) {
//         setState(() {
//           _errorMessage = "Could not build a valid route from fence data.";
//           _isLoading = false;
//         });
//         return;
//       }
//
//       setState(() {
//         _adQueue = queue;
//         _adFenceMap = adFenceMap;
//         _vehicleFence = vehicleFence;
//         _vehicleReg = vehicleReg;
//         _route = route;
//         _currentStep = 0;
//         _isLoading = false;
//       });
//     } catch (e) {
//       debugPrint("_loadData ERROR: $e");
//       setState(() {
//         _errorMessage = "Failed to load data: $e";
//         _isLoading = false;
//       });
//     }
//   }
//
//   // ───────── START / STOP ─────────
//   void _startSimulation() {
//     if (_isRunning || _route.isEmpty) return;
//     setState(() => _isRunning = true);
//
//     _moveTimer = Timer.periodic(const Duration(seconds: 4), (_) {
//       if (!mounted) return;
//       setState(() {
//         _currentStep = (_currentStep + 1) % _route.length;
//       });
//       _checkZones();
//       _animateCamera();
//     });
//   }
//
//   void _stopSimulation() {
//     setState(() => _isRunning = false);
//     _moveTimer?.cancel();
//     _stopAdRotation();
//     _moveTimer = null;
//   }
//
//   // ───────── GEO LOGIC ─────────
//   bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
//     if (polygon.length < 3) return false;
//     int intersectCount = 0;
//     final int n = polygon.length;
//     for (int j = 0; j < n; j++) {
//       final a = polygon[j];
//       final b = polygon[(j + 1) % n];
//       if (((a.longitude > point.longitude) !=
//           (b.longitude > point.longitude)) &&
//           (point.latitude <
//               (b.latitude - a.latitude) *
//                   (point.longitude - a.longitude) /
//                   (b.longitude - a.longitude) +
//                   a.latitude)) {
//         intersectCount++;
//       }
//     }
//     return (intersectCount % 2) == 1;
//   }
//
//   void _checkZones() {
//     if (!mounted) return;
//     final pos = _carPosition;
//
//     final List<int> activeAdIds = [];
//     _adFenceMap.forEach((adId, polygon) {
//       if (_isPointInPolygon(pos, polygon)) activeAdIds.add(adId);
//     });
//
//     if (activeAdIds.length > 1) {
//       if (!_inOverlapZone) {
//         setState(() => _inOverlapZone = true);
//         _startAdRotation(activeAdIds);
//         _slideController.forward(from: 0);
//       }
//     } else {
//       if (_inOverlapZone) {
//         setState(() => _inOverlapZone = false);
//         _stopAdRotation();
//         _slideController.reverse();
//       }
//       if (activeAdIds.isNotEmpty) {
//         final index = _adQueue.indexWhere((a) => a.adId == activeAdIds.first);
//         if (index != -1 && mounted) setState(() => _currentAdIndex = index);
//       }
//     }
//   }
//
//   // ───────── ROTATION ─────────
//   void _startAdRotation(List<int> adIds) {
//     _activeRotationAds = List.from(adIds);
//     _stopAdRotation();
//     setState(() => _secondsLeft = _rotationSeconds);
//
//     _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (!mounted) return;
//       setState(() {
//         _secondsLeft--;
//         if (_secondsLeft <= 0) _secondsLeft = _rotationSeconds;
//       });
//     });
//
//     _adRotateTimer =
//         Timer.periodic(const Duration(seconds: _rotationSeconds), (_) {
//           if (!mounted || _activeRotationAds.isEmpty) return;
//           final currentAdId = _adQueue[_currentAdIndex].adId;
//           final currentIdx = _activeRotationAds.indexOf(currentAdId);
//           final nextIdx = (currentIdx + 1) % _activeRotationAds.length;
//           final nextAdId = _activeRotationAds[nextIdx];
//           final queueIndex = _adQueue.indexWhere((a) => a.adId == nextAdId);
//           if (queueIndex != -1) {
//             setState(() {
//               _currentAdIndex = queueIndex;
//               _secondsLeft = _rotationSeconds;
//             });
//             _slideController.forward(from: 0);
//           }
//         });
//   }
//
//   void _stopAdRotation() {
//     _adRotateTimer?.cancel();
//     _countdownTimer?.cancel();
//     _adRotateTimer = null;
//     _countdownTimer = null;
//   }
//
//   void _animateCamera() {
//     _mapController?.animateCamera(CameraUpdate.newLatLng(_carPosition));
//   }
//
//   // ───────── MAP BUILDERS ─────────
//   Set<Marker> _buildMarkers() => {
//     Marker(
//       markerId: const MarkerId("car"),
//       position: _carPosition,
//       icon: BitmapDescriptor.defaultMarkerWithHue(
//           BitmapDescriptor.hueAzure),
//       infoWindow: InfoWindow(
//         title: _vehicleReg,
//         snippet: _inOverlapZone ? "In overlap zone" : "Driving",
//       ),
//     ),
//   };
//
//   Set<Polyline> _buildPolylines() {
//     if (_route.isEmpty) return {};
//     return {
//       Polyline(
//         polylineId: const PolylineId("route"),
//         points: _route,
//         color: Colors.blue.withOpacity(0.4),
//         width: 4,
//         patterns: [PatternItem.dash(20), PatternItem.gap(10)],
//       ),
//       if (_currentStep > 0)
//         Polyline(
//           polylineId: const PolylineId("driven"),
//           points: _route.sublist(0, _currentStep + 1),
//           color: const Color(0xff18B6A3),
//           width: 5,
//         ),
//     };
//   }
//
//   Set<Polygon> _buildPolygons() {
//     final Set<Polygon> polygons = {};
//     if (_vehicleFence.isNotEmpty) {
//       polygons.add(Polygon(
//         polygonId: const PolygonId("vehicle"),
//         points: _vehicleFence,
//         strokeColor: Colors.green,
//         strokeWidth: 2,
//         fillColor: Colors.green.withOpacity(0.1),
//       ));
//     }
//     final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.red];
//     int idx = 0;
//     _adFenceMap.forEach((id, poly) {
//       final color = colors[(idx++) % colors.length];
//       polygons.add(Polygon(
//         polygonId: PolygonId("ad_$id"),
//         points: poly,
//         strokeColor: color,
//         strokeWidth: 2,
//         fillColor: color.withOpacity(0.12),
//       ));
//     });
//     return polygons;
//   }
//
//   // ───────── LEGEND ─────────
//   Widget _buildLegend() {
//     final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.red];
//     int i = 0;
//     return Container(
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.93),
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _legendRow(Colors.green, "Vehicle Fence"),
//           ..._adFenceMap.keys.map((id) {
//             final color = colors[(i++) % colors.length];
//             final ad = _adQueue.firstWhere((a) => a.adId == id,
//                 orElse: () =>
//                     _QueuedAd(adId: id, adTitle: "Ad $id", mediaPath: ""));
//             return Padding(
//               padding: const EdgeInsets.only(top: 4),
//               child: _legendRow(color, ad.adTitle),
//             );
//           }),
//         ],
//       ),
//     );
//   }
//
//   Widget _legendRow(Color color, String label) => Row(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       Container(
//         width: 14,
//         height: 14,
//         decoration: BoxDecoration(
//             color: color, borderRadius: BorderRadius.circular(3)),
//       ),
//       const SizedBox(width: 6),
//       Text(label, style: const TextStyle(fontSize: 11)),
//     ],
//   );
//
//   // ───────── BOTTOM PANEL ─────────
//   Widget _buildBottomPanel() {
//     if (!_inOverlapZone || _adQueue.isEmpty) {
//       return Container(
//         margin: const EdgeInsets.all(12),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
//         ),
//         child: Row(
//           children: [
//             const Icon(Icons.directions_car,
//                 color: Color(0xff18B6A3), size: 28),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     _vehicleReg.isNotEmpty ? _vehicleReg : "Vehicle",
//                     style: const TextStyle(
//                         fontWeight: FontWeight.bold, fontSize: 15),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     "Step ${_currentStep + 1} / ${_route.length}  •  "
//                         "${_isRunning ? 'Driving' : 'Stopped'}",
//                     style: const TextStyle(
//                         fontSize: 12, color: Colors.black54),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//               padding:
//               const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 color: _isRunning
//                     ? Colors.green.withOpacity(0.1)
//                     : Colors.grey.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(
//                     color: _isRunning ? Colors.green : Colors.grey),
//               ),
//               child: Text(
//                 _isRunning ? "Running" : "Idle",
//                 style: TextStyle(
//                     color: _isRunning ? Colors.green : Colors.grey,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     final currentAd = _adQueue[_currentAdIndex];
//     final queueLength = _adQueue.length;
//
//     return SlideTransition(
//       position: _slideAnimation,
//       child: Container(
//         margin: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: const [
//             BoxShadow(color: Colors.black26, blurRadius: 8)
//           ],
//           border: Border.all(
//               color: const Color(0xff18B6A3).withOpacity(0.5), width: 1.5),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Header
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(
//                   vertical: 8, horizontal: 14),
//               decoration: const BoxDecoration(
//                 color: Color(0xffffe0e0),
//                 borderRadius:
//                 BorderRadius.vertical(top: Radius.circular(16)),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.warning_amber_rounded,
//                       color: Colors.red, size: 18),
//                   const SizedBox(width: 6),
//                   const Expanded(
//                     child: Text(
//                       "Overlap Zone — Ad Queue Active",
//                       style: TextStyle(
//                           color: Colors.red,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 13),
//                     ),
//                   ),
//                   Text(
//                     "${_currentAdIndex + 1} / $queueLength",
//                     style: const TextStyle(
//                         fontSize: 12, color: Colors.black54),
//                   ),
//                 ],
//               ),
//             ),
//             // Ad content
//             Padding(
//               padding: const EdgeInsets.all(12),
//               child: Row(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: Image.network(
//                       currentAd.mediaPath,
//                       width: 70,
//                       height: 70,
//                       fit: BoxFit.cover,
//                       errorBuilder: (_, __, ___) => Container(
//                         width: 70,
//                         height: 70,
//                         color: Colors.grey[200],
//                         child: const Icon(Icons.campaign, size: 32),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text("Now Displaying",
//                             style: TextStyle(
//                                 fontSize: 11, color: Colors.grey[500])),
//                         const SizedBox(height: 2),
//                         Text(
//                           currentAd.adTitle,
//                           style: const TextStyle(
//                               fontSize: 15, fontWeight: FontWeight.bold),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 6),
//                         Row(
//                           children: [
//                             const Icon(Icons.timer,
//                                 size: 14, color: Color(0xff18B6A3)),
//                             const SizedBox(width: 4),
//                             Text(
//                               "Next ad in $_secondsLeft sec",
//                               style: const TextStyle(
//                                   fontSize: 12,
//                                   color: Color(0xff18B6A3)),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // Queue dots
//             if (queueLength > 1)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: List.generate(queueLength, (i) {
//                     return AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       margin:
//                       const EdgeInsets.symmetric(horizontal: 4),
//                       width: i == _currentAdIndex ? 20 : 8,
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: i == _currentAdIndex
//                             ? const Color(0xff18B6A3)
//                             : Colors.grey[300],
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     );
//                   }),
//                 ),
//               ),
//             // Progress bar
//             Padding(
//               padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(4),
//                 child: LinearProgressIndicator(
//                   value: _secondsLeft / _rotationSeconds,
//                   backgroundColor: Colors.grey[200],
//                   color: const Color(0xff18B6A3),
//                   minHeight: 5,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ───────── BUILD ─────────
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//           body: Center(child: CircularProgressIndicator()));
//     }
//
//     if (_errorMessage != null) {
//       return Scaffold(
//         appBar: AppBar(
//           backgroundColor: const Color(0xff18B6A3),
//           title: const Text("Ad Simulation",
//               style: TextStyle(color: Colors.black)),
//         ),
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(Icons.error_outline,
//                     color: Colors.red, size: 48),
//                 const SizedBox(height: 16),
//                 Text(_errorMessage!,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(fontSize: 15)),
//                 const SizedBox(height: 24),
//                 ElevatedButton(
//                   onPressed: () => setState(() {
//                     _isLoading = true;
//                     _errorMessage = null;
//                     _loadData();
//                   }),
//                   child: const Text("Retry"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xff18B6A3),
//         leading: const BackButton(color: Colors.black),
//         title: const Text("Ad Simulation",
//             style: TextStyle(color: Colors.black)),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 14),
//             child: Center(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 10, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: _inOverlapZone ? Colors.red : Colors.green,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   _inOverlapZone ? "OVERLAP ZONE" : "Single Zone",
//                   style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 11,
//                       fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition:
//             CameraPosition(target: _carPosition, zoom: 14),
//             onMapCreated: (ctrl) => _mapController = ctrl,
//             markers: _buildMarkers(),
//             polylines: _buildPolylines(),
//             polygons: _buildPolygons(),
//             myLocationEnabled: false,
//             zoomControlsEnabled: true,
//           ),
//           Positioned(top: 12, left: 12, child: _buildLegend()),
//           Positioned(
//             top: 12,
//             right: 12,
//             child: Column(
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: _isRunning ? null : _startSimulation,
//                   icon: const Icon(Icons.play_arrow),
//                   label: const Text("Start"),
//                   style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xff18B6A3),
//                       foregroundColor: Colors.white),
//                 ),
//                 const SizedBox(height: 8),
//                 ElevatedButton.icon(
//                   onPressed: _isRunning ? _stopSimulation : null,
//                   icon: const Icon(Icons.stop),
//                   label: const Text("Stop"),
//                   style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                       foregroundColor: Colors.white),
//                 ),
//               ],
//             ),
//           ),
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: _buildBottomPanel(),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/AdApiService.dart';
import '../../services/AdFenceApiService.dart';
import '../../services/VehFenceApiService.dart';

// ───────── AD MODEL ─────────
class _QueuedAd {
  final int adId;
  final String adTitle;
  final String mediaPath;

  _QueuedAd({
    required this.adId,
    required this.adTitle,
    required this.mediaPath,
  });
}

class AdSimulationScreen extends StatefulWidget {
  const AdSimulationScreen({super.key});

  @override
  State<AdSimulationScreen> createState() => _AdSimulationScreenState();
}

class _AdSimulationScreenState extends State<AdSimulationScreen>
    with TickerProviderStateMixin {

  GoogleMapController? _mapController;

  // ───────── STATE ─────────
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRunning = false;
  bool _inOverlapZone = false;

  List<LatLng> _route = [];
  int _currentStep = 0;

  LatLng get _carPosition => _route[_currentStep];

  Timer? _moveTimer;
  Timer? _adRotateTimer;
  Timer? _countdownTimer;

  List<_QueuedAd> _adQueue = [];
  int _currentAdIndex = 0;

  Map<int, List<LatLng>> _adFenceMap = {};
  List<LatLng> _vehicleFence = [];
  List<int> _activeRotationAds = [];
  String _vehicleReg = "";

  // ── Changed to 3 seconds ──
  int _secondsLeft = 3;
  static const int _rotationSeconds = 3;

  BitmapDescriptor? _carIcon;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // ───────── INIT ─────────
  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _loadCarIcon().then((_) => _loadData());
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _adRotateTimer?.cancel();
    _countdownTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  // ───────── CAR ICON ─────────
  // Draws a car emoji / SVG-style icon as a BitmapDescriptor
  Future<void> _loadCarIcon() async {
    try {
      // Try to load from assets first (add assets/icons/car.png to pubspec if you have one)
      // _carIcon = await BitmapDescriptor.fromAssetImage(
      //   const ImageConfiguration(size: Size(48, 48)),
      //   'assets/icons/car.png',
      // );

      // Fallback: draw a custom car shape programmatically
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      const double size = 80;

      // Shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(6, 12, size - 12, size - 20),
          const Radius.circular(14),
        ),
        shadowPaint,
      );

      // Car body
      final bodyPaint = Paint()..color = const Color(0xff18B6A3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(4, 8, size - 8, size - 18),
          const Radius.circular(12),
        ),
        bodyPaint,
      );

      // Roof / cabin
      final roofPaint = Paint()..color = const Color(0xff0d8c7c);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(14, 4, size - 28, 28),
          const Radius.circular(8),
        ),
        roofPaint,
      );

      // Windshield
      final glassPaint = Paint()..color = Colors.white.withOpacity(0.85);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(17, 6, size - 34, 22),
          const Radius.circular(5),
        ),
        glassPaint,
      );

      // Wheels
      final wheelPaint = Paint()..color = const Color(0xff1a1a2e);
      // front-left
      canvas.drawCircle(const Offset(16, size - 10), 9, wheelPaint);
      // front-right
      canvas.drawCircle(Offset(size - 16, size - 10), 9, wheelPaint);

      // Wheel rims
      final rimPaint = Paint()..color = Colors.white54;
      canvas.drawCircle(const Offset(16, size - 10), 4, rimPaint);
      canvas.drawCircle(Offset(size - 16, size - 10), 4, rimPaint);

      // Headlights
      final lightPaint = Paint()..color = Colors.yellow[200]!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(6, 10, 10, 5),
          const Radius.circular(2),
        ),
        lightPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size - 16, 10, 10, 5),
          const Radius.circular(2),
        ),
        lightPaint,
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final ByteData? byteData =
      await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        _carIcon = BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint("Car icon error: $e");
      // Falls back to default marker if icon fails
    }
  }

  // ───────── SAFE INT PARSE ─────────
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ───────── PARSE POLYGON ─────────
  List<LatLng> _parsePolygon(dynamic raw) {
    try {
      List data;
      if (raw is String) {
        data = jsonDecode(raw) as List;
      } else if (raw is List) {
        data = raw;
      } else {
        debugPrint("Unknown polygon format: ${raw.runtimeType}");
        return [];
      }

      if (data.isEmpty) return [];

      if (data.first is Map) {
        return data.map<LatLng>((e) {
          final map = e as Map;
          final lat = (map['lat'] ?? map['latitude'] ?? 0) as num;
          final lng = (map['lng'] ?? map['longitude'] ?? 0) as num;
          return LatLng(lat.toDouble(), lng.toDouble());
        }).toList();
      }

      if (data.first is List) {
        return data.map<LatLng>((e) {
          final arr = e as List;
          return LatLng(
            (arr[1] as num).toDouble(),
            (arr[0] as num).toDouble(),
          );
        }).toList();
      }

      debugPrint("Unrecognized polygon element: ${data.first.runtimeType}");
      return [];
    } catch (e) {
      debugPrint("Polygon parse error: $e  raw=$raw");
      return [];
    }
  }

  // ───────── CENTROID ─────────
  LatLng _centroid(List<LatLng> polygon) {
    double lat = 0, lng = 0;
    for (final p in polygon) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / polygon.length, lng / polygon.length);
  }

  // ───────── BUILD ROUTE ─────────
  List<LatLng> _buildRoute(
      List<LatLng> vehicleFence, Map<int, List<LatLng>> adFenceMap) {
    final List<LatLng> points = [];

    if (vehicleFence.isNotEmpty) {
      points.add(_centroid(vehicleFence));
    }

    for (final poly in adFenceMap.values) {
      if (poly.isNotEmpty) {
        final center = _centroid(poly);
        if (points.isNotEmpty) {
          final prev = points.last;
          points.add(LatLng(
            prev.latitude + (center.latitude - prev.latitude) / 3,
            prev.longitude + (center.longitude - prev.longitude) / 3,
          ));
          points.add(LatLng(
            prev.latitude + 2 * (center.latitude - prev.latitude) / 3,
            prev.longitude + 2 * (center.longitude - prev.longitude) / 3,
          ));
        }
        points.add(center);
      }
    }

    if (points.length >= 2) {
      final last = points.last;
      final secondLast = points[points.length - 2];
      points.add(LatLng(
        last.latitude + (last.latitude - secondLast.latitude),
        last.longitude + (last.longitude - secondLast.longitude),
      ));
    }

    return points;
  }

  // ───────── LOAD DATA ─────────
  Future<void> _loadData() async {
    try {
      final allAds = await AdApiService.fetchAds();
      final activeAds =
      allAds.where((a) => a.status.toLowerCase() == 'active').toList();

      if (activeAds.isEmpty) {
        setState(() {
          _errorMessage = "No active ads found.";
          _isLoading = false;
        });
        return;
      }

      debugPrint("Active ads: ${activeAds.map((a) => a.adId).toList()}");

      final Set<String> distinctVehicleRegs = {};
      for (final ad in activeAds) {
        try {
          final adId = _toInt(ad.adId);
          final assignments = await AdApiService.getAssignedDrivers(adId);
          for (final a in assignments) {
            final reg = a.vehicleReg?.trim() ?? '';
            if (reg.isNotEmpty) distinctVehicleRegs.add(reg);
          }
        } catch (e) {
          debugPrint("Assignments error for adId=${ad.adId}: $e");
        }
      }

      if (distinctVehicleRegs.isEmpty) {
        setState(() {
          _errorMessage = "No vehicles assigned to active ads.";
          _isLoading = false;
        });
        return;
      }

      final vehicleReg = distinctVehicleRegs.first;
      debugPrint("Using vehicleReg: $vehicleReg");

      // ── Fetch vehicle fence with detailed logging ──
      List<LatLng> vehicleFence = [];
      try {
        final vehFences =
        await VehFenceApiService.getFenceByVehicle(vehicleReg);
        debugPrint("VehFences count: ${vehFences.length}");
        if (vehFences.isNotEmpty) {
          debugPrint(
              "VehFence[0] polygon raw: ${vehFences.first.polygon}");
          vehicleFence = _parsePolygon(vehFences.first.polygon);
          debugPrint("Vehicle fence points: ${vehicleFence.length}");
        } else {
          debugPrint("No vehicle fences returned for $vehicleReg");
        }
      } catch (e) {
        debugPrint("Vehicle fence error for $vehicleReg: $e");
      }

      // ── Fetch ad fences ──
      final Map<int, List<LatLng>> adFenceMap = {};
      final List<_QueuedAd> queue = [];

      for (final ad in activeAds) {
        try {
          final adId = _toInt(ad.adId);
          debugPrint("Fetching fence for adId=$adId");
          final fences = await AdFenceApiService.getFenceByAd(adId);
          debugPrint("  → fences count: ${fences.length}");

          if (fences.isNotEmpty) {
            debugPrint("  → polygon raw: ${fences.first.polygon}");
            final polygon = _parsePolygon(fences.first.polygon);
            debugPrint("  → polygon points: ${polygon.length}");
            if (polygon.isNotEmpty) {
              adFenceMap[adId] = polygon;
              queue.add(_QueuedAd(
                adId: adId,
                adTitle: ad.adTitle,
                mediaPath: ad.mediaPath,
              ));
            }
          }
        } catch (e) {
          debugPrint("Ad fence error for adId=${ad.adId}: $e");
        }
      }

      if (adFenceMap.isEmpty) {
        setState(() {
          _errorMessage = "No ad fences found for active ads.";
          _isLoading = false;
        });
        return;
      }

      final route = _buildRoute(vehicleFence, adFenceMap);
      debugPrint("Route length: ${route.length}");

      if (route.length < 2) {
        setState(() {
          _errorMessage = "Could not build a valid route from fence data.";
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _adQueue = queue;
        _adFenceMap = adFenceMap;
        _vehicleFence = vehicleFence;
        _vehicleReg = vehicleReg;
        _route = route;
        _currentStep = 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("_loadData ERROR: $e");
      setState(() {
        _errorMessage = "Failed to load data: $e";
        _isLoading = false;
      });
    }
  }

  // ───────── START / STOP ─────────
  void _startSimulation() {
    if (_isRunning || _route.isEmpty) return;
    setState(() => _isRunning = true);

    _moveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _currentStep = (_currentStep + 1) % _route.length;
      });
      _checkZones();
      _animateCamera();
    });
  }

  void _stopSimulation() {
    setState(() => _isRunning = false);
    _moveTimer?.cancel();
    _stopAdRotation();
    _moveTimer = null;
  }

  // ───────── GEO LOGIC ─────────
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    int intersectCount = 0;
    final int n = polygon.length;
    for (int j = 0; j < n; j++) {
      final a = polygon[j];
      final b = polygon[(j + 1) % n];
      if (((a.longitude > point.longitude) !=
          (b.longitude > point.longitude)) &&
          (point.latitude <
              (b.latitude - a.latitude) *
                  (point.longitude - a.longitude) /
                  (b.longitude - a.longitude) +
                  a.latitude)) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }

  void _checkZones() {
    if (!mounted) return;
    final pos = _carPosition;

    final List<int> activeAdIds = [];
    _adFenceMap.forEach((adId, polygon) {
      if (_isPointInPolygon(pos, polygon)) activeAdIds.add(adId);
    });

    if (activeAdIds.length > 1) {
      if (!_inOverlapZone) {
        setState(() => _inOverlapZone = true);
        _startAdRotation(activeAdIds);
        _slideController.forward(from: 0);
      }
    } else {
      if (_inOverlapZone) {
        setState(() => _inOverlapZone = false);
        _stopAdRotation();
        _slideController.reverse();
      }
      if (activeAdIds.isNotEmpty) {
        final index = _adQueue.indexWhere((a) => a.adId == activeAdIds.first);
        if (index != -1 && mounted) setState(() => _currentAdIndex = index);
      }
    }
  }

  // ───────── ROTATION (3 seconds) ─────────
  void _startAdRotation(List<int> adIds) {
    _activeRotationAds = List.from(adIds);
    _stopAdRotation();
    setState(() => _secondsLeft = _rotationSeconds);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) _secondsLeft = _rotationSeconds;
      });
    });

    _adRotateTimer =
        Timer.periodic(const Duration(seconds: _rotationSeconds), (_) {
          if (!mounted || _activeRotationAds.isEmpty) return;
          final currentAdId = _adQueue[_currentAdIndex].adId;
          final currentIdx = _activeRotationAds.indexOf(currentAdId);
          final nextIdx = (currentIdx + 1) % _activeRotationAds.length;
          final nextAdId = _activeRotationAds[nextIdx];
          final queueIndex = _adQueue.indexWhere((a) => a.adId == nextAdId);
          if (queueIndex != -1) {
            setState(() {
              _currentAdIndex = queueIndex;
              _secondsLeft = _rotationSeconds;
            });
            _slideController.forward(from: 0);
          }
        });
  }

  void _stopAdRotation() {
    _adRotateTimer?.cancel();
    _countdownTimer?.cancel();
    _adRotateTimer = null;
    _countdownTimer = null;
  }

  void _animateCamera() {
    _mapController?.animateCamera(CameraUpdate.newLatLng(_carPosition));
  }

  // ───────── MAP BUILDERS ─────────
  Set<Marker> _buildMarkers() => {
    Marker(
      markerId: const MarkerId("car"),
      position: _carPosition,
      // Use custom car icon; fallback to azure default if not loaded
      icon: _carIcon ??
          BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure),
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(
        title: _vehicleReg,
        snippet: _inOverlapZone ? "In overlap zone" : "Driving",
      ),
    ),
  };

  Set<Polyline> _buildPolylines() {
    if (_route.isEmpty) return {};
    return {
      Polyline(
        polylineId: const PolylineId("route"),
        points: _route,
        color: Colors.blue.withOpacity(0.4),
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
      if (_currentStep > 0)
        Polyline(
          polylineId: const PolylineId("driven"),
          points: _route.sublist(0, _currentStep + 1),
          color: const Color(0xff18B6A3),
          width: 5,
        ),
    };
  }

  Set<Polygon> _buildPolygons() {
    final Set<Polygon> polygons = {};

    // ── Vehicle fence — green ──
    if (_vehicleFence.isNotEmpty) {
      polygons.add(Polygon(
        polygonId: const PolygonId("vehicle"),
        points: _vehicleFence,
        strokeColor: Colors.green,
        strokeWidth: 3,
        fillColor: Colors.green.withOpacity(0.15),
      ));
    } else {
      debugPrint(
          "⚠️ _vehicleFence is empty — vehicle fence polygon will not be drawn");
    }

    // ── Ad fences ──
    final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.red];
    int idx = 0;
    _adFenceMap.forEach((id, poly) {
      final color = colors[(idx++) % colors.length];
      polygons.add(Polygon(
        polygonId: PolygonId("ad_$id"),
        points: poly,
        strokeColor: color,
        strokeWidth: 2,
        fillColor: color.withOpacity(0.12),
      ));
    });
    return polygons;
  }

  // ───────── LEGEND ─────────
  Widget _buildLegend() {
    final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.red];
    int i = 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Always show vehicle fence in legend, greyed if not loaded
          _legendRow(
            Colors.green,
            "Vehicle Fence${_vehicleFence.isEmpty ? ' (not loaded)' : ''}",
          ),
          ..._adFenceMap.keys.map((id) {
            final color = colors[(i++) % colors.length];
            final ad = _adQueue.firstWhere(
                  (a) => a.adId == id,
              orElse: () =>
                  _QueuedAd(adId: id, adTitle: "Ad $id", mediaPath: ""),
            );
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _legendRow(color, ad.adTitle),
            );
          }),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(3)),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(fontSize: 11, color: Colors.black87)),
    ],
  );

  // ───────── BOTTOM PANEL ─────────
  Widget _buildBottomPanel() {
    // ── Normal driving panel (no overlap) ──
    if (!_inOverlapZone || _adQueue.isEmpty) {
      // Show current ad image even outside overlap if we know which ad is active
      final bool hasActiveAd = _adQueue.isNotEmpty &&
          _currentAdIndex >= 0 &&
          _currentAdIndex < _adQueue.length;

      return Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Vehicle status row ──
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.directions_car,
                      color: Color(0xff18B6A3), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _vehicleReg.isNotEmpty ? _vehicleReg : "Vehicle",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Step ${_currentStep + 1} / ${_route.length}  •  "
                              "${_isRunning ? 'Driving' : 'Stopped'}",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isRunning
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _isRunning ? Colors.green : Colors.grey),
                    ),
                    child: Text(
                      _isRunning ? "Running" : "Idle",
                      style: TextStyle(
                          color: _isRunning ? Colors.green : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // ── Ad image preview box ──
            if (hasActiveAd) ...[
              const Divider(height: 1),
              _buildAdImageBox(_adQueue[_currentAdIndex], isOverlap: false),
            ],
          ],
        ),
      );
    }

    // ── Overlap zone panel ──
    final currentAd = _adQueue[_currentAdIndex];
    final queueLength = _adQueue.length;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8)
          ],
          border: Border.all(
              color: const Color(0xff18B6A3).withOpacity(0.5), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: const BoxDecoration(
                color: Color(0xffffe0e0),
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 18),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      "Overlap Zone — Ad Queue Active",
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                  Text(
                    "${_currentAdIndex + 1} / $queueLength",
                    style:
                    const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),

            // ── Ad image box (large) + info ──
            _buildAdImageBox(currentAd, isOverlap: true),

            // Queue dots
            if (queueLength > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(queueLength, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentAdIndex ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _currentAdIndex
                            ? const Color(0xff18B6A3)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _secondsLeft / _rotationSeconds,
                  backgroundColor: Colors.grey[200],
                  color: const Color(0xff18B6A3),
                  minHeight: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────── AD IMAGE BOX ─────────
  // Reusable widget that displays the ad media image from Cloudinary URL
  Widget _buildAdImageBox(_QueuedAd ad, {required bool isOverlap}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image box ──
          Container(
            width: isOverlap ? 90 : 72,
            height: isOverlap ? 90 : 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xff18B6A3).withOpacity(0.4), width: 1.5),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ad.mediaPath.isNotEmpty
                  ? Image.network(
                ad.mediaPath,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: const Color(0xff18B6A3),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.broken_image,
                        color: Colors.grey, size: 28),
                    SizedBox(height: 4),
                    Text("No image",
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey)),
                  ],
                ),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.campaign, color: Colors.grey, size: 28),
                  SizedBox(height: 4),
                  Text("No URL",
                      style:
                      TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ── Ad info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverlap ? "Now Displaying" : "Active Ad",
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  ad.adTitle,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // URL preview
                Text(
                  ad.mediaPath.isNotEmpty ? ad.mediaPath : "No media URL",
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isOverlap) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timer,
                          size: 14, color: Color(0xff18B6A3)),
                      const SizedBox(width: 4),
                      Text(
                        "Next ad in $_secondsLeft sec",
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xff18B6A3)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────── BUILD ─────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff18B6A3),
          title: const Text("Ad Simulation",
              style: TextStyle(color: Colors.black)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(_errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                    _loadData();
                  }),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff18B6A3),
        leading: const BackButton(color: Colors.black),
        title: const Text("Ad Simulation",
            style: TextStyle(color: Colors.black)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _inOverlapZone ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _inOverlapZone ? "OVERLAP ZONE" : "Single Zone",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
            CameraPosition(target: _carPosition, zoom: 14),
            onMapCreated: (ctrl) => _mapController = ctrl,
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            polygons: _buildPolygons(),
            myLocationEnabled: false,
            zoomControlsEnabled: true,
          ),
          Positioned(top: 12, left: 12, child: _buildLegend()),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _startSimulation,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Start"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff18B6A3),
                      foregroundColor: Colors.white),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isRunning ? _stopSimulation : null,
                  icon: const Icon(Icons.stop),
                  label: const Text("Stop"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }
}