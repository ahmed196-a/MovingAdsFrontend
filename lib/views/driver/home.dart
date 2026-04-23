import 'package:ads_frontend/views/advertiser/requestsScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/Ad.dart';
import '../../services/AdApiService.dart';
import '../../services/VehicleApiService.dart';
import '../driver/adDetailsScreen.dart';
import '../advertiser/accountScreen.dart';
import '../driver/registeredVehiclesScreen.dart';
import '../driver/routesScreen.dart';
import 'adSimulationScreen.dart';
import 'myEarningsScreen.dart';


class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int currentIndex = 0;
  late Future<List<Ad>> adsFuture;

  @override
  void initState() {
    super.initState();
    adsFuture = AdApiService.fetchAds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔥 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xff18B6A3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const Center(
                child: Text(
                  "Welcome",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔥 YOUR REQUESTS BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RequestScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xff18B6A3),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6)
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group, color: Colors.black),
                      SizedBox(width: 10),
                      Text(
                        "Your Requests",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🔥 QUICK ACTIONS
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Quick Actions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _quickActionCard(
                      icon: Icons.directions_car,
                      title: "Registered Vehicles",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisteredVehiclesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickActionCard(
                      icon: Icons.location_on,
                      title: "Set Routes",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SetRoutesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickActionCard(
                      icon: Icons.monetization_on,
                      title: "My Earnings",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const MyEarningsScreen(),
                        ));
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children:[
              Expanded(
              child: _quickActionCard(
              icon: Icons.play_circle_outline,
                title: "Start Simulation",
                onTap: () async {
                  // Get first vehicle reg from SharedPreferences or vehicles list
                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.getInt('userId');
                  if (userId != null) {
                    final vehicles = await VehicleApiService.fetchVehicles(userId);
                    if (vehicles.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdSimulationScreen(
                            // vehicleReg: vehicles.first.vehicleReg,
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
                ]
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 NEW ADS TITLE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "New Ads Opportunities",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            // 🔥 ADS LIST
            Expanded(
              child: FutureBuilder<List<Ad>>(
                future: adsFuture,
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }

                  final ads = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: ads.length,
                    itemBuilder: (context, index) {
                      final ad = ads[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdDetailsScreen(ad: ad),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 5)
                            ],
                          ),
                          child: Row(
                            children: [

                              // IMAGE
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  ad.mediaPath,
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image, size: 40),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // TEXT SECTION
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
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[200],
                                            borderRadius:
                                            BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            ad.status ?? "active",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    Row(
                                      children: const [
                                        Icon(Icons.location_on, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          "6th Road, Rawalpindi",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),

                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // 🔥 BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) return;

          setState(() => currentIndex = index);

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "My Ads"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xff18B6A3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 5)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            )
          ],
        ),
      ),
    );
  }
}
