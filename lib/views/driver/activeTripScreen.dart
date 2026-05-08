// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import '../../models/activityFeedItem.dart';
// import '../../models/gpsModels.dart';
// import '../../services/VehicleApiService.dart';
// import '../../services/autoAssignApiService.dart';
// import '../../services/gpsService.dart';
//
// class ActiveTripScreen extends StatefulWidget {
//   final String vehicleReg;
//   final int    userId;
//
//   const ActiveTripScreen({
//     super.key,
//     required this.vehicleReg,
//     required this.userId,
//   });
//
//   @override
//   State<ActiveTripScreen> createState() => _ActiveTripScreenState();
// }
//
// class _ActiveTripScreenState extends State<ActiveTripScreen> {
//   List<ActivityFeedItem> _ads = [];
//   int _currentAdIndex = 0;
//
//   bool _loading    = true;
//   String? _loadError;
//   bool _tripActive = false;
//
//   Position? _lastPosition;
//   String?   _validationWarning;
//
//   // live stats (from DailyTrip, refreshed after each valid ping)
//   double _todayDistanceKm    = 0;
//   double _todayTimeMinutes   = 0;
//   int    _todaySegments      = 0;
//
//   Timer? _rotationTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadAds();
//   }
//
//   @override
//   void dispose() {
//     GpsService.instance.stopPinging();
//     _rotationTimer?.cancel();
//     super.dispose();
//   }
//
//   // ── Load this vehicle's active assigned ads ─────────────────────────────────
//   Future<void> _loadAds() async {
//     setState(() { _loading = true; _loadError = null; });
//     try {
//       final all = await AutoAssignApiService.getActivityFeedForVehicle(
//           widget.vehicleReg);
//       setState(() { _ads = all; _loading = false; });
//       if (all.isNotEmpty) _refreshTripStats();
//     } catch (e) {
//       setState(() { _loadError = e.toString(); _loading = false; });
//     }
//   }
//
//   // ── Refresh trip stats from backend ────────────────────────────────────────
//   Future<void> _refreshTripStats() async {
//     if (_ads.isEmpty) return;
//     try {
//       final stats = await VehicleApiService.getTodayTripStats(
//         vehicleReg: widget.vehicleReg,
//         adId:       _ads[_currentAdIndex].adId,
//       );
//       if (!mounted) return;
//       setState(() {
//         _todayDistanceKm  = stats.validDistanceKm;
//         _todayTimeMinutes = stats.validTimeMinutes;
//         _todaySegments    = stats.segmentsCount;
//       });
//     } catch (_) {}
//   }
//
//   // ── Go Online ───────────────────────────────────────────────────────────────
//   void _goOnline() {
//     if (_ads.isEmpty) { _snack('No active ads for this vehicle.'); return; }
//
//     setState(() { _tripActive = true; _validationWarning = null; });
//
//     // Rotate ads every 60 seconds
//     _rotationTimer = Timer.periodic(const Duration(seconds: 60), (_) {
//       if (_ads.length > 1) {
//         setState(() {
//           _currentAdIndex = (_currentAdIndex + 1) % _ads.length;
//           _validationWarning = null;
//         });
//         _refreshTripStats();
//       }
//     });
//
//     // GPS ping every 30 seconds
//     GpsService.instance.startPinging(
//       intervalSeconds: 30,
//       onPing: _handlePing,
//       onError: (e) => setState(() => _validationWarning = 'GPS error: $e'),
//     );
//   }
//
//   // ── Go Offline ──────────────────────────────────────────────────────────────
//   void _goOffline() {
//     GpsService.instance.stopPinging();
//     _rotationTimer?.cancel();
//     setState(() {
//       _tripActive        = false;
//       _validationWarning = null;
//       _lastPosition      = null;
//     });
//   }
//
//   // ── Handle ping result ──────────────────────────────────────────────────────
//   Future<void> _handlePing(Position pos) async {
//     if (!mounted) return;
//     setState(() => _lastPosition = pos);
//     if (_ads.isEmpty) return;
//
//     try {
//       final result = await VehicleApiService.sendTripPing(
//         GpsPingRequest(
//           vehicleReg: widget.vehicleReg,
//           userId:     widget.userId,
//           adId:       _ads[_currentAdIndex].adId,
//           latitude:   pos.latitude,
//           longitude:  pos.longitude,
//         ),
//       );
//
//       if (!mounted) return;
//       setState(() => _validationWarning = result.valid ? null : result.reason);
//
//       // Refresh live stats on every valid ping
//       if (result.valid) _refreshTripStats();
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _validationWarning = 'Ping failed: $e');
//     }
//   }
//
//   void _snack(String msg) =>
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//
//   // ── BUILD ───────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xfff5f6fa),
//       appBar: AppBar(
//         backgroundColor: const Color(0xff18B6A3),
//         elevation: 0,
//         title: Text(widget.vehicleReg,
//             style: const TextStyle(
//                 color: Colors.black, fontWeight: FontWeight.bold)),
//         iconTheme: const IconThemeData(color: Colors.black),
//         actions: [
//           if (_tripActive)
//             Padding(
//               padding: const EdgeInsets.only(right: 16),
//               child: Row(children: [
//                 Container(
//                   width: 8, height: 8,
//                   decoration: const BoxDecoration(
//                       color: Colors.greenAccent, shape: BoxShape.circle),
//                 ),
//                 const SizedBox(width: 5),
//                 const Text('LIVE',
//                     style: TextStyle(
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 12)),
//               ]),
//             ),
//         ],
//       ),
//       body: _loading
//           ? const Center(
//           child: CircularProgressIndicator(color: Color(0xff18B6A3)))
//           : _loadError != null
//           ? _buildError()
//           : Column(
//         children: [
//           // ── VALIDATION WARNING ─────────────────────────────────
//           if (_validationWarning != null)
//             Container(
//               width: double.infinity,
//               color: Colors.orange.shade700,
//               padding: const EdgeInsets.symmetric(
//                   horizontal: 16, vertical: 10),
//               child: Row(children: [
//                 const Icon(Icons.warning_amber_rounded,
//                     color: Colors.white, size: 18),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(_validationWarning!,
//                       style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 13,
//                           fontWeight: FontWeight.w500)),
//                 ),
//               ]),
//             ),
//
//           Expanded(
//             child: _ads.isEmpty
//                 ? _buildNoAds()
//                 : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(children: [
//
//                 // ── LIVE STATS ─────────────────────────────
//                 _buildStatsCard(),
//                 const SizedBox(height: 14),
//
//                 // ── CURRENT AD ─────────────────────────────
//                 _buildCurrentAdCard(),
//                 const SizedBox(height: 14),
//
//                 // ── GPS STATUS ──────────────────────────────
//                 _buildGpsCard(),
//                 const SizedBox(height: 14),
//
//                 // ── AD QUEUE ───────────────────────────────
//                 if (_ads.length > 1) ...[
//                   _buildAdQueue(),
//                   const SizedBox(height: 14),
//                 ],
//               ]),
//             ),
//           ),
//
//           // ── GO ONLINE / OFFLINE BUTTON ─────────────────────────
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
//             child: SizedBox(
//               width: double.infinity,
//               height: 54,
//               child: ElevatedButton.icon(
//                 onPressed: _ads.isEmpty
//                     ? null
//                     : _tripActive ? _goOffline : _goOnline,
//                 icon: Icon(
//                   _tripActive
//                       ? Icons.stop_circle_outlined
//                       : Icons.play_circle_outline,
//                   size: 22,
//                 ),
//                 label: Text(
//                   _tripActive ? 'Go Offline' : 'Go Online',
//                   style: const TextStyle(
//                       fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: _tripActive
//                       ? Colors.red.shade600
//                       : const Color(0xff18B6A3),
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14)),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ── LIVE STATS CARD ─────────────────────────────────────────────────────────
//   Widget _buildStatsCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.black87,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: const [
//           BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0,3))
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(children: [
//             const Icon(Icons.today, color: Color(0xff18B6A3), size: 16),
//             const SizedBox(width: 6),
//             Text(
//               "Today's Stats  •  ${_fmt(DateTime.now())}",
//               style: const TextStyle(
//                   color: Colors.white70, fontSize: 12,
//                   fontWeight: FontWeight.w500),
//             ),
//           ]),
//           const SizedBox(height: 14),
//           Row(children: [
//             Expanded(child: _statItem(
//               Icons.route,
//               '${_todayDistanceKm.toStringAsFixed(2)} km',
//               'Distance',
//             )),
//             Expanded(child: _statItem(
//               Icons.timer_outlined,
//               '${_todayTimeMinutes.toStringAsFixed(0)} min',
//               'Valid Time',
//             )),
//             Expanded(child: _statItem(
//               Icons.gps_fixed,
//               '$_todaySegments',
//               'Pings',
//             )),
//           ]),
//         ],
//       ),
//     );
//   }
//
//   Widget _statItem(IconData icon, String value, String label) {
//     return Column(
//       children: [
//         Icon(icon, color: const Color(0xff18B6A3), size: 22),
//         const SizedBox(height: 6),
//         Text(value,
//             style: const TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16)),
//         const SizedBox(height: 2),
//         Text(label,
//             style: const TextStyle(color: Colors.white54, fontSize: 11)),
//       ],
//     );
//   }
//
//   // ── CURRENT AD CARD ─────────────────────────────────────────────────────────
//   Widget _buildCurrentAdCard() {
//     final ad = _ads[_currentAdIndex];
//     final isValid = _validationWarning == null;
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(
//           color: _tripActive
//               ? (isValid ? const Color(0xff18B6A3) : Colors.orange.shade400)
//               : Colors.transparent,
//           width: 2,
//         ),
//         boxShadow: const [
//           BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,3))
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: const BoxDecoration(
//               color: Color(0xffe6faf8),
//               borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//             ),
//             child: Row(children: [
//               const Icon(Icons.campaign_outlined,
//                   color: Color(0xff18B6A3), size: 20),
//               const SizedBox(width: 8),
//               const Text('Now Displaying',
//                   style: TextStyle(fontSize: 12, color: Colors.black54)),
//               const Spacer(),
//               if (_ads.length > 1)
//                 Text('${_currentAdIndex + 1} / ${_ads.length}',
//                     style: const TextStyle(fontSize: 12, color: Colors.black45)),
//             ]),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   ad.adTitle.isNotEmpty ? ad.adTitle : 'Ad #${ad.adId}',
//                   style: const TextStyle(
//                       fontSize: 17, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 _infoRow(Icons.tag, 'Ad ID', '#${ad.adId}'),
//                 const SizedBox(height: 4),
//                 _infoRow(Icons.check_circle_outline, 'Status',
//                     ad.status.toUpperCase(),
//                     color: const Color(0xff18B6A3)),
//                 if (ad.startingDate != null && ad.endingDate != null) ...[
//                   const SizedBox(height: 4),
//                   _infoRow(Icons.date_range_outlined, 'Campaign',
//                       '${_fmt(ad.startingDate!)} → ${_fmt(ad.endingDate!)}'),
//                 ],
//                 if (_ads.length > 1) ...[
//                   const SizedBox(height: 8),
//                   const Divider(),
//                   Row(children: [
//                     const Icon(Icons.autorenew, size: 13, color: Colors.grey),
//                     const SizedBox(width: 4),
//                     const Text('Rotates every 60 seconds',
//                         style: TextStyle(fontSize: 11, color: Colors.grey)),
//                   ]),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ── GPS CARD ────────────────────────────────────────────────────────────────
//   Widget _buildGpsCard() {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
//       ),
//       child: Row(children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: _tripActive
//                 ? const Color(0xff18B6A3).withOpacity(0.15)
//                 : Colors.grey.shade100,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(Icons.location_on,
//               color: _tripActive ? const Color(0xff18B6A3) : Colors.grey,
//               size: 22),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             const Text('GPS Location',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
//             const SizedBox(height: 2),
//             Text(
//               _lastPosition == null
//                   ? 'Waiting for location...'
//                   : '${_lastPosition!.latitude.toStringAsFixed(5)}, '
//                   '${_lastPosition!.longitude.toStringAsFixed(5)}',
//               style: const TextStyle(fontSize: 12, color: Colors.black54),
//             ),
//           ]),
//         ),
//         if (_tripActive)
//           const Text('Pinging\nevery 30s',
//               textAlign: TextAlign.right,
//               style: TextStyle(
//                   fontSize: 10,
//                   color: Color(0xff18B6A3),
//                   fontWeight: FontWeight.w600)),
//       ]),
//     );
//   }
//
//   // ── AD QUEUE ────────────────────────────────────────────────────────────────
//   Widget _buildAdQueue() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text('Ad Queue',
//             style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 8),
//         ...List.generate(_ads.length, (i) {
//           final ad = _ads[i];
//           final isCurrent = i == _currentAdIndex;
//           return Container(
//             margin: const EdgeInsets.only(bottom: 8),
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//             decoration: BoxDecoration(
//               color: isCurrent ? const Color(0xffe6faf8) : Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: isCurrent
//                   ? Border.all(color: const Color(0xff18B6A3), width: 1.5)
//                   : null,
//               boxShadow: const [
//                 BoxShadow(color: Colors.black12, blurRadius: 4)
//               ],
//             ),
//             child: Row(children: [
//               Container(
//                 width: 26, height: 26,
//                 decoration: BoxDecoration(
//                   color: isCurrent
//                       ? const Color(0xff18B6A3)
//                       : Colors.grey.shade200,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Center(
//                   child: Text('${i + 1}',
//                       style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           color: isCurrent ? Colors.white : Colors.grey)),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   ad.adTitle.isNotEmpty ? ad.adTitle : 'Ad #${ad.adId}',
//                   style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: isCurrent
//                           ? FontWeight.bold
//                           : FontWeight.normal),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               if (isCurrent)
//                 const Icon(Icons.play_arrow,
//                     size: 16, color: Color(0xff18B6A3)),
//             ]),
//           );
//         }),
//       ],
//     );
//   }
//
//   Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
//     return Row(children: [
//       Icon(icon, size: 14, color: Colors.grey),
//       const SizedBox(width: 6),
//       Text('$label: ',
//           style: const TextStyle(fontSize: 12, color: Colors.grey)),
//       Text(value,
//           style: TextStyle(
//               fontSize: 12,
//               color: color ?? Colors.black87,
//               fontWeight:
//               color != null ? FontWeight.w600 : FontWeight.normal)),
//     ]);
//   }
//
//   Widget _buildNoAds() {
//     return const Center(
//       child: Padding(
//         padding: EdgeInsets.all(32),
//         child: Column(mainAxisSize: MainAxisSize.min, children: [
//           Icon(Icons.campaign_outlined, size: 60, color: Colors.grey),
//           SizedBox(height: 12),
//           Text('No active ads assigned to this vehicle.',
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey, fontSize: 15)),
//           SizedBox(height: 8),
//           Text(
//               'Your vehicle must be linked to an agency and the fence + schedule must match.',
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey, fontSize: 12)),
//         ]),
//       ),
//     );
//   }
//
//   Widget _buildError() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(mainAxisSize: MainAxisSize.min, children: [
//           const Icon(Icons.error_outline, color: Colors.red, size: 48),
//           const SizedBox(height: 12),
//           Text(_loadError!, textAlign: TextAlign.center),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _loadAds,
//             style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xff18B6A3)),
//             child: const Text('Retry',
//                 style: TextStyle(color: Colors.white)),
//           ),
//         ]),
//       ),
//     );
//   }
//
//   String _fmt(DateTime d) =>
//       '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
// }