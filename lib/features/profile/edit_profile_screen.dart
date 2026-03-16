import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/auth/model/user_model.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _businessNameController;
  late TextEditingController _pincodeController;

  String? _selectedGender;
  String? _selectedOccupation;

  DateTime? _selectedDob;
  String _preferredLanguageCode = 'en';

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _occupations = ['Student', 'Professional', 'Business Owner', 'Other'];

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    final user = context.read<AuthController>().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber);
    _emailController = TextEditingController(text: user?.email);
    
    _businessNameController = TextEditingController(text: user?.profile?.businessName);
    _pincodeController = TextEditingController(text: user?.profile?.pincode);
    
    _selectedGender = user?.profile?.gender;
    _selectedOccupation = user?.profile?.occupation;

    // Date of birth & preferred language from profile if available
    if (user?.profile?.dateOfBirth != null &&
        (user!.profile!.dateOfBirth ?? '').isNotEmpty) {
      _selectedDob = DateTime.tryParse(user.profile!.dateOfBirth!);
    }
    if (user?.profile?.preferredLanguage != null &&
        user!.profile!.preferredLanguage.isNotEmpty) {
      _preferredLanguageCode = user.profile!.preferredLanguage;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _businessNameController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> data = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text,
        'phone_number': _phoneController.text,
        'profile': {
          'gender': _selectedGender,
          'date_of_birth': _selectedDob != null
              ? _selectedDob!.toIso8601String().split('T').first
              : null,
          'preferred_language': _preferredLanguageCode,
        }
      };

      final authController = context.read<AuthController>();
      final success = await authController.updateProfile(data);
      
      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) return Scaffold(body: Center(child: Text(tr(context, 'login_to_account'))));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr(context, 'edit_profile_title'),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: tr(context, 'tab_primary')),
            Tab(text: tr(context, 'tab_other_info')),
            Tab(text: tr(context, 'tab_settings')),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPrimaryTab(user),
                _buildOtherInfoTab(user),
                _buildSettingsTab(user),
              ],
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildPrimaryTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (user.profile?.profilePicture != null && user.profile!.profilePicture!.isNotEmpty)
                            ? NetworkImage(user.profile!.profilePicture!) as ImageProvider
                            : null,
                    child: (_imageFile == null && (user.profile?.profilePicture == null || user.profile!.profilePicture!.isEmpty))
                        ? Text(
                            user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _pickImage,
                child: Text(
                  tr(context, 'change_picture'),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildFieldLabel(tr(context, 'first_name_label')),
            _buildTextField(_firstNameController, tr(context, 'first_name_hint')),
            const SizedBox(height: 16),
            _buildFieldLabel(tr(context, 'last_name_label')),
            _buildTextField(_lastNameController, tr(context, 'last_name_hint')),
            const SizedBox(height: 20),
            _buildFieldLabel('${tr(context, 'phone')} *'),
            _buildTextField(_phoneController, '+971...', keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            _buildFieldLabel(tr(context, 'email_id_label')),
            _buildTextField(_emailController, 'you@example.com', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            _buildFieldLabel(tr(context, 'profile_gender_label')),
            _buildDropdown(['Male', 'Female', 'Other'], _selectedGender, (v) => setState(() => _selectedGender = v)),
            const SizedBox(height: 20),
            _buildFieldLabel(tr(context, 'profile_dob_label')),
            _buildDobField(),
            const SizedBox(height: 20),
            _buildFieldLabel(tr(context, 'profile_lang_label')),
            _buildPreferredLanguageDropdown(),
            const SizedBox(height: 100), // Space for save button
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
      ),
      validator: (v) => v!.isEmpty ? tr(context, 'required') : null,
    );
  }

  Widget _buildDobField() {
    final displayText = _selectedDob != null
        ? _selectedDob!.toIso8601String().split('T').first
        : tr(context, 'select_date');

    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final initialDate = _selectedDob ?? DateTime(now.year - 18, now.month, now.day);
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(1900),
          lastDate: now,
        );
        if (picked != null) {
          setState(() {
            _selectedDob = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
        child: Row(
          children: [
            Text(
              displayText,
              style: TextStyle(
                color: displayText == tr(context, 'select_date')
                    ? Colors.grey.shade400
                    : Colors.black87,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferredLanguageDropdown() {
    final Map<String, String> languageLabels = {
      'en': 'English',
      'ar': 'Arabic',
      'cn': 'Chinese',
    };

    return DropdownButtonFormField<String>(
      value: _preferredLanguageCode,
      items: languageLabels.entries
          .map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _preferredLanguageCode = v;
        });
      },
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) {
        String localizedLabel;
        switch (e.toLowerCase()) {
          case 'male': localizedLabel = tr(context, 'gender_male'); break;
          case 'female': localizedLabel = tr(context, 'gender_female'); break;
          case 'other': localizedLabel = tr(context, 'gender_other'); break;
          default: localizedLabel = trText(context, e);
        }
        return DropdownMenuItem(value: e, child: Text(localizedLabel));
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
      ),
      validator: (v) => v == null ? tr(context, 'required') : null,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: context.read<AuthController>().isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: AppColors.primary.withOpacity(0.4),
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
        ),
        child: context.watch<AuthController>().isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                tr(context, 'save_changes'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
  Widget _buildOtherInfoTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(tr(context, 'occupation_label')),
          _buildDropdown(_occupations, _selectedOccupation, (v) => setState(() => _selectedOccupation = v)),
          const SizedBox(height: 16),
          _buildFieldLabel(tr(context, 'monthly_income')),
          _buildTextField(TextEditingController(), tr(context, 'select_income_range')),
          const SizedBox(height: 16),
          _buildFieldLabel(tr(context, 'marital_status')),
          _buildTextField(TextEditingController(), tr(context, 'select_status')),
          const SizedBox(height: 32),
          Text(tr(context, 'business_details'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          _buildFieldLabel(tr(context, 'business_name_label')),
          _buildTextField(_businessNameController, tr(context, 'enter_business_name')),
          const SizedBox(height: 16),
          _buildFieldLabel(tr(context, 'pincode_label')),
          _buildTextField(_pincodeController, tr(context, 'enter_pincode'), keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSettingToggle(tr(context, 'notification_permissions'), true),
          const Divider(),
          _buildSettingToggle(tr(context, 'email_updates'), false),
          const Divider(),
          _buildSettingToggle(tr(context, 'sms_updates'), true),
          const Divider(),
          _buildSettingToggle(tr(context, 'whatsapp_updates'), false),
          const SizedBox(height: 32),
          ListTile(
            title: Text(tr(context, 'deactivate_account'), style: const TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingToggle(String title, bool value) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      value: value,
      onChanged: (val) {},
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}
