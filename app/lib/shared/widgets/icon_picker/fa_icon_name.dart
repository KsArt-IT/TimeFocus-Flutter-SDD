import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timefocus/shared/widgets/icon_picker/icon_category.dart';

/// Data class for icon with metadata.
class FaIconName {
  const FaIconName({
    required this.name,
    required this.faIcon,
    required this.category,
    this.keywords = const [],
  });

  final String name;
  final FaIconData faIcon;
  final IconCategory category;
  final List<String> keywords;

  /// Unique identifier for serialization.
  String get id => 'fa_$name';
}
