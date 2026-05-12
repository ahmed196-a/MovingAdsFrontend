import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/billingApiService.dart';


class BillingScreen extends StatefulWidget {
  final int agencyId;

  const BillingScreen({super.key, required this.agencyId});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  // ── state ────────────────────────────────────────────────────
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _successMessage;

  double? _currentAdvertiserRate;
  double? _currentDriverRate;
  bool _hasExistingRecord = false;

  // ── controllers ──────────────────────────────────────────────
  final _advertiserCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  @override
  void dispose() {
    _advertiserCtrl.dispose();
    _driverCtrl.dispose();
    super.dispose();
  }

  // ── load both rates ──────────────────────────────────────────
  Future<void> _loadRates() async {
    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      // Fetch both in parallel
      final results = await Future.wait([
        BillingApiService.getAdvertiserRate(widget.agencyId)
            .then<double?>((r) => r.advertiserRate)
            .catchError((_) => null),
        BillingApiService.getDriverRate(widget.agencyId)
            .then<double?>((r) => r.driverRate)
            .catchError((_) => null),
      ]);

      final advRate = results[0];
      final drvRate = results[1];

      _hasExistingRecord = advRate != null || drvRate != null;

      setState(() {
        _currentAdvertiserRate = advRate;
        _currentDriverRate = drvRate;
        _advertiserCtrl.text =
        advRate != null ? advRate.toStringAsFixed(2) : '';
        _driverCtrl.text =
        drvRate != null ? drvRate.toStringAsFixed(2) : '';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── save / update both rates ─────────────────────────────────
  Future<void> _saveRates() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final advRate = double.parse(_advertiserCtrl.text.trim());
      final drvRate = double.parse(_driverCtrl.text.trim());

      final msg = await BillingApiService.setRates(
        agencyId: widget.agencyId,
        advertiserRate: advRate,
        driverRate: drvRate,
      );

      setState(() {
        _currentAdvertiserRate = advRate;
        _currentDriverRate = drvRate;
        _hasExistingRecord = true;
        _successMessage = msg;
        _saving = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  // ── update advertiser rate only ──────────────────────────────
  Future<void> _updateAdvertiserRate() async {
    final text = _advertiserCtrl.text.trim();
    final rate = double.tryParse(text);
    if (rate == null || rate < 0) {
      _showSnack('Enter a valid advertiser rate.', isError: true);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final msg = await BillingApiService.updateAdvertiserRate(
        agencyId: widget.agencyId,
        advertiserRate: rate,
      );
      setState(() {
        _currentAdvertiserRate = rate;
        _successMessage = msg;
        _saving = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  // ── update driver rate only ──────────────────────────────────
  Future<void> _updateDriverRate() async {
    final text = _driverCtrl.text.trim();
    final rate = double.tryParse(text);
    if (rate == null || rate < 0) {
      _showSnack('Enter a valid driver rate.', isError: true);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final msg = await BillingApiService.updateDriverRate(
        agencyId: widget.agencyId,
        driverRate: rate,
      );
      setState(() {
        _currentDriverRate = rate;
        _successMessage = msg;
        _saving = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xff00c4aa),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: Column(
        children: [
          // ── HEADER ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            color: const Color(0xff00c4aa),
            child: const Column(
              children: [
                Text(
                  'Billing Rates',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage advertiser & driver hourly rates',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),

          // ── BODY ──────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xff00c4aa)),
            )
                : RefreshIndicator(
              color: const Color(0xff00c4aa),
              onRefresh: _loadRates,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Status banners ─────────────────
                      if (_successMessage != null)
                        _banner(
                          message: _successMessage!,
                          color: const Color(0xff00c4aa),
                          icon: Icons.check_circle_outline,
                        ),
                      if (_error != null)
                        _banner(
                          message: _error!,
                          color: Colors.red,
                          icon: Icons.error_outline,
                        ),

                      // ── Current rates summary ──────────
                      if (_hasExistingRecord) ...[
                        const SizedBox(height: 4),
                        _summaryCard(),
                        const SizedBox(height: 20),
                      ] else
                        const SizedBox(height: 8),

                      // ── Advertiser rate card ───────────
                      _rateCard(
                        title: 'Advertiser Rate',
                        subtitle: 'Amount charged to advertiser per hour',
                        icon: Icons.business_center_outlined,
                        iconColor: const Color(0xff00c4aa),
                        controller: _advertiserCtrl,
                        hintText: 'e.g. 150.00',
                        currentValue: _currentAdvertiserRate,
                        onUpdateTap: _hasExistingRecord
                            ? _updateAdvertiserRate
                            : null,
                      ),

                      const SizedBox(height: 16),

                      // ── Driver rate card ───────────────
                      _rateCard(
                        title: 'Driver Rate',
                        subtitle: 'Amount paid to driver per hour',
                        icon: Icons.directions_car_outlined,
                        iconColor: Colors.black87,
                        controller: _driverCtrl,
                        hintText: 'e.g. 80.00',
                        currentValue: _currentDriverRate,
                        onUpdateTap:
                        _hasExistingRecord ? _updateDriverRate : null,
                      ),

                      const SizedBox(height: 28),

                      // ── Primary action button ──────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveRates,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff00c4aa),
                            disabledBackgroundColor:
                            const Color(0xff00c4aa).withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _saving
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Text(
                            _hasExistingRecord
                                ? 'Update Both Rates'
                                : 'Set Rates',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Helper note ────────────────────
                      Center(
                        child: Text(
                          _hasExistingRecord
                              ? 'Use individual "Update" buttons to change one rate at a time.'
                              : 'No billing record yet. Fill both fields and tap Set Rates.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── summary card ─────────────────────────────────────────────
  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              label: 'Advertiser Rate',
              value: _currentAdvertiserRate != null
                  ? 'R ${_currentAdvertiserRate!.toStringAsFixed(2)}/hr'
                  : '—',
              icon: Icons.business_center_outlined,
              valueColor: const Color(0xff00c4aa),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _summaryItem(
              label: 'Driver Rate',
              value: _currentDriverRate != null
                  ? 'R ${_currentDriverRate!.toStringAsFixed(2)}/hr'
                  : '—',
              icon: Icons.directions_car_outlined,
              valueColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  // ── rate input card ──────────────────────────────────────────
  Widget _rateCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required String hintText,
    double? currentValue,
    VoidCallback? onUpdateTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // text field + optional update button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    hintText: hintText,
                    prefixText: 'R ',
                    filled: true,
                    fillColor: const Color(0xfff5f5f5),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xff00c4aa), width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Invalid number';
                    }
                    if (double.parse(value.trim()) < 0) {
                      return 'Must be ≥ 0';
                    }
                    return null;
                  },
                ),
              ),

              // Only show individual update button when record exists
              if (onUpdateTap != null) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : onUpdateTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── banner widget ────────────────────────────────────────────
  Widget _banner({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _successMessage = null;
              _error = null;
            }),
            child: Icon(Icons.close, size: 16, color: color),
          ),
        ],
      ),
    );
  }
}