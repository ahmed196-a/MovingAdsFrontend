import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // APP BAR
      appBar: AppBar(
        backgroundColor: const Color(0xff00c4aa),
        title: const Text(
          "Stats",
          style: TextStyle(color: Colors.black),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.show_chart, color: Colors.black),
          )
        ],
      ),

      // BODY
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _statCard(
              title: "Active Ads",
              value: "2",
              icon: Icons.assignment_turned_in,
              iconColor: Colors.blue,
            ),
            _statCard(
              title: "Drivers",
              value: "2",
              icon: Icons.directions_car,
              iconColor: Colors.black,
            ),
            _statCard(
              title: "Total Spent",
              value: "RS 1000",
              icon: Icons.attach_money,
              iconColor: Colors.green,
            ),
            _statCard(
              title: "Total Ads",
              value: "3",
              icon: Icons.campaign,
              iconColor: Colors.orange,
            ),
          ],
        ),
      ),

      // BOTTOM NAV
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: currentIndex,
      //   onTap: (index) {
      //     if (index == currentIndex) return;
      //
      //     if (index == 0) {
      //       Navigator.pushReplacementNamed(context, "/home");
      //     } else if (index == 2) {
      //       Navigator.pushReplacementNamed(context, "/myAds");
      //     }
      //   },
      //   selectedItemColor: Colors.black,
      //   unselectedItemColor: Colors.black54,
      //   items: const [
      //     BottomNavigationBarItem(
      //         icon: Icon(Icons.home), label: "Home"),
      //     BottomNavigationBarItem(
      //         icon: Icon(Icons.bar_chart), label: "Stats"),
      //     BottomNavigationBarItem(
      //         icon: Icon(Icons.receipt), label: "My Ads"),
      //     BottomNavigationBarItem(
      //         icon: Icon(Icons.person), label: "Account"),
      //   ],
      // ),
    );
  }

  // STAT CARD WIDGET
  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, color: Colors.teal)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
        ],
      ),
    );
  }
}
