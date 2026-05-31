import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/widgets/custom_image.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/auth/controller/address_controller.dart';
import 'package:uae_ecom_project/features/auth/model/address_model.dart';
import 'package:uae_ecom_project/features/orders/controller/checkout_controller.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/auth/model/user_model.dart';
import 'package:uae_ecom_project/features/auth/widgets/otp_verification_dialog.dart';
import 'package:uae_ecom_project/features/auth/widgets/google_map_picker.dart';

class AddAddressDialog extends StatefulWidget {
  const AddAddressDialog({super.key});

  @override
  State<AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<AddAddressDialog> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'home';
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _buildingController = TextEditingController();
  final _flatVillaController = TextEditingController();
  final _streetController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  String? _emirate;
  bool _isDefault = false;
  double? _lat;
  double? _lng;

  String _selectedCountryCode = '+971';

  final List<Map<String, dynamic>> _countries = [
    {
      'name': 'UAE',
      'code': '+971',
      'flag': '🇦🇪',
      'hint': 'phone_hint_uae',
      'maxLength': 9,
      'pattern': r'^(50|52|54|55|56|58)\d{7}$',
      'key': 'uae',
    },
  ];

  // Emirates defined with slug values (matching React implementation)
  static const List<Map<String, dynamic>> _emiratesData = [
    {'value': 'abu_dhabi', 'label': 'Abu Dhabi', 'available': true},
    {'value': 'dubai', 'label': 'Dubai', 'available': false},
    {'value': 'sharjah', 'label': 'Sharjah', 'available': false},
    {'value': 'ajman', 'label': 'Ajman', 'available': false},
    {'value': 'umm_al_quwain', 'label': 'Umm Al Quwain', 'available': false},
    {'value': 'ras_al_khaimah', 'label': 'Ras Al Khaimah', 'available': false},
    {'value': 'fujairah', 'label': 'Fujairah', 'available': false},
  ];

  /// Normalizes a raw geocoded emirate string to a slug.
  /// Mirrors the React logic: toLowerCase → replace non-alpha with '_' → trim '_'
  static String _normalizeEmirate(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  /// Tries to match a normalized slug against known emirate entries.
  /// Returns the slug if matched, or null.
  static String? _matchEmirate(String rawEmirate) {
    final normalized = _normalizeEmirate(rawEmirate);
    for (final e in _emiratesData) {
      final slug = e['value'] as String;
      final label = e['label'] as String;
      // Direct slug match
      if (normalized == slug) return slug;
      // Match against normalized label (e.g. 'abu_dhabi' == 'abu_dhabi')
      if (normalized == _normalizeEmirate(label)) return slug;
      // Partial containment (e.g. 'abu_dhabi_emirate' contains 'abu_dhabi')
      if (normalized.contains(slug) || slug.contains(normalized)) return slug;
    }
    return null;
  }

  bool _showErrors = false;

  bool get _isPhoneValid {
    final country = _countries.firstWhere(
      (c) => c['code'] == _selectedCountryCode,
    );
    final pattern = country['pattern'] as String;
    return RegExp(pattern).hasMatch(_phoneController.text.trim());
  }

  bool get _isNameValid {
    return _nameController.text.trim().length >= 3;
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill phone if verified
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      final user = auth.currentUser;
      if (user != null && user.isPhoneVerified && user.phoneNumber != null) {
        _populateFromFullPhone(user.phoneNumber!);
      }
    });
  }

  void _populateFromFullPhone(String fullPhone) {
    if (fullPhone.isEmpty) return;

    // Try to match country code from our supported list
    for (final country in _countries) {
      final code = country['code']!;
      if (fullPhone.startsWith(code)) {
        setState(() {
          _selectedCountryCode = code;
          _phoneController.text = fullPhone.substring(code.length);
        });
        return;
      }
    }

    // Fallback: if no code matches, just put everything in the controller
    setState(() {
      _phoneController.text = fullPhone;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _buildingController.dispose();
    _flatVillaController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final isPhoneVerified = user?.isPhoneVerified ?? false;
    // The field is locked until the user's primary phone number is verified.
    final isLocked = !isPhoneVerified;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr(context, 'address_add_title').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 0),

              // Google Map Picker
              _buildLabel(tr(context, 'address_location_on_map')),
              GoogleMapPicker(
                onSelect: (result) {
                  setState(() {
                    _lat = result.lat;
                    _lng = result.lng;

                    if (result.street != null) {
                      _streetController.text = result.street!;
                    }
                    if (result.area != null) {
                      _areaController.text = result.area!;
                    }
                    if (result.city != null) {
                      _cityController.text = result.city!;
                    }

                    // Normalize the geocoded emirate to a slug and match
                    if (result.emirate != null && result.emirate!.isNotEmpty) {
                      final matched = _matchEmirate(result.emirate!);
                      _emirate = matched; // may be null if completely unrecognized
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              // Grid Layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Type, Building, Street, City, Emirate
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(tr(context, 'address_type_label')),
                        _buildDropdown(
                          value: _type,
                          items: ['home', 'work', 'other'],
                          itemLabelBuilder: (v) =>
                              tr(context, 'address_type_${v.toLowerCase()}'),
                          onChanged: (v) => setState(() => _type = v!),
                        ),
                        const SizedBox(height: 16),
                        _buildLabel(tr(context, 'address_building_label')),
                        _buildTextField(
                          controller: _buildingController,
                          hintText: tr(context, 'address_building_hint'),
                          validator: (v) =>
                              v!.isEmpty ? tr(context, 'required') : null,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel(tr(context, 'address_street_label')),
                        _buildTextField(
                          controller: _streetController,
                          hintText: tr(context, 'address_street_hint'),
                          validator: (v) =>
                              v!.isEmpty ? tr(context, 'required') : null,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel(tr(context, 'address_city_label')),
                        _buildTextField(
                          controller: _cityController,
                          hintText: tr(context, 'address_city_hint'),
                          validator: (v) =>
                              v!.isEmpty ? tr(context, 'required') : null,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel(tr(context, 'address_emirate_label')),
                        _buildDropdown(
                          value: _emirate,
                          hint: 'Select emirate',
                          items: _emiratesData.map((e) => e['value'] as String).toList(),
                          itemLabelBuilder: (v) {
                            final entry = _emiratesData.firstWhere(
                              (e) => e['value'] == v,
                              orElse: () => {'label': v},
                            );
                            return entry['label'] as String;
                          },
                          disabledItems: _emiratesData
                              .where((e) => e['available'] != true)
                              .map((e) => e['value'] as String)
                              .toList(),
                          errorText: _showErrors
                              ? (_emirate == null
                                  ? 'Please select an emirate'
                                  : (_emirate != 'abu_dhabi'
                                      ? 'Delivery is currently available only in Abu Dhabi.'
                                      : null))
                              : null,
                          onChanged: (v) {
                            // Only allow selecting Abu Dhabi
                            if (v == 'abu_dhabi') {
                              setState(() => _emirate = v!);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Right Column: Full Name, Flat/Villa, Area, Phone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(tr(context, 'address_name_label')),
                        _buildTextField(
                          controller: _nameController,
                          hintText: tr(context, 'address_name_hint'),
                          validator: (v) {
                            if (v!.isEmpty) return tr(context, 'required');
                            if (!_isNameValid) {
                              return tr(context, 'address_name_min_length');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildLabel(tr(context, 'address_flat_label')),
                        _buildTextField(
                          controller: _flatVillaController,
                          hintText: tr(context, 'address_flat_hint'),
                          validator: (v) =>
                              v!.isEmpty ? tr(context, 'required') : null,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel(tr(context, 'address_area_label')),
                        _buildTextField(
                          controller: _areaController,
                          hintText: tr(context, 'address_area_hint'),
                          validator: (v) =>
                              v!.isEmpty ? tr(context, 'required') : null,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel(tr(context, 'address_phone_label')),
                        _buildPhoneField(
                          theme,
                          isLocked,
                          isPhoneVerified,
                          user,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Checkbox(
                              value: _isDefault,
                              onChanged: (v) => setState(() => _isDefault = v!),
                              activeColor: AppColors.primary,
                            ),
                            Expanded(
                              child: Text(
                                tr(context, 'address_set_default'),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          tr(context, 'address_save_btn'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.grey.shade700,
                        ),
                        child: Text(tr(context, 'cancel')),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String)? itemLabelBuilder,
    List<String> disabledItems = const [],
    String? hint,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null ? Colors.red : Colors.grey.shade200,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: hint != null
                  ? Text(
                      hint,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    )
                  : null,
              items: items
                  .map(
                    (e) {
                      final isDisabled = disabledItems.contains(e);
                      return DropdownMenuItem(
                        value: e,
                        enabled: !isDisabled,
                        child: Text(
                          itemLabelBuilder != null ? itemLabelBuilder(e) : e,
                          style: TextStyle(
                            color: isDisabled ? Colors.grey.shade400 : Colors.black87,
                            fontWeight: e == 'Abu Dhabi' ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  )
                  .toList(),
              onChanged: onChanged,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 16),
            child: Text(
              errorText,
              style: const TextStyle(fontSize: 10, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    Widget? prefix,
    BoxConstraints? prefixIconConstraints,
    bool readOnly = false,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      autovalidateMode: _showErrors
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: prefix,
        prefixIconConstraints: prefixIconConstraints,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 10, color: Colors.red),
      ),
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildPhoneField(
    ThemeData theme,
    bool isLocked,
    bool isPhoneVerified,
    UserModel? user,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _phoneController,
          hintText: tr(
            context,
            _countries.firstWhere(
              (c) => c['code'] == _selectedCountryCode,
            )['hint']!,
          ),
          keyboardType: TextInputType.phone,
          readOnly: isLocked,
          maxLength:
              _countries.firstWhere(
                    (c) => c['code'] == _selectedCountryCode,
                  )['maxLength']
                  as int,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(
              _countries.firstWhere(
                    (c) => c['code'] == _selectedCountryCode,
                  )['maxLength']
                  as int,
            ),
          ],
          validator: (v) {
            if (v!.isEmpty) return tr(context, 'required');
            if (!_isPhoneValid) return tr(context, 'address_phone_invalid');
            return null;
          },
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          prefix: Container(
            margin: const EdgeInsets.only(right: 0),
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getFlagIcon('UAE'),
                  const SizedBox(width: 6),
                  const Text('+971', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 16,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isPhoneVerified) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              if (user != null) {
                final phone =
                    '$_selectedCountryCode${_phoneController.text.trim()}';
                showDialog(
                  context: context,
                  builder: (context) => OtpVerificationDialog(
                    type: 'phone',
                    currentValue: phone.length > _selectedCountryCode.length
                        ? phone
                        : (user.phoneNumber ?? ''),
                    userId: user.id,
                    onVerified: (identifier) async {
                      await context.read<AuthController>().refreshProfile();
                      // Auto-populate the form with the newly verified phone
                      if (mounted) {
                        _populateFromFullPhone(identifier);
                      }
                    },
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 14,
                    color: AppColors.actionBlue,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Verify your phone number to add an alternative number.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.actionBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (isPhoneVerified) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              tr(context, 'checkout_add_alt_phone'),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _getFlagIcon(String countryName) {
    String flagUrl;
    if (countryName == 'UAE') {
      flagUrl = 'https://flagcdn.com/w40/ae.png';
    } else if (countryName == 'India') {
      flagUrl = 'https://flagcdn.com/w40/in.png';
    } else if (countryName == 'China') {
      flagUrl = 'https://flagcdn.com/w40/cn.png';
    } else {
      return const Icon(Icons.flag, size: 16);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: CustomImage(
        flagUrl,
        width: 20,
        height: 14,
        fit: BoxFit.cover,
      ),
    );
  }

  void _submit() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    final isPhoneVerified = user?.isPhoneVerified ?? false;

    if (!isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'checkout_verify_primary')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _showErrors = true;
    });

    if (_emirate == null || _emirate != 'abu_dhabi') {
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Split Full Name into First and Last
      String fullName = _nameController.text.trim();
      List<String> nameParts = fullName.split(' ');
      String fName = nameParts.length > 1
          ? nameParts.sublist(0, nameParts.length - 1).join(' ')
          : fullName;
      String lName = nameParts.length > 1
          ? nameParts.last
          : '.'; // Better fallback for backend validation

      // Construction: Flat/Villa, Building, Street Address
      final line1 =
          '${_flatVillaController.text}, ${_buildingController.text}, ${_streetController.text}';

      final address = AddressModel(
        type: _type,
        firstName: fName,
        lastName: lName,
        phoneNumber:
            '$_selectedCountryCode${_phoneController.text.replaceAll(RegExp(r'[^0-9]'), '')}', // Prepended country code
        line1: line1,
        line2: _areaController.text,
        city: _cityController.text,
        state: _emirate == 'abu_dhabi' ? 'Abu Dhabi' : (_emirate ?? ''),
        postalCode: '00000',
        country: 'UAE',
        isDefault: _isDefault,
        latitude: _lat,
        longitude: _lng,
      );

      final addressController = context.read<AddressController>();
      final checkoutController = context.read<CheckoutController>();

      final success = await addressController.addAddress(address);
      if (success) {
        if (addressController.selectedAddress != null) {
          checkoutController.selectAddress(
            addressController.selectedAddress!.id!,
          );
        }
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'failed_to_add_address')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
