import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/icon_picker/icon_category.dart';
import 'package:timefocus/shared/widgets/icon_picker/icons_grid.dart';

/// Dialog for picking a FontAwesome icon (T076's activity icon field).
///
/// Supports category filtering via tabs, search by name/keyword, a grid
/// with a selection indicator, and previewing the icon in the activity's
/// current color.
class IconPickerDialog extends StatefulWidget {
  const IconPickerDialog._({required this.initialIcon, required this.selectedColor});

  final FaIconData initialIcon;
  final Color selectedColor;

  /// Shows the dialog; resolves to the picked icon, or null if dismissed
  /// without a selection.
  static Future<FaIconData?> show(
    BuildContext context, {
    required FaIconData initialIcon,
    required Color selectedColor,
  }) => showDialog<FaIconData>(
    context: context,
    builder: (_) => IconPickerDialog._(initialIcon: initialIcon, selectedColor: selectedColor),
  );

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> with SingleTickerProviderStateMixin {
  late var _selectedIcon = widget.initialIcon;
  late final _tabController = TabController(length: _categories.length, vsync: this);
  final _searchController = TextEditingController();
  var _searchQuery = '';

  static const _categories = IconCategory.values;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final value = _searchController.text;
    if (_searchQuery == value) return;
    setState(() => _searchQuery = value);
  }

  void _onIconSelected(FaIconData icon) {
    if (_selectedIcon == icon) return;
    setState(() => _selectedIcon = icon);
  }

  void _onClose(FaIconData? icon) => Navigator.of(context).pop(icon);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(l10n.actionIcon, style: theme.textTheme.titleMedium),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 340,
        height: 480,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchIcons,
                  prefixIcon: const Icon(Icons.search, size: 24),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 24),
                          onPressed: _searchController.clear,
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: theme.textTheme.labelSmall,
              unselectedLabelStyle: theme.textTheme.labelSmall,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: [
                for (final category in _categories) Tab(text: category.categoryName(l10n)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  for (final category in _categories)
                    IconsGrid(
                      icons: category.categoryIcons(_searchQuery),
                      selectedIcon: _selectedIcon,
                      selectedColor: widget.selectedColor,
                      onIconSelected: _onIconSelected,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.all(8),
      actions: [
        TextButton(onPressed: () => _onClose(null), child: Text(l10n.cancel)),
        TextButton(onPressed: () => _onClose(_selectedIcon), child: Text(l10n.select)),
      ],
    );
  }
}
