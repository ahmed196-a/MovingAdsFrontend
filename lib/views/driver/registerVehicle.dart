import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/VehicleApiService.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() =>
      _AddVehicleScreenState();
}

class _AddVehicleScreenState
    extends State<AddVehicleScreen> {

  final regController = TextEditingController();
  final modelController = TextEditingController();
  final typeController = TextEditingController();

  File? selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;

  // ================= PICK IMAGE =================

  Future<void> pickImage() async {
    final XFile? file =
    await _picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() {
        selectedImage = File(file.path);
      });
    }
  }

  // ================= REGISTER VEHICLE =================

  Future<void> registerVehicle() async {

    if (selectedImage == null ||
        regController.text.isEmpty ||
        modelController.text.isEmpty ||
        typeController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all required fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    bool success =
    await VehicleApiService.registerVehicle2(
      vehicleReg: regController.text,
      vehicleModel: modelController.text,
      vehicleType: typeController.text,
      vehicleOwner: userId,
      mediaFile: selectedImage!,
      mediaType: "image",
    );

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vehicle Registered")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration failed")),
      );
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xff00c4aa),
        title: const Text("Register Vehicle",
            style: TextStyle(color: Colors.black)),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // MAIN CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Vehicle Image*",
                    style:
                    TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey.shade300),
                      ),
                      child: selectedImage == null
                          ? const Center(
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload,
                                size: 40),
                            SizedBox(height: 8),
                            Text(
                                "Upload Vehicle Image"),
                          ],
                        ),
                      )
                          : ClipRRect(
                        borderRadius:
                        BorderRadius.circular(12),
                        child: Image.file(
                          selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _textField("Registration Number*", regController),
                  const SizedBox(height: 12),

                  _textField("Vehicle Model*", modelController),
                  const SizedBox(height: 12),

                  _textField("Vehicle Type*", typeController),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                isLoading ? null : registerVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                    color: Colors.white)
                    : const Text("Register Vehicle"),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.grey.shade300,
                  foregroundColor: Colors.black,
                ),
                child: const Text("Cancel"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TEXT FIELD =================

  Widget _textField(
      String label,
      TextEditingController controller,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
