import 'package:ads_frontend/views/advertiser/accountScreen.dart';
import 'package:ads_frontend/views/advertiser/adScheduleScreen.dart';
import 'package:ads_frontend/views/advertiser/addFence.dart';
import 'package:ads_frontend/views/advertiser/addNewFenceScreen.dart';
import 'package:ads_frontend/views/advertiser/matchedDriversScreen.dart';

import 'package:ads_frontend/views/advertiser/sentRequestsScreen.dart';
import 'package:ads_frontend/views/advertiser/statsScreen.dart';
import 'package:ads_frontend/views/advertiser/adDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/Ad.dart';
import '../../models/AdFence.dart';
import '../../services/AdApiService.dart';
import '../../services/AdFenceApiService.dart';
import 'myAdsScreen.dart';

class AdvertiserHomeScreen extends StatefulWidget {
  const AdvertiserHomeScreen({super.key});

  @override
  State<AdvertiserHomeScreen> createState() =>
      _AdvertiserHomeScreenState();
}

class _AdvertiserHomeScreenState extends State<AdvertiserHomeScreen> {
  int currentIndex = 0;
  late Future<List<Ad>> adsFuture;
  int? userId;

  // ── unchanged ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');
    setState(() {
      adsFuture = AdApiService.fetchAdsByUser(userId!);
    });
  }

  Future<void> _reload() async {
    if (userId == null) return;
    setState(() {
      adsFuture = AdApiService.fetchAdsByUser(userId!);
    });
  }
  // ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f4f4),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── HEADER ──────────────────────────────────────────────────────
          _buildHeader(),

          const SizedBox(height: 16),

          // ── REQUESTS BUTTON ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SentRequestScreen()),
                );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff00c4aa), Color(0xff00a892)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff00c4aa).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text(
                      "Sent Requests",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── SECTION LABEL ────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Your Ads",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xff1a1a2e),
                letterSpacing: -0.3,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── ADS LIST ─────────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<Ad>>(
              future: adsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff00c4aa),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.red.shade300),
                          const SizedBox(height: 12),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final ads = snapshot.data ?? [];
                if (ads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 64,
                            color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          "No ads yet.",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xff00c4aa),
                  onRefresh: _reload,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: ads.length,
                    itemBuilder: (context, index) {
                      final ad = ads[index];
                      return FutureBuilder<List<AdFence>>(
                        future: AdFenceApiService.getFenceByAd(ad.adId),
                        builder: (context, fenceSnapshot) {
                          final fenceCount =
                              fenceSnapshot.data?.length ?? 0;
                          final isLoading = fenceSnapshot
                              .connectionState ==
                              ConnectionState.waiting;
                          return _buildAdCard(
                            ad,
                            fenceCount: fenceCount,
                            isLoading: isLoading,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ── BOTTOM NAV ───────────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xff00c4aa),
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 11),
        onTap: (index) {
          if (index == currentIndex) return;
          setState(() => currentIndex = index);

          if (index == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const StatsScreen()));
          } else if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyAdsScreen()));
          } else if (index == 3) {
            Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const AccountScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded), label: "Stats"),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded), label: "My Ads"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: "Account"),
        ],
      ),
    );
  }

  // ── Header widget ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 52, left: 20, right: 20, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff00c4aa), Color(0xff009e8e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dashboard",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Welcome back 👋",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Ad Card ───────────────────────────────────────────────────────────────
  Widget _buildAdCard(Ad ad,
      {required int fenceCount, bool isLoading = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdDetailsScreen(adId: ad.adId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [

            // ── Image + overlay info ───────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  child: Image.network(
                    ad.mediaPath,
                    height: 155,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 155,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            size: 36, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                // Dark gradient overlay at bottom of image
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Title over image
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ad.adTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                              )
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Category pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xff00c4aa).withOpacity(0.88),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ad.Category ?? "General",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Action row ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [

                  // Geofence button
                  _actionIconBtn(
                    icon: Icons.location_on_rounded,
                    color: isLoading ? Colors.grey : const Color(0xff3b82f6),
                    bgColor: isLoading
                        ? Colors.grey.shade100
                        : const Color(0xff3b82f6).withOpacity(0.1),
                    badge: fenceCount > 0 ? fenceCount : null,
                    tooltip: fenceCount == 0
                        ? "Add Geofence"
                        : "Add Another Geofence ($fenceCount existing)",
                    onTap: isLoading
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddFenceScreen(adId: ad.adId),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 8),

                  // Schedule button
                  _actionIconBtn(
                    icon: Icons.schedule_rounded,
                    color: const Color(0xfff59e0b),
                    bgColor: const Color(0xfff59e0b).withOpacity(0.1),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdScheduleScreen(adId: ad.adId),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // Find Drivers CTA
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MatchedDriversScreen(adId: ad.adId),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xff00c4aa),
                            Color(0xff009e8e),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff00c4aa).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_car_rounded,
                              color: Colors.white, size: 15),
                          SizedBox(width: 6),
                          Text(
                            "Find Drivers",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable action icon button ───────────────────────────────────────────
  Widget _actionIconBtn({
    required IconData icon,
    required Color color,
    required Color bgColor,
    int? badge,
    String? tooltip,
    VoidCallback? onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Tooltip(
          message: tooltip ?? '',
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ),
        ),
        if (badge != null && badge > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "$badge",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}