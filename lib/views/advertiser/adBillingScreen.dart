// ============================================================
// lib/views/advertiser/adBillingScreen.dart
//
// Advertiser taps "View Billing" from AdDetailsScreen.
// Shows:
//   • Summary card (total km / time / paid / unpaid)
//   • Daily trip rows with per-day amount
//   • "Mark Paid" button on each unpaid row
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/billing_record.dart';
import '../../models/ad_billing_summary.dart';
import '../../services/BillingApiService.dart';

class AdBillingScreen extends StatefulWidget {
  final int adId;
  final String adTitle;

  const AdBillingScreen({
    super.key,
    required this.adId,
    required this.adTitle,
  });

  @override
  State<AdBillingScreen> createState() => _AdBillingScreenState();
}

class _AdBillingScreenState extends State<AdBillingScreen> {
  List<BillingRecord> records = [];
  AdBillingSummary? summary;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        BillingApiService.getRecordsByAd(widget.adId),
        BillingApiService.getAdSummary(widget.adId),
      ]);

      setState(() {
        records = results[0] as List<BillingRecord>;
        summary = results[1] as AdBillingSummary;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _markPaid(BillingRecord record) async {
    bool success = await BillingApiService.markAsPaid(record.billId);

    if (success) {
      setState(() {
        final index = records.indexWhere((r) => r.billId == record.billId);
        if (index != -1) {
          records[index] = BillingRecord(
            billId:           record.billId,
            tripId:           record.tripId,
            adId:             record.adId,
            vehicleReg:       record.vehicleReg,
            billDate:         record.billDate,
            validDistanceKm:  record.validDistanceKm,
            validTimeMinutes: record.validTimeMinutes,
            amountDue:        record.amountDue,
            status:           'paid',
            driverName:       record.driverName,
            vehicleModel:     record.vehicleModel,
            adTitle:          record.adTitle,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Marked as paid"),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh summary
      final newSummary = await BillingApiService.getAdSummary(widget.adId);
      setState(() => summary = newSummary);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to mark as paid"),
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
        backgroundColor: const Color(0xff18B6A3),
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Billing",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
          ? const Center(child: Text("No billing records yet"))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── AD TITLE ──────────────────────────────
          Text(
            widget.adTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // ── SUMMARY CARD ─────────────────────────
          if (summary != null) _buildSummaryCard(summary!),

          const SizedBox(height: 20),

          const Text(
            "Daily Breakdown",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // ── RECORDS LIST ──────────────────────────
          ...records.map((r) => _buildRecordCard(r)),
        ],
      ),
    );
  }

  // ── Summary Card ─────────────────────────────────────────
  Widget _buildSummaryCard(AdBillingSummary s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff18B6A3),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem("Total Km", "${s.totalDistanceKm.toStringAsFixed(1)} km"),
              _summaryItem("Total Time", "${s.totalTimeMinutes.toStringAsFixed(0)} min"),
              _summaryItem("Total Days", "${s.totalDays}"),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white38, thickness: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem("Total Due", "RS ${s.totalAmountDue.toStringAsFixed(0)}"),
              _summaryItem("Paid", "RS ${s.totalPaid.toStringAsFixed(0)}"),
              _summaryItem("Unpaid", "RS ${s.totalUnpaid.toStringAsFixed(0)}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Record Card ───────────────────────────────────────────
  Widget _buildRecordCard(BillingRecord record) {
    final isPaid = record.status == 'paid';
    final statusColor = isPaid ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Date + Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat("dd MMM yyyy").format(record.billDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    record.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Driver + Vehicle
            Text(
              "${record.driverName}  •  ${record.vehicleReg}",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),

            const SizedBox(height: 10),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statChip(
                  Icons.directions_car,
                  "${record.validDistanceKm.toStringAsFixed(2)} km",
                ),
                _statChip(
                  Icons.timer,
                  "${record.validTimeMinutes.toStringAsFixed(0)} min",
                ),
                _statChip(
                  Icons.attach_money,
                  "RS ${record.amountDue.toStringAsFixed(0)}",
                  bold: true,
                ),
              ],
            ),

            // Mark Paid button — only for unpaid records
            if (!isPaid) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => _markPaid(record),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00c4aa),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("Mark as Paid"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, {bool bold = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xff18B6A3)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
