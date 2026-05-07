import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:el_moza3/Constants.dart';
import 'package:el_moza3/services/listing_service.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _category = "Services";
  String _type = "Offering Service";
  String _location = "Cairo";
  bool _loading = false;

  // Country code picker - default to Egypt
  String _countryCode = '+20';
  String? _phoneError;

  // Arab countries for the picker
  static final List<Map<String, String>> _arabCountries = [
    {'name': 'مصر', 'code': '+20', 'flag': '🇪🇬'},
    {'name': 'السعودية', 'code': '+966', 'flag': '🇸🇦'},
    {'name': 'الإمارات', 'code': '+971', 'flag': '🇦🇪'},
    {'name': 'الكويت', 'code': '+965', 'flag': '🇰🇼'},
    {'name': 'قطر', 'code': '+974', 'flag': '🇶🇦'},
    {'name': 'البحرين', 'code': '+973', 'flag': '🇧🇭'},
    {'name': 'عمان', 'code': '+968', 'flag': '🇴🇲'},
    {'name': 'الأردن', 'code': '+962', 'flag': '🇯🇴'},
    {'name': 'لبنان', 'code': '+961', 'flag': '🇱🇧'},
    {'name': 'العراق', 'code': '+964', 'flag': '🇮🇶'},
    {'name': 'الجزائر', 'code': '+213', 'flag': '🇩🇿'},
    {'name': 'تونس', 'code': '+216', 'flag': '🇹🇳'},
    {'name': 'المغرب', 'code': '+212', 'flag': '🇲🇦'},
    {'name': 'السودان', 'code': '+249', 'flag': '🇸🇩'},
    {'name': 'اليمن', 'code': '+967', 'flag': '🇾🇪'},
  ];

  final List<String> _categories = [
    "Services",
    "Manufacturing",
    "Contracting",
    "Logistics",
  ];

  final List<String> _types = ["Offering Service", "Looking for Service"];

  final List<String> _locations = [
    "Cairo",
    "Giza",
    "Alexandria",
    "Mansoura",
    "Tanta",
    "Port Said",
    "Suez",
    "Luxor",
    "Aswan",
    "Other",
  ];

  Future<void> _submit() async {
    // Validation
    if (_titleCtrl.text.trim().isEmpty) {
      _showError('اكتب العنوان');
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _showError('اكتب الوصف');
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _showError('Please enter a phone number');
      return;
    }

    // Validate phone number
    final phoneValidation = _validatePhone(
      _phoneCtrl.text.trim(),
      _countryCode,
    );
    if (phoneValidation != null) {
      setState(() => _phoneError = phoneValidation);
      return;
    }

    setState(() => _loading = true);

    try {
      // Normalize and combine country code with phone number
      final normalized = _normalizePhone(_phoneCtrl.text.trim(), _countryCode);
      final fullPhone = '$_countryCode$normalized';

      final err = await ListingService.addListing(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        type: _type,
        price: _priceCtrl.text.trim().isEmpty
            ? "Negotiable"
            : _priceCtrl.text.trim(),
        location: _location,
        phone: fullPhone,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (err != null) {
        _showError(err);
      } else {
        _showSuccess('تم نشر إعلانك!');
        _clearForm();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('An error occurred. Please try again.');
    }
  }

  void _clearForm() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _priceCtrl.clear();
    _phoneCtrl.clear();
    setState(() {
      _category = "Services";
      _type = "Offering Service";
      _location = "Cairo";
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusSmall),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusSmall),
      ),
    );
  }

  /// Validate phone number based on country code
  String? _validatePhone(String phone, String countryCode) {
    // Remove any spaces or dashes
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');

    // Check minimum length
    if (cleanPhone.length < 8) {
      return 'رقم الهاتف قصير جداً';
    }

    // Check maximum length
    if (cleanPhone.length > 15) {
      return 'رقم الهاتف طويل جداً';
    }

    // Egypt: local input 011xxxxxxx (11 digits) -> normalized 10 digits
    if (countryCode == '+20') {
      // User may enter 011... (11 digits) or 11... (10 digits)
      if (cleanPhone.length == 11 && cleanPhone.startsWith('0')) {
        // Valid - will be normalized to 10 digits
      } else if (cleanPhone.length == 10 &&
          RegExp(r'^[1][0-9]\d{8}$').hasMatch(cleanPhone)) {
        // Also valid - already normalized
      } else {
        return 'رقم مصر غير صحيح (مثال: 01xxxxxxxxx)';
      }
    }

    // For Saudi Arabia (+966), should be 9 digits starting with 5
    if (countryCode == '+966') {
      if (!RegExp(r'^5\d{8}$').hasMatch(cleanPhone)) {
        return 'رقم السعودية غير صحيح (مثال: 05xxxxxxxx)';
      }
    }

    // For UAE (+971), should be 9 digits starting with 5
    if (countryCode == '+971') {
      if (!RegExp(r'^5[0-9]\d{7}$').hasMatch(cleanPhone)) {
        return 'رقم الإمارات غير صحيح (مثال: 050xxxxxxx)';
      }
    }

    // Generic check - should be mostly digits
    if (!RegExp(r'^\d+$').hasMatch(cleanPhone)) {
      return 'رقم الهاتف يجب أن يحتوي على أرقام فقط';
    }

    return null;
  }

  /// Normalize phone number for storage (Egypt: 011... -> 10... removing leading 0)
  String _normalizePhone(String phone, String countryCode) {
    final clean = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (countryCode == '+20' && clean.length == 11 && clean.startsWith('0')) {
      // Remove leading 0: 011... -> 11...
      return clean.substring(1);
    }
    return clean;
  }

  /// Show country picker bottom sheet
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'اختر الدولة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _arabCountries.length,
                itemBuilder: (context, index) {
                  final country = _arabCountries[index];
                  final isSelected = country['code'] == _countryCode;
                  return ListTile(
                    leading: Text(
                      country['flag']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(country['name']!),
                    subtitle: Text(country['code']!),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() => _countryCode = country['code']!);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background2,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'إضافة إعلان',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // العنوان
            _buildLabel('العنوان *'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleCtrl,
              hint: 'اكتب عنوان الإعلان',
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // الوصف
            _buildLabel('الوصف *'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descCtrl,
              hint: 'صف خدمتك...',
              maxLines: 4,
              maxLength: 1000,
            ),
            const SizedBox(height: 16),

            // التصنيف
            _buildLabel('التصنيف'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _category,
              items: _categories,
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),

            // النوع
            _buildLabel('النوع'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _type,
              items: _types,
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),

            // السعر
            _buildLabel('السعر (EGP)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _priceCtrl,
              hint: 'اكتب السعر (numbers only)',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // الموقع
            _buildLabel('الموقع'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _location,
              items: _locations,
              onChanged: (v) => setState(() => _location = v!),
            ),
            const SizedBox(height: 16),

            // Phone with country code
            _buildLabel('رقم الهاتف *'),
            const SizedBox(height: 8),
            Row(
              children: [
                // Country code selector
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppBorders.radiusMedium,
                      boxShadow: AppShadows.small,
                      border: Border.all(
                        color: _phoneError != null
                            ? AppColors.error
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Get flag for current country
                        Text(
                          _arabCountries.firstWhere(
                            (c) => c['code'] == _countryCode,
                            orElse: () => _arabCountries.first,
                          )['flag']!,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _countryCode,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Phone number input
                Expanded(
                  child: _buildTextField(
                    controller: _phoneCtrl,
                    hint: _countryCode == '+20' ? '01xxxxxxxxx' : 'رقم الهاتف',
                    keyboardType: TextInputType.phone,
                    errorText: _phoneError,
                    onChanged: (value) {
                      // Clear error when user starts typing
                      if (_phoneError != null) {
                        setState(() => _phoneError = null);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.radiusMedium,
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'نشر الإعلان',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorders.radiusMedium,
        boxShadow: AppShadows.small,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          counterText: "",
          errorText: hasError ? errorText : null,
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorders.radiusMedium,
        boxShadow: AppShadows.small,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
