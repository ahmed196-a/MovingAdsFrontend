import 'package:ads_frontend/views/advertiser/accountScreen.dart';
import 'package:ads_frontend/views/advertiser/adScheduleScreen.dart';
import 'package:ads_frontend/views/advertiser/addFence.dart';
import 'package:ads_frontend/views/advertiser/matchedDriversScreen.dart';
import 'package:ads_frontend/views/advertiser/requestsScreen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUser();
    adsFuture = AdApiService.fetchAds();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── HEADER ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            color: const Color(0xff00c4aa),
            child: const Center(
              child: Text(
                "Welcome",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── REQUESTS BUTTON ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RequestScreen()),
                );
              },
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xff00c4aa),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 5)
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people, color: Colors.black),
                    SizedBox(width: 10),
                    Text(
                      "Your Requests",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    )
                  ],
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Your Ads",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // ── ADS LIST ─────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<Ad>>(
              future: adsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text(snapshot.error.toString()));
                }

                final ads = snapshot.data ?? [];
                if (ads.isEmpty) {
                  return const Center(child: Text("No ads found."));
                }

                return ListView.builder(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index];

                    // ✅ FIX: fetch fences only to SHOW COUNT,
                    // not to disable the button
                    return FutureBuilder<List<AdFence>>(
                      future:
                      AdFenceApiService.getFenceByAd(ad.adId),
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
                );
              },
            ),
          ),
        ],
      ),

      // ── BOTTOM NAV ───────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xff00c4aa),
        unselectedItemColor: Colors.grey,
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
              icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Stats"),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt), label: "My Ads"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }

  // ── Ad Card ──────────────────────────────────────────────
  // fenceCount: how many fences already exist (just for display)
  // The add-fence button is ALWAYS enabled now
  Widget _buildAdCard(Ad ad,
      {required int fenceCount, bool isLoading = false}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdDetailsScreen(adId: ad.adId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6)
          ],
        ),
        child: Column(
          children: [

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Ad thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ad.mediaPath,
                    height: 90,
                    width: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image, size: 40),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [

                          Expanded(
                            child: Text(
                              ad.adTitle,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),

                          // ✅ FIX: Fence icon — always clickable.
                          // Badge shows existing fence count.
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.location_on,
                                  size: 22,
                                  // Blue = can add more, grey = loading
                                  color: isLoading
                                      ? Colors.grey
                                      : Colors.blue,
                                ),
                                tooltip: fenceCount == 0
                                    ? "Add Geofence"
                                    : "Add Another Geofence ($fenceCount existing)",
                                onPressed: isLoading
                                    ? null
                                    : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddNewAdFenceScreen(
                                              adId: ad.adId),
                                    ),
                                  );
                                },
                              ),
                              // Badge: show count if > 0
                              if (fenceCount > 0)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "$fenceCount",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // Schedule icon
                          IconButton(
                            icon: const Icon(Icons.schedule,
                                size: 22, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdScheduleScreen(
                                          adId: ad.adId),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      Text(
                        ad.Category ?? "General",
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          Icon(Icons.location_on, size: 16),
                          SizedBox(width: 6),
                          Expanded(child: Text("Rawalpindi")),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MatchedDriversScreen(adId: ad.adId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff00c4aa),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "Find Drivers",
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
