import 'package:ads_frontend/views/driver/addNewRouteScreen.dart';
import 'package:flutter/material.dart';

class SetRoutesScreen extends StatefulWidget {
  const SetRoutesScreen({super.key});

  @override
  State<SetRoutesScreen> createState() => _SetRoutesScreenState();
}

class _SetRoutesScreenState extends State<SetRoutesScreen> {

  // Dummy route list
  List<Map<String, dynamic>> routes = [
    {
      "name": "Murree Road, Rawalpindi",
      "isOnline": true,
      "adsRunning": 3,
    },
    {
      "name": "6th Road, Rawalpindi",
      "isOnline": false,
      "adsRunning": 0,
    },
  ];

  void toggleRoute(int index, bool value) {
    setState(() {
      // Only one route can be online at a time
      for (int i = 0; i < routes.length; i++) {
        routes[i]["isOnline"] = false;
      }
      routes[index]["isOnline"] = value;
    });
  }

  @override
  Widget build(BuildContext context) {

    final activeRoute =
    routes.firstWhere((route) => route["isOnline"] == true,
        orElse: () => {});

    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        backgroundColor: const Color(0xff18B6A3),
        title: const Text(
          "Routes",
          style: TextStyle(color: Colors.black),
        ),
        leading: const BackButton(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔥 ACTIVE ROUTE SECTION
            if (activeRoute.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff7DB9B3),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 5)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Current Active Route",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius:
                            BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Live",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeRoute["name"],
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${activeRoute["adsRunning"]} ads running on this route",
                      style: const TextStyle(color: Colors.white70),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              "Saved Routes",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            /// 🔥 ROUTE CARDS
            ...List.generate(routes.length, (index) {
              final route = routes[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 5)
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            route["name"],
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Switch(
                          value: route["isOnline"],
                          activeColor: Colors.green,
                          onChanged: (value) =>
                              toggleRoute(index, value),
                        )
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              routes.removeAt(index);
                            });
                          },
                          child: const Text("Delete"),
                        ),
                        Text(
                          route["isOnline"]
                              ? "Online"
                              : "Offline",
                          style: TextStyle(
                            color: route["isOnline"]
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            })
          ],
        ),
      ),

      /// 🔥 RECTANGULAR FLOATING BUTTON
      floatingActionButton: SizedBox(
        width: 180,
        height: 50,
        child: FloatingActionButton.extended(
          backgroundColor: Colors.blue,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddNewRouteScreen(),
              ),
            );
          },
          label: const Text("Add New Route"),
        ),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerFloat,
    );
  }
}
