import 'package:ads_frontend/models/simulation_models.dart';
import 'package:ads_frontend/services/AdApiService.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/Ad.dart';
import '../../services/simulation_api_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int? _userId;

  List<Ad> _ads = [];
  final Map<int, AdAnalyticsResponse?> _analytics = {};
  final Map<int, String> _analyticsErrors = {};

  bool _loadingAds = true;
  String? _adsError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');

    if (_userId == null) {
      setState(() { _adsError = 'User not logged in.'; _loadingAds = false; });
      return;
    }

    setState(() {
      _loadingAds = true;
      _adsError = null;
      _ads = [];
      _analytics.clear();
      _analyticsErrors.clear();
    });

    try {
      final ads = await AdApiService.fetchAdsByUser(_userId!);

      setState(() {
        _ads = ads;
        for (final ad in ads) _analytics[ad.adId] = null;
        _loadingAds = false;
      });

      await Future.wait(ads.map((ad) async {
        try {
          final data = await SimulationApiService.getAdAnalytics(ad.adId);
          if (mounted) setState(() => _analytics[ad.adId] = data);
        } catch (e) {
          if (mounted) setState(() => _analyticsErrors[ad.adId] = e.toString());
        }
      }));
    } catch (e) {
      setState(() { _adsError = e.toString(); _loadingAds = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: _loadingAds
          ? const Center(child: CircularProgressIndicator(color: Color(0xff00c4aa)))
          : _adsError != null
          ? _buildError(_adsError!)
          : _ads.isEmpty
          ? _buildEmpty()
          : _buildBody(),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 52),
            const SizedBox(height: 14),
            const Text('Failed to load ads', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _init,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff00c4aa), foregroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('No ads found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          backgroundColor: const Color(0xff00c4aa),
          foregroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
            title: const Text('Ad Statistics',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
            background: Container(color: const Color(0xff00c4aa)),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh, color: Colors.black), onPressed: _init),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (_, i) {
                final ad = _ads[i];
                return _adCard(ad, _analytics[ad.adId], _analyticsErrors[ad.adId]);
              },
              childCount: _ads.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _adCard(Ad ad, AdAnalyticsResponse? data, String? error) {
    // Loading state — show image + spinner
    if (data == null && error == null) {
      return _cardShell(
        mediaPath: ad.mediaPath,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xff00c4aa)),
              ),
              const SizedBox(width: 10),
              Text(
                ad.adTitle.isNotEmpty ? 'Loading stats for ${ad.adTitle}…' : 'Loading Ad #${ad.adId}…',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Error state — show image + error message
    if (error != null && data == null) {
      return _cardShell(
        mediaPath: ad.mediaPath,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${ad.adTitle.isNotEmpty ? ad.adTitle : "Ad #${ad.adId}"} — failed to load analytics.',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Data ready
    final consumedPct = data!.allocatedMinutes > 0
        ? (data.consumedMinutes / data.allocatedMinutes).clamp(0.0, 1.0)
        : 0.0;

    final Color barColor = consumedPct < 0.5
        ? const Color(0xff00c4aa)
        : consumedPct < 0.8
        ? Colors.orange
        : Colors.red;

    return _cardShell(
      mediaPath: ad.mediaPath,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + % badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data.adTitle.isNotEmpty ? data.adTitle : 'Ad #${data.adId}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: barColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(consumedPct * 100).toStringAsFixed(0)}% used',
                    style: TextStyle(color: barColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3-column time stats
            Row(
              children: [
                Expanded(child: _timeStat(label: 'Allocated', value: _fmtMins(data.allocatedMinutes), sub: '${data.allocatedMinutes.toInt()} mins', color: Colors.black87)),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(child: _timeStat(label: 'Consumed', value: _fmtMins(data.consumedMinutes), sub: '${data.consumedMinutes.toStringAsFixed(1)} mins', color: barColor)),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(child: _timeStat(label: 'Remaining', value: _fmtMins(data.remainingMinutes), sub: '${data.remainingMinutes.toStringAsFixed(1)} mins', color: const Color(0xff00c4aa))),
              ],
            ),

            const SizedBox(height: 14),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: consumedPct,
                minHeight: 8,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${data.consumedMinutes.toStringAsFixed(1)} mins consumed',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text('${data.allocatedMinutes.toInt()} mins total',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared card shell with image on top ──────────────────────────────────
  Widget _cardShell({required String? mediaPath, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _adImage(mediaPath),
          child,
        ],
      ),
    );
  }

  // ── Ad image widget ──────────────────────────────────────────────────────
  Widget _adImage(String? mediaPath) {
    final bool hasImage = mediaPath != null && mediaPath.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: hasImage
          ? Image.network(
        mediaPath!,
        width: double.infinity,
        height: 160,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: double.infinity,
            height: 160,
            color: Colors.grey.shade100,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(0xff00c4aa),
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _imageFallback(),
      )
          : _imageFallback(),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 32),
          SizedBox(height: 6),
          Text('No image', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Widget _timeStat({required String label, required String value, required String sub, required Color color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  String _fmtMins(double mins) => '${(mins / 60).toStringAsFixed(1)} hrs';
}