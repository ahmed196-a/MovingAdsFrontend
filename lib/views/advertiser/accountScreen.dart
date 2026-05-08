import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../UserSession.dart';


class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String name = "";
  String email = "";
  String role = "";
  double rating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name   = prefs.getString('username') ?? "Unknown";
      email  = prefs.getString('email')    ?? "";
      role   = prefs.getString('role')     ?? "";
      rating = prefs.getDouble('rating')   ?? 0.0;
    });
  }

  // ── Build star row based on rating (0–5) ─────────────────
  Widget _buildStars(double rating) {
    final int fullStars  = rating.floor().clamp(0, 5);
    final bool halfStar  = (rating - fullStars) >= 0.5;
    final int emptyStars = (5 - fullStars - (halfStar ? 1 : 0)).clamp(0, 5);

    return Row(
      children: [
        ...List.generate(fullStars,  (_) => const Icon(Icons.star,          color: Colors.amber, size: 18)),
        if (halfStar)                        const Icon(Icons.star_half,     color: Colors.amber, size: 18),
        ...List.generate(emptyStars, (_) => const Icon(Icons.star_border,   color: Colors.amber, size: 18)),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // APP BAR
      appBar: AppBar(
        backgroundColor: const Color(0xff00c4aa),
        title: const Text(
          "Account",
          style: TextStyle(color: Colors.black),
        ),
        elevation: 0,
      ),

      body: Column(
        children: [
          const SizedBox(height: 20),

          // PROFILE CARD
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AVATAR
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 32),
                ),

                const SizedBox(width: 12),

                // USER INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (role == 'a' || role == 'd')
                        Chip(
                          label: Text(role == 'a' ? "Advertiser" : "Driver"),
                          backgroundColor: Colors.teal,
                          labelStyle: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      const SizedBox(height: 4),
                      Text("Email: $email"),
                      const SizedBox(height: 6),
                      _buildStars(rating),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // EDIT PROFILE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/editProfile");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Edit Profile",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // LOGOUT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await UserSession.logout();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, "/login");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}