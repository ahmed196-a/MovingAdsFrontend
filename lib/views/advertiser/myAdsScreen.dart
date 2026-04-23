import 'package:ads_frontend/views/advertiser/postAdScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/Ad.dart';
import '../../services/AdApiService.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  int? userId;
  String selectedFilter = "All";
  Future<List<Ad>>? adsFuture;

  final List<String> filters = ["All", "Active", "Paused", "Completed"];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');

    if (userId != null) {
      setState(() {
        adsFuture = AdApiService.fetchAdsByUser(userId!);
      });
    }
  }

  List<Ad> filterAds(List<Ad> ads) {
    if (selectedFilter == "All") return ads;

    return ads
        .where((ad) =>
    ad.status.toLowerCase() ==
        selectedFilter.toLowerCase())
        .toList();
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "active":
        return Colors.green[200]!;
      case "paused":
        return Colors.orange[200]!;
      case "completed":
        return Colors.blue[200]!;
      default:
        return Colors.grey[300]!;
    }
  }

  List<PopupMenuEntry<String>> buildMenuItems(String status) {
    switch (status.toLowerCase()) {
      case "active":
        return [
          const PopupMenuItem(
            value: "pause",
            child: Text("Pause"),
          )
        ];
      case "paused":
        return [
          const PopupMenuItem(
            value: "resume",
            child: Text("Resume"),
          )
        ];
      case "completed":
        return [
          const PopupMenuItem(
            value: "republish",
            child: Text("Republish"),
          )
        ];
      default:
        return [];
    }
  }

  void handleAction(String action, Ad ad) {
    if (action == "pause") {
      print("Pause clicked for AdId: ${ad.adId}");
    } else if (action == "resume") {
      print("Resume clicked for AdId: ${ad.adId}");
    } else if (action == "republish") {
      print("Republish clicked for AdId: ${ad.adId}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xff00c4aa),
        title: const Text("My Ads"),
      ),

      body: adsFuture == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 10),

          /// FILTER BAR
          Container(
            height: 40,
            margin:
            const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: filters.map((filter) {
                final isSelected =
                    filter == selectedFilter;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() =>
                      selectedFilter = filter);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          color: isSelected
                              ? Colors.black
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          /// ADS LIST
          Expanded(
            child: FutureBuilder<List<Ad>>(
              future: adsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child:
                      CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          snapshot.error.toString()));
                }

                final ads =
                filterAds(snapshot.data ?? []);

                if (ads.isEmpty) {
                  return const Center(
                      child: Text("No Ads Found"));
                }

                return ListView.builder(
                  padding:
                  const EdgeInsets.all(16),
                  itemCount: ads.length,
                  itemBuilder:
                      (context, index) {
                    final ad = ads[index];

                    return Container(
                      margin:
                      const EdgeInsets.only(
                          bottom: 14),
                      padding:
                      const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(
                            12),
                        boxShadow: const [
                          BoxShadow(
                              color:
                              Colors.black12,
                              blurRadius: 6)
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius:
                                BorderRadius
                                    .circular(8),
                                child: Image.network(
                                  ad.mediaPath,
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(
                                  width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                              ad.adTitle,
                                              style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight.bold)),
                                        ),

                                        /// STATUS BADGE
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal:
                                              10,
                                              vertical:
                                              4),
                                          decoration:
                                          BoxDecoration(
                                            color: statusColor(
                                                ad.status),
                                            borderRadius:
                                            BorderRadius.circular(
                                                12),
                                          ),
                                          child: Text(
                                              ad.status,
                                              style:
                                              const TextStyle(
                                                  fontSize:
                                                  12)),
                                        ),

                                        const SizedBox(
                                            width: 6),

                                        /// 3 DOT MENU
                                        if (buildMenuItems(
                                            ad.status)
                                            .isNotEmpty)
                                          PopupMenuButton<
                                              String>(
                                            onSelected:
                                                (value) =>
                                                handleAction(
                                                    value,
                                                    ad),
                                            itemBuilder:
                                                (context) =>
                                                buildMenuItems(
                                                    ad.status),
                                            icon:
                                            const Icon(
                                                Icons
                                                    .more_vert),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(
                                        height: 4),
                                    Text(
                                        ad.Category ??
                                            "",
                                        style:
                                        const TextStyle(
                                            color: Colors.grey)),
                                    const SizedBox(
                                        height: 6),
                                    Row(
                                      children: const [
                                        Icon(Icons
                                            .location_on,
                                            size: 16),
                                        SizedBox(
                                            width: 6),
                                        Expanded(
                                            child: Text(
                                                "6 Road, Rawalpindi")),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor:
        const Color(0xff00c4aa),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                const PostNewAdScreen()),
          );
        },
        child:
        const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}