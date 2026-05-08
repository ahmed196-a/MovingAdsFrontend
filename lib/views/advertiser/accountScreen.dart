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

  // ── unchanged ──────────────────────────────────────────────────────────
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

  Widget _buildStars(double rating) {
    final int fullStars  = rating.floor().clamp(0, 5);
    final bool halfStar  = (rating - fullStars) >= 0.5;
    final int emptyStars = (5 - fullStars - (halfStar ? 1 : 0)).clamp(0, 5);

    return Row(
      children: [
        ...List.generate(fullStars,  (_) => const Icon(Icons.star,        color: Colors.amber, size: 18)),
        if (halfStar)                       const Icon(Icons.star_half,    color: Colors.amber, size: 18),
        ...List.generate(emptyStars, (_) => const Icon(Icons.star_border, color: Colors.amber, size: 18)),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
      ],
    );
  }
  // ───────────────────────────────────────────────────────────────────────

  String get _roleLabel => role == 'a' ? "Advertiser" : role == 'd' ? "Driver" : role;
  String get _initials  => name.trim().isEmpty ? "?" :
  name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f4f4),
      body: Column(
        children: [

          // ── HERO HEADER ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff00c4aa), Color(0xff008f7e)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  children: [
                    // Back button row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          "My Account",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 38), // balance
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Avatar
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.6), width: 2.5),
                      ),
                      child: Center(
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Role pill
                    if (role == 'a' || role == 'd')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Text(
                          _roleLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Stars
                    _buildStars(rating),
                  ],
                ),
              ),
            ),
          ),

          // ── INFO CARD ─────────────────────────────────────────────────
          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _infoRow(
                      icon: Icons.email_outlined,
                      iconColor: const Color(0xff00c4aa),
                      label: "Email",
                      value: email.isNotEmpty ? email : "—",
                      showDivider: true,
                    ),
                    _infoRow(
                      icon: Icons.badge_outlined,
                      iconColor: const Color(0xff3b82f6),
                      label: "Role",
                      value: _roleLabel.isNotEmpty ? _roleLabel : "—",
                      showDivider: true,
                    ),
                    _infoRow(
                      icon: Icons.star_rounded,
                      iconColor: Colors.amber,
                      label: "Rating",
                      value: "${rating.toStringAsFixed(1)} / 5.0",
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // ── EDIT PROFILE BUTTON ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, "/editProfile");
              },
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xff00c4aa), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_outlined,
                        color: Color(0xff00c4aa), size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff00c4aa),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── LOGOUT BUTTON ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () async {
                await UserSession.logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, "/login");
              },
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffef4444), Color(0xffc53030)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffef4444).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Logout",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // ── Info row tile ─────────────────────────────────────────────────────────
  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1a1a2e),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 68, endIndent: 18,
              color: Color(0xfff0f0f0)),
      ],
    );
  }
}