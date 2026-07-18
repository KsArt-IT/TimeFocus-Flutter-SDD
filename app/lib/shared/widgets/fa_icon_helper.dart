import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Builds FA solid icon data from a codePoint stored in the DB.
/// Dynamic codePoints require building with --no-tree-shake-icons.
FaIconData faIconFromCode(int codePoint) => FaIconData(
  // ignore: non_const_argument_for_const_parameter
  IconData(codePoint, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter'),
);
