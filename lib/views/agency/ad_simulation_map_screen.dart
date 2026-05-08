import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:ads_frontend/services/agencyApiService.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/agency.dart';
import '../../models/vehicle.dart';
import '../../services/AdApiService.dart';
import '../../services/AdFenceApiService.dart';


// ── Ad model for simulation ──
class _SimAd {
  final int adId;
  final String adTitle;
  final String mediaPath;
  final List<LatLng> fence;

  _SimAd({
    required this.adId,
    required this.adTitle,
    required this.mediaPath,
    required this.fence,
  });
}

class AdSimulationMapScreen extends StatefulWidget {
  final Agency agency;
  final Vehicle vehicle;
  final DateTime simulationStartTime;

  const AdSimulationMapScreen({
    super.key,
    required this.agency,
    required this.vehicle,
    required this.simulationStartTime,
  });

  @override
  State<AdSimulationMapScreen> createState() => _AdSimulationMapScreenState();
}

class _AdSimulationMapScreenState extends State<AdSimulationMapScreen>
    with TickerProviderStateMixin {

  GoogleMapController? _mapController;

  // ── Loading ──
  bool _loadingAds = true;
  String? _errorMessage;

  // ── Ad data ──
  List<_SimAd> _ads = [];

  // ── Route tapping ──
  List<LatLng> _tappedRoute = [];
  bool _routeLocked = false; // once trip starts, no more tapping

  // ── Trip state ──
  bool _isRunning = false;
  int _currentStep = 0;
  Timer? _moveTimer;

  // ── Ad panel state ──
  List<int> _currentFenceAdIndexes = []; // indexes into _ads
  bool _inOverlapZone = false;
  int _displayAdIndex = 0; // which ad is currently shown
  Timer? _rotateTimer;
  Timer? _countdownTimer;
  int _secondsLeft = 3;
  static const int _rotationSeconds = 3;

  // ── Car icon ──
  BitmapDescriptor? _carIcon;

  // ── Live clock ──
  late DateTime _liveTime;
  Timer? _clockTimer;

  // ── Slide animation for overlap panel ──
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  // Palette for ad fences
  static const List<Color> _fenceColors = [
    Color(0xff2196F3),
    Color(0xffFF9800),
    Color(0xff9C27B0),
    Color(0xffF44336),
    Color(0xff4CAF50),
    Color(0xffE91E63),
  ];

  @override
  void initState() {
    super.initState();
    _liveTime = widget.simulationStartTime;

    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _startLiveClock();
    _loadCarIcon().then((_) => _loadAds());
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _rotateTimer?.cancel();
    _countdownTimer?.cancel();
    _clockTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  // ── Live clock ──
  void _startLiveClock() {
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() => _liveTime = _liveTime.add(const Duration(seconds: 1)));
        });
  }

  String get _clockDisplay {
    final h = _liveTime.hour.toString().padLeft(2, '0');
    final m = _liveTime.minute.toString().padLeft(2, '0');
    final s = _liveTime.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ── Car icon (Canvas-drawn) ──
  Future<void> _loadCarIcon() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const double size = 80;

      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(6, 12, size - 12, size - 20),
            const Radius.circular(14)),
        shadowPaint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(4, 8, size - 8, size - 18),
            const Radius.circular(12)),
        Paint()..color = const Color(0xff00c4aa),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(14, 4, size - 28, 28),
            const Radius.circular(8)),
        Paint()..color = const Color(0xff009982),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(17, 6, size - 34, 22),
            const Radius.circular(5)),
        Paint()..color = Colors.white.withOpacity(0.85),
      );

      final wheelPaint = Paint()..color = const Color(0xff1a1a2e);
      canvas.drawCircle(const Offset(16, size - 10), 9, wheelPaint);
      canvas.drawCircle(Offset(size - 16, size - 10), 9, wheelPaint);

      final rimPaint = Paint()..color = Colors.white54;
      canvas.drawCircle(const Offset(16, size - 10), 4, rimPaint);
      canvas.drawCircle(Offset(size - 16, size - 10), 4, rimPaint);

      final lightPaint = Paint()..color = Colors.yellow[200]!;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(6, 10, 10, 5), const Radius.circular(2)),
          lightPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(size - 16, 10, 10, 5), const Radius.circular(2)),
          lightPaint);

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final ByteData? bd =
      await img.toByteData(format: ui.ImageByteFormat.png);
      if (bd != null) {
        _carIcon = BitmapDescriptor.fromBytes(bd.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Car icon error: $e');
    }
  }

  // ── Load ads for this agency ──
  Future<void> _loadAds() async {
    try {
      // 1. Get active assignments for this agency
      final assignments = await AgencyApiService
          .getAssignmentsByAgency(widget.agency.agencyId);

      if (assignments.isEmpty) {
        setState(() {
          _errorMessage = 'No active ads assigned to this agency.';
          _loadingAds = false;
        });
        return;
      }

      // 2. For each assignment, load ad details + fence
      final List<_SimAd> result = [];

      for (final assign in assignments) {
        try {
          final fences =
          await AdFenceApiService.getFenceByAd(assign.adId);
          if (fences.isEmpty) continue;

          final polygon = _parsePolygon(fences.first.polygon);
          if (polygon.isEmpty) continue;

          result.add(_SimAd(
            adId: assign.adId,
            adTitle: assign.adTitle,
            mediaPath: '',  // AdAssignment model has adTitle; mediaPath needs Ad fetch
            fence: polygon,
          ));
        } catch (e) {
          debugPrint('Fence load error adId=${assign.adId}: $e');
        }
      }

      // 3. Optionally enrich with mediaPath from Ad
      // (fetch all ads and match by adId)
      try {
        final allAds = await AdApiService.fetchAds();
        final enriched = result.map((sim) {
          final match = allAds.firstWhere(
                (a) => _toInt(a.adId) == sim.adId,
            orElse: () => allAds.first,
          );
          return _SimAd(
            adId: sim.adId,
            adTitle: sim.adTitle,
            mediaPath: _toInt(match.adId) == sim.adId
                ? (match.mediaPath ?? '')
                : '',
            fence: sim.fence,
          );
        }).toList();
        setState(() {
          _ads = enriched;
          _loadingAds = false;
        });
      } catch (_) {
        setState(() {
          _ads = result;
          _loadingAds = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load ads: $e';
        _loadingAds = false;
      });
    }
  }

  // ── Helpers ──
  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  List<LatLng> _parsePolygon(dynamic raw) {
    try {
      List data;
      if (raw is String) {
        data = jsonDecode(raw) as List;
      } else if (raw is List) {
        data = raw;
      } else {
        return [];
      }
      if (data.isEmpty) return [];
      if (data.first is Map) {
        return data.map<LatLng>((e) {
          final m = e as Map;
          final lat = (m['lat'] ?? m['latitude'] ?? 0) as num;
          final lng = (m['lng'] ?? m['longitude'] ?? 0) as num;
          return LatLng(lat.toDouble(), lng.toDouble());
        }).toList();
      }
      if (data.first is List) {
        return data.map<LatLng>((e) {
          final arr = e as List;
          return LatLng(
              (arr[1] as num).toDouble(), (arr[0] as num).toDouble());
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    int count = 0;
    final n = polygon.length;
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
        count++;
      }
    }
    return (count % 2) == 1;
  }

  // ── Map tap → add route point ──
  void _onMapTap(LatLng pos) {
    if (_routeLocked) return;
    setState(() => _tappedRoute.add(pos));
  }

  void _undoLastPoint() {
    if (_tappedRoute.isEmpty || _routeLocked) return;
    setState(() => _tappedRoute.removeLast());
  }

  void _clearRoute() {
    if (_routeLocked) return;
    setState(() => _tappedRoute.clear());
  }

  // ── Trip control ──
  void _startTrip() {
    if (_tappedRoute.length < 2 || _isRunning) return;
    setState(() {
      _isRunning = true;
      _routeLocked = true;
      _currentStep = 0;
    });

    _moveTimer =
        Timer.periodic(const Duration(milliseconds: 15000), (_) {
          if (!mounted) return;
          if (_currentStep >= _tappedRoute.length - 1) {
            _stopTrip();
            return;
          }
          setState(() => _currentStep++);
          _checkZones();
          _mapController
              ?.animateCamera(CameraUpdate.newLatLng(_tappedRoute[_currentStep]));
        });
  }

  void _stopTrip() {
    _moveTimer?.cancel();
    _rotateTimer?.cancel();
    _countdownTimer?.cancel();
    _moveTimer = null;
    setState(() {
      _isRunning = false;
      _inOverlapZone = false;
      _currentFenceAdIndexes = [];
    });
    _slideController.reverse();
  }

  void _resetTrip() {
    _stopTrip();
    setState(() {
      _routeLocked = false;
      _tappedRoute.clear();
      _currentStep = 0;
    });
  }

  // ── Zone detection ──
  void _checkZones() {
    if (!mounted || _tappedRoute.isEmpty) return;
    final pos = _tappedRoute[_currentStep];

    final List<int> inFence = [];
    for (int i = 0; i < _ads.length; i++) {
      if (_isPointInPolygon(pos, _ads[i].fence)) inFence.add(i);
    }

    if (inFence.length > 1) {
      // Overlap zone
      if (!_inOverlapZone) {
        setState(() {
          _inOverlapZone = true;
          _currentFenceAdIndexes = inFence;
          _displayAdIndex = inFence.first;
          _secondsLeft = _rotationSeconds;
        });
        _startRotation(inFence);
        _slideController.forward(from: 0);
      } else {
        setState(() => _currentFenceAdIndexes = inFence);
      }
    } else if (inFence.length == 1) {
      if (_inOverlapZone) {
        _stopRotation();
        _slideController.reverse();
      }
      setState(() {
        _inOverlapZone = false;
        _currentFenceAdIndexes = inFence;
        _displayAdIndex = inFence.first;
      });
    } else {
      if (_inOverlapZone) {
        _stopRotation();
        _slideController.reverse();
      }
      setState(() {
        _inOverlapZone = false;
        _currentFenceAdIndexes = [];
      });
    }
  }

  void _startRotation(List<int> adIndexes) {
    _stopRotation();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() {
            _secondsLeft--;
            if (_secondsLeft <= 0) _secondsLeft = _rotationSeconds;
          });
        });

    _rotateTimer = Timer.periodic(
        const Duration(seconds: _rotationSeconds), (_) {
      if (!mounted || _currentFenceAdIndexes.isEmpty) return;
      final currentPos =
      _currentFenceAdIndexes.indexOf(_displayAdIndex);
      final nextPos =
          (currentPos + 1) % _currentFenceAdIndexes.length;
      setState(() {
        _displayAdIndex = _currentFenceAdIndexes[nextPos];
        _secondsLeft = _rotationSeconds;
      });
      _slideController.forward(from: 0);
    });
  }

  void _stopRotation() {
    _rotateTimer?.cancel();
    _countdownTimer?.cancel();
    _rotateTimer = null;
    _countdownTimer = null;
  }

  // ── Map builders ──
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Car marker (only during trip)
    if (_isRunning || (_routeLocked && _currentStep > 0)) {
      markers.add(Marker(
        markerId: const MarkerId('car'),
        position: _tappedRoute[_currentStep],
        icon: _carIcon ??
            BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: widget.vehicle.vehicleReg,
          snippet: _inOverlapZone ? 'In overlap zone' : 'Driving',
        ),
      ));
    }

    // Route waypoint markers (numbered) — show when building route
    if (!_routeLocked) {
      for (int i = 0; i < _tappedRoute.length; i++) {
        markers.add(Marker(
          markerId: MarkerId('wp_$i'),
          position: _tappedRoute[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(
              i == 0
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueCyan),
          anchor: const Offset(0.5, 1.0),
          infoWindow: InfoWindow(title: i == 0 ? 'Start' : 'Point ${i + 1}'),
        ));
      }
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_tappedRoute.length < 2) return {};
    final lines = <Polyline>{};

    // Full planned route (dashed)
    lines.add(Polyline(
      polylineId: const PolylineId('planned'),
      points: _tappedRoute,
      color: Colors.blueGrey.withOpacity(0.4),
      width: 4,
      patterns: [PatternItem.dash(16), PatternItem.gap(8)],
    ));

    // Driven portion (solid teal)
    if (_currentStep > 0) {
      lines.add(Polyline(
        polylineId: const PolylineId('driven'),
        points: _tappedRoute.sublist(0, _currentStep + 1),
        color: const Color(0xff00c4aa),
        width: 5,
      ));
    }

    return lines;
  }

  Set<Polygon> _buildPolygons() {
    final polygons = <Polygon>{};
    for (int i = 0; i < _ads.length; i++) {
      final color = _fenceColors[i % _fenceColors.length];
      final isActive = _currentFenceAdIndexes.contains(i);
      polygons.add(Polygon(
        polygonId: PolygonId('fence_$i'),
        points: _ads[i].fence,
        strokeColor: color,
        strokeWidth: isActive ? 3 : 2,
        fillColor: isActive
            ? color.withOpacity(0.25)
            : color.withOpacity(0.10),
      ));
    }
    return polygons;
  }

  // ── Legend ──
  Widget _buildLegend() {
    if (_ads.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Ad Fences',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 0.3)),
          const SizedBox(height: 6),
          ..._ads.asMap().entries.map((e) {
            final color = _fenceColors[e.key % _fenceColors.length];
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      e.value.adTitle,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Bottom ad panel ──
  Widget _buildBottomPanel() {
    if (_inOverlapZone && _currentFenceAdIndexes.length > 1) {
      return _buildOverlapPanel();
    }
    return _buildSinglePanel();
  }

  Widget _buildSinglePanel() {
    final bool hasAd = _currentFenceAdIndexes.isNotEmpty &&
        _displayAdIndex < _ads.length;
    final ad = hasAd ? _ads[_displayAdIndex] : null;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xff00c4aa).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_car,
                      color: Color(0xff00c4aa), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.vehicle.vehicleReg,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        _isRunning
                            ? 'Step ${_currentStep + 1} / ${_tappedRoute.length}'
                            : _routeLocked
                            ? 'Trip ended'
                            : 'Ready',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isRunning
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _isRunning ? Colors.green : Colors.grey),
                  ),
                  child: Text(
                    _isRunning ? 'Running' : 'Idle',
                    style: TextStyle(
                        color: _isRunning ? Colors.green : Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          if (ad != null) ...[
            const Divider(height: 1),
            _buildAdRow(ad, isOverlap: false),
          ] else if (_isRunning) ...[
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.location_off, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Text('No ad fence at current position',
                      style:
                      TextStyle(fontSize: 12, color: Colors.black45)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverlapPanel() {
    if (_displayAdIndex >= _ads.length) return _buildSinglePanel();
    final ad = _ads[_displayAdIndex];
    final total = _currentFenceAdIndexes.length;

    return SlideTransition(
      position: _slideAnim,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8)],
          border: Border.all(
              color: const Color(0xffFF5252).withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Overlap banner
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: const BoxDecoration(
                color: Color(0xfffff0f0),
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text('Overlap Zone — Rotating Ads',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  Text(
                    '${_currentFenceAdIndexes.indexOf(_displayAdIndex) + 1} / $total',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ),
            _buildAdRow(ad, isOverlap: true),
            // Dot indicator
            if (total > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(total, (i) {
                    final active =
                        _currentFenceAdIndexes[i] == _displayAdIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xff00c4aa)
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
                  color: const Color(0xff00c4aa),
                  minHeight: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdRow(_SimAd ad, {required bool isOverlap}) {
    final imgSize = isOverlap ? 80.0 : 64.0;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: imgSize,
            height: imgSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xff00c4aa).withOpacity(0.3),
                  width: 1.5),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: ad.mediaPath.isNotEmpty
                  ? Image.network(ad.mediaPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.grey))
                  : const Icon(Icons.campaign,
                  color: Colors.grey, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverlap ? 'Now Displaying' : 'Active Ad',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  ad.adTitle,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ad #${ad.adId}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
                if (isOverlap) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timer,
                          size: 13, color: Color(0xff00c4aa)),
                      const SizedBox(width: 4),
                      Text(
                        'Next in $_secondsLeft sec',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xff00c4aa)),
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

  // ── Route builder toolbar ──
  Widget _buildRouteToolbar() {
    if (_routeLocked) return const SizedBox.shrink();
    return Positioned(
      top: 12,
      right: 12,
      child: Column(
        children: [
          _toolbarBtn(
            icon: Icons.undo,
            label: 'Undo',
            color: Colors.orange,
            onTap: _undoLastPoint,
            enabled: _tappedRoute.isNotEmpty,
          ),
          const SizedBox(height: 8),
          _toolbarBtn(
            icon: Icons.clear,
            label: 'Clear',
            color: Colors.red,
            onTap: _clearRoute,
            enabled: _tappedRoute.isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _toolbarBtn(
      {required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
        required bool enabled}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Trip controls ──
  Widget _buildTripControls() {
    return Positioned(
      top: _routeLocked ? 12 : 100,
      right: 12,
      child: Column(
        children: [
          if (!_routeLocked && _tappedRoute.length >= 2)
            _toolbarBtn(
              icon: Icons.play_arrow,
              label: 'Start',
              color: Colors.green,
              onTap: _startTrip,
              enabled: !_isRunning,
            ),
          if (_isRunning) ...[
            _toolbarBtn(
              icon: Icons.stop,
              label: 'Stop',
              color: Colors.red,
              onTap: _stopTrip,
              enabled: true,
            ),
            const SizedBox(height: 8),
          ],
          if (_routeLocked && !_isRunning)
            _toolbarBtn(
              icon: Icons.refresh,
              label: 'Reset',
              color: Colors.blueGrey,
              onTap: _resetTrip,
              enabled: true,
            ),
        ],
      ),
    );
  }

  // ── Tap hint ──
  Widget _buildTapHint() {
    if (_routeLocked || _tappedRoute.length >= 2) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app,
                  color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                _tappedRoute.isEmpty
                    ? 'Tap on the map to set route'
                    : '${_tappedRoute.length} point${_tappedRoute.length > 1 ? 's' : ''} — tap more or press Start',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── AppBar ──
          Container(
            color: const Color(0xff00c4aa),
            padding:
            const EdgeInsets.only(top: 48, bottom: 12, left: 8, right: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Simulation Map',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text(
                        '${widget.agency.agencyName}  ·  ${widget.vehicle.vehicleReg}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Live clock
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        _clockDisplay,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                // Zone badge
                if (_isRunning) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: _inOverlapZone ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _inOverlapZone ? 'OVERLAP' : 'ZONE',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Body ──
          Expanded(
            child: _loadingAds
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                      color: Color(0xff00c4aa)),
                  SizedBox(height: 14),
                  Text('Loading ad fences…',
                      style: TextStyle(color: Colors.black45)),
                ],
              ),
            )
                : _errorMessage != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(_errorMessage!,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _loadingAds = true;
                        });
                        _loadAds();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xff00c4aa)),
                      child: const Text('Retry',
                          style:
                          TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
                : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(24.8607, 67.0011),
                    zoom: 13,
                  ),
                  onMapCreated: (ctrl) => _mapController = ctrl,
                  onTap: _onMapTap,
                  markers: _buildMarkers(),
                  polylines: _buildPolylines(),
                  polygons: _buildPolygons(),
                  myLocationEnabled: false,
                  zoomControlsEnabled: true,
                ),

                // Legend
                Positioned(
                    top: 12, left: 12, child: _buildLegend()),

                // Tap hint
                _buildTapHint(),

                // Route toolbar (undo/clear)
                _buildRouteToolbar(),

                // Trip controls (start/stop/reset)
                _buildTripControls(),

                // Bottom ad panel
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}