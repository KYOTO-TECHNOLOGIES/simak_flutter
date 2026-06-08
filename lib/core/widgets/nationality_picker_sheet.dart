import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/core/constants/nationalities.dart';

class NationalityPickerSheet extends StatefulWidget {
  final ThemeData theme;
  final String? initialValue;
  final ValueChanged<String> onSelected;

  const NationalityPickerSheet({
    super.key,
    required this.theme,
    required this.initialValue,
    required this.onSelected,
  });

  @override
  State<NationalityPickerSheet> createState() => _NationalityPickerSheetState();
}

class _NationalityPickerSheetState extends State<NationalityPickerSheet> {
  String _searchQuery = '';
  late List<MapEntry<String, String>> _filteredNationalities;

  @override
  void initState() {
    super.initState();
    _filteredNationalities = kNationalityMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query;
      _filteredNationalities = kNationalityMap.entries
          .where((e) => e.value.toLowerCase().contains(query.toLowerCase()))
          .toList()
        ..sort((a, b) => a.value.compareTo(b.value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(context, 'nationality_label'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search nationality...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: widget.theme.scaffoldBackgroundColor,
                  ),
                  onChanged: _filter,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filteredNationalities.length,
                  itemBuilder: (context, index) {
                    final item = _filteredNationalities[index];
                    final isSelected = widget.initialValue?.toUpperCase() == item.key;
                    return ListTile(
                      title: Text(
                        item.value,
                        style: TextStyle(
                          color: widget.theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.actionBlue)
                          : null,
                      onTap: () {
                        widget.onSelected(item.value);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
