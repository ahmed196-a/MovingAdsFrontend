// Advertiser sets or updates the billing rate for an ad.
// Linked from AdDetailsScreen.
// ============================================================
import 'package:flutter/material.dart';
import '../../models/billing_rate.dart';
import '../../services/BillingApiService.dart';

class SetBillingRateScreen extends StatefulWidget {
  final int adId;
  final String adTitle;

  const SetBillingRateScreen({
    super.key,
    required this.adId,
    required this.adTitle,
  });

  @override
  State<SetBillingRateScreen> createState() => _SetBillingRateScreenState();
}

class _SetBillingRateScreenState extends State<SetBillingRateScreen> {
  String selectedRateType = 'per_km';
  final ratePerKmController  = TextEditingController();
  final ratePerMinController = TextEditingController();

  bool isLoading = true;
  bool hasSaved  = false;
  int? existingRateId;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final existing = await BillingApiService.getRate(widget.adId);
      if (existing != null) {
        setState(() {
          selectedRateType       = existing.rateType;
          ratePerKmController.text  = existing.ratePerKm.toString();
          ratePerMinController.text = existing.ratePerMin.toString();
          existingRateId         = existing.rateId;
          hasSaved               = true;
        });
      }
    } catch (_) {}

    setState(() => isLoading = false);
  }

  Future<void> _save() async {
    final perKm  = double.tryParse(ratePerKmController.text)  ?? 0;
    final perMin = double.tryParse(ratePerMinController.text) ?? 0;

    if (selectedRateType == 'per_km' && perKm <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid rate per km")),
      );
      return;
    }
    if (selectedRateType == 'per_minute' && perMin <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid rate per minute")),
      );
      return;
    }
    if (selectedRateType == 'both' && (perKm <= 0 || perMin <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter both rates")),
      );
      return;
    }

    final rate = BillingRate(
      rateId:     existingRateId ?? 0,
      adId:       widget.adId,
      rateType:   selectedRateType,
      ratePerKm:  perKm,
      ratePerMin: perMin,
    );

    bool success;
    if (hasSaved) {
      success = await BillingApiService.updateRate(widget.adId, rate);
    } else {
      success = await BillingApiService.createRate(rate);
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Billing rate saved"),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => hasSaved = true);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to save rate"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        backgroundColor: const Color(0xff00c4aa),
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Billing Rate",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              widget.adTitle,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // ── Rate Type Selector ───────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Billing Method",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Rate type buttons
                  Row(
                    children: [
                      _rateTypeBtn('per_km',     'Per KM'),
                      const SizedBox(width: 8),
                      _rateTypeBtn('per_minute', 'Per Minute'),
                      const SizedBox(width: 8),
                      _rateTypeBtn('both',       'Both'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Per KM field
                  if (selectedRateType == 'per_km' ||
                      selectedRateType == 'both') ...[
                    const Text("Rate Per KM (RS)"),
                    const SizedBox(height: 6),
                    TextField(
                      controller: ratePerKmController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "e.g. 5.00",
                        prefixText: "RS  ",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Per Minute field
                  if (selectedRateType == 'per_minute' ||
                      selectedRateType == 'both') ...[
                    const Text("Rate Per Minute (RS)"),
                    const SizedBox(height: 6),
                    TextField(
                      controller: ratePerMinController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "e.g. 0.50",
                        prefixText: "RS  ",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Save Button ──────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff00c4aa),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  hasSaved ? "Update Rate" : "Save Rate",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateTypeBtn(String type, String label) {
    final isSelected = selectedRateType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRateType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xff00c4aa)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? Colors.black : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
