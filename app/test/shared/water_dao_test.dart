import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timefocus/shared/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('watchAllQuickButtons includes inactive buttons; watchQuickButtons excludes them', () async {
    final seeded = await db.select(db.waterQuickButtons).get();
    final target = seeded.first;
    await db.waterDao.saveQuickButton(
      WaterQuickButtonsCompanion(id: Value(target.id), isActive: const Value(false)),
    );

    final all = await db.waterDao.watchAllQuickButtons().first;
    final active = await db.waterDao.watchQuickButtons().first;

    expect(all.length, seeded.length);
    expect(all.any((b) => b.id == target.id), isTrue);
    expect(active.any((b) => b.id == target.id), isFalse);
    expect(active.length, seeded.length - 1);
  });

  test('reorderQuickButtons rewrites sortOrder to list index', () async {
    final seeded = await db.waterDao.watchAllQuickButtons().first;
    final reversedIds = seeded.reversed.map((b) => b.id).toList();

    await db.waterDao.reorderQuickButtons(reversedIds);

    final reordered = await db.waterDao.watchAllQuickButtons().first;
    expect(reordered.map((b) => b.id).toList(), reversedIds);
    expect(reordered.map((b) => b.sortOrder).toList(), List.generate(seeded.length, (i) => i));
  });

  test('saveQuickButton with id 0 semantics inserts a new custom-named button', () async {
    await db.waterDao.saveQuickButton(
      WaterQuickButtonsCompanion.insert(volume: 350, label: 'My custom drink', icon: 0xe4f4),
    );

    final all = await db.waterDao.watchAllQuickButtons().first;
    expect(all.any((b) => b.label == 'My custom drink' && b.volume == 350), isTrue);
  });

  test('deleteQuickButton removes it from watchAllQuickButtons', () async {
    final seeded = await db.waterDao.watchAllQuickButtons().first;
    final target = seeded.first;

    await db.waterDao.deleteQuickButton(target.id);

    final remaining = await db.waterDao.watchAllQuickButtons().first;
    expect(remaining.any((b) => b.id == target.id), isFalse);
    expect(remaining.length, seeded.length - 1);
  });
}
