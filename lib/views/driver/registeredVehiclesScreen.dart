import 'package:ads_frontend/views/driver/registerVehicle.dart';
import 'package:ads_frontend/views/driver/vehicleScheduleScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/vehicle.dart';
import '../../services/VehicleApiService.dart';


class RegisteredVehiclesScreen extends StatefulWidget {
  const RegisteredVehiclesScreen({super.key});

  @override
  State<RegisteredVehiclesScreen> createState() =>
      _RegisteredVehiclesScreenState();
}

class _RegisteredVehiclesScreenState
    extends State<RegisteredVehiclesScreen> {
  late Future<List<Vehicle>> vehiclesFuture;
  int? userid;

  @override
  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    userid = prefs.getInt('userId');

    if (userid != null) {
      setState(() {
        vehiclesFuture = VehicleApiService.fetchVehicles(userid!);
      });
    }
  }


  void refresh() {
    setState(() {
     _loadVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        title: const Text("Registered Vehicles"),
        backgroundColor: const Color(0xff18B6A3),
        elevation: 0,
      ),

      body: SafeArea(
        child: FutureBuilder<List<Vehicle>>(
          future: vehiclesFuture,
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

            final vehicles = snapshot.data!;

            if (vehicles.isEmpty) {
              return const Center(
                child: Text("No vehicles registered."),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];

                return Container(
                  margin:
                  const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff7DB9B3),
                    borderRadius:
                    BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6)
                    ],
                  ),
                  child: Row(
                    children: [

                      // 🚗 Placeholder Image
                      Container(
                        height: 70,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            vehicle.MediaPath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,

                            // 🔄 Loading indicator
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },

                            // ❌ If image fails, show car icon
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.directions_car,
                                size: 40,
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 🔥 Vehicle Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.vehicleModel,
                              style: const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(vehicle.vehicleReg),
                            const SizedBox(height: 4),
                            Text(vehicle.vehicleType),
                          ],
                        ),
                      ),

                      // 🗑 Delete Icon (UI Only)
                      const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.schedule,
                          size: 22,
                          color: Colors.blue,
                        ),
                        onPressed:
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  VehicleScheduleScreen(
                                      vehicleReg:
                                      vehicle.vehicleReg),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),

      // ➕ Floating Add Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff18B6A3),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddVehicleScreen(),
            ),
          );

          refresh();
        },
      ),
    );
  }
}
