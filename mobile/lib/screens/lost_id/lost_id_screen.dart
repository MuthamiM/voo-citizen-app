import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LostIdScreen extends StatefulWidget {
  const LostIdScreen({super.key});

  @override
  State<LostIdScreen> createState() => _LostIdScreenState();
}

class _LostIdScreenState extends State<LostIdScreen> {
  List<dynamic> _reports = [];
  bool _isLoading = true;
  bool _showForm = false;
  bool _isSubmitting = false;
  bool _isForSelf = true;
  String _reportType = 'lost'; // 'lost' or 'found'

  // Theme colors
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color bgDark = Color(0xFF000000);
  static const Color cardDark = Color(0xFF1C1C1C);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF888888);
  static const Color inputBg = Color(0xFF2A2A2A);

  // Controllers
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  DateTime? _dateLost;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _idNumberController.dispose();
    _locationController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final phone = auth.user?['phone']?.toString() ?? '';
      if (phone.isNotEmpty) {
        final reports = await DashboardService.getLostIdReports(phone);
        if (mounted) setState(() => _reports = reports);
      }
    } catch (e) {
      debugPrint('Error loading lost ID reports: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReport() async {
    if (!_isForSelf && _ownerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID owner name is required'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.user;
      final phone = user?['phone']?.toString() ?? '';
      final name = user?['fullName'] ?? user?['full_name'] ?? '';

      await DashboardService.reportLostId(
        reporterPhone: phone,
        reporterName: name,
        idOwnerName: _isForSelf ? name : _ownerNameController.text,
        idOwnerPhone: _isForSelf ? phone : _ownerPhoneController.text,
        isForSelf: _isForSelf,
        idNumber: _idNumberController.text,
        lastSeenLocation: _locationController.text,
        dateLost: _dateLost?.toIso8601String().split('T')[0],
        additionalInfo: _additionalInfoController.text,
        status: _reportType == 'found' ? 'found' : 'pending',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lost ID reported successfully!'), backgroundColor: Colors.green),
        );
        setState(() {
          _showForm = false;
          _clearForm();
        });
        _loadReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _ownerNameController.clear();
    _ownerPhoneController.clear();
    _idNumberController.clear();
    _locationController.clear();
    _additionalInfoController.clear();
    _dateLost = null;
    _isForSelf = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        foregroundColor: textLight,
        title: const Text('Report Lost ID', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : _showForm
              ? _buildForm()
              : _buildReportsList(),
      floatingActionButton: !_showForm
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _showForm = true),
              backgroundColor: primaryOrange,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Report Lost ID', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildReportsList() {
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off, size: 80, color: textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No lost ID reports yet', style: TextStyle(color: textMuted, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Tap the button below to report a lost ID', style: TextStyle(color: textMuted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      color: primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          final status = report['status'] ?? 'pending';
          final statusColor = status == 'found' ? Colors.green : (status == 'pending' ? Colors.orange : Colors.grey);
          
          return Card(
            color: cardDark,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          report['id_owner_name'] ?? 'Unknown',
                          style: const TextStyle(color: textLight, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (report['id_number'] != null && report['id_number'].toString().isNotEmpty)
                    _buildInfoRow(Icons.badge, 'ID: ${report['id_number']}'),
                  if (report['last_seen_location'] != null)
                    _buildInfoRow(Icons.location_on, report['last_seen_location']),
                  if (report['date_lost'] != null)
                    _buildInfoRow(Icons.calendar_today, 'Lost: ${report['date_lost']}'),

                  if (status == 'found')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openWhatsAppClaim(report),
                          icon: const Icon(Icons.message, color: Colors.white),
                          label: const Text('Claim ID via WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: textMuted, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle: For Self or Other
          Container(
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _reportType = 'lost'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _reportType == 'lost' ? primaryOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Report Lost ID',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _reportType == 'lost' ? Colors.white : textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _reportType = 'found'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _reportType == 'found' ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Report Found ID',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _reportType == 'found' ? Colors.white : textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Toggle: For Self or Other (Only valid if reporting LOST ID)
          if (_reportType == 'lost')
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isForSelf = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isForSelf ? primaryOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'For Myself',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isForSelf ? Colors.white : textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isForSelf = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: !_isForSelf ? primaryOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'For Someone Else',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_isForSelf ? Colors.white : textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Owner Details (only if for someone else)

          // Owner Details (If finding someone's ID or reporting for someone else)
          if (_reportType == 'found' || !_isForSelf) ...[
            const Text('ID Owner Details', style: TextStyle(color: textLight, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildTextField(_ownerNameController, 'Full Name on ID *', Icons.person), // Found ID requires Name on ID
            const SizedBox(height: 12),
            // Phone is optional for found ID (we might not know their number)
             _buildTextField(_ownerPhoneController, _reportType == 'found' ? 'Owner Phone (Optional)' : 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 24),
          ],

          if (!_isForSelf && _reportType == 'lost') ...[
            const Text('ID Owner Details', style: TextStyle(color: textLight, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildTextField(_ownerNameController, 'Full Name *', Icons.person),
            const SizedBox(height: 12),
            _buildTextField(_ownerPhoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 24),
          ],

          const Text('ID Details', style: TextStyle(color: textLight, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildTextField(_idNumberController, 'ID Number (if known)', Icons.badge),
          const SizedBox(height: 12),
          _buildTextField(_locationController, 'Last Seen Location', Icons.location_on),
          const SizedBox(height: 12),
          
          // Date Picker
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _dateLost ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _dateLost = date);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: textMuted),
                  const SizedBox(width: 12),
                  Text(
                    _dateLost != null
                        ? '${_dateLost!.day}/${_dateLost!.month}/${_dateLost!.year}'
                        : 'Date Lost (tap to select)',
                    style: TextStyle(color: _dateLost != null ? textLight : textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(_additionalInfoController, 'Additional Info (wallet color, etc)', Icons.info_outline, maxLines: 3),
          
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _showForm = false;
                    _clearForm();
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textLight,
                    side: BorderSide(color: textMuted.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: textLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: textMuted),
        prefixIcon: Icon(icon, color: textMuted),
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryOrange, width: 2)),
      ),
    );
  }

  Future<void> _openWhatsAppClaim(dynamic report) async {
    const adminPhone = '254114945842';
    final idOwner = report['id_owner_name'] ?? 'Unknown';
    final idNumber = report['id_number'] ?? 'Unknown';
    final message = Uri.encodeComponent('Hey Admin, I want to claim ID Number: $idNumber belonging to $idOwner');
    final url = Uri.parse('https://wa.me/$adminPhone?text=$message');

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
