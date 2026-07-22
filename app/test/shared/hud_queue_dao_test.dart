import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/shared/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  final today = DateTime.utc(2026, 7, 22);
  final yesterday = DateTime.utc(2026, 7, 21);
  final now = DateTime(2026, 7, 22, 10);

  test('upsert raises an action once; a second trigger the same day is a no-op row-wise', () async {
    await db.hudQueueDao.upsert(SystemAction.toilet.name, today, now);
    await db.hudQueueDao.upsert(
      SystemAction.toilet.name,
      today,
      now.add(const Duration(minutes: 5)),
    );

    final active = await db.hudQueueDao.watchActive(today).first;
    expect(active.length, 1);
    expect(active.single.systemAction, SystemAction.toilet.name);
  });

  test('dismiss hides an item from watchActive', () async {
    await db.hudQueueDao.upsert(SystemAction.meal.name, today, now);
    final id = (await db.hudQueueDao.watchActive(today).first).single.id;

    await db.hudQueueDao.dismiss(id);

    expect(await db.hudQueueDao.watchActive(today).first, isEmpty);
  });

  test('upsert on a dismissed action refreshes it back to active', () async {
    await db.hudQueueDao.upsert(SystemAction.toilet.name, today, now);
    final id = (await db.hudQueueDao.watchActive(today).first).single.id;
    await db.hudQueueDao.dismiss(id);
    expect(await db.hudQueueDao.watchActive(today).first, isEmpty);

    await db.hudQueueDao.upsert(SystemAction.toilet.name, today, now.add(const Duration(hours: 1)));

    final active = await db.hudQueueDao.watchActive(today).first;
    expect(active.length, 1);
    expect(active.single.dismissed, isFalse);
  });

  test('insertIfAbsent inserts a new action', () async {
    await db.hudQueueDao.insertIfAbsent(SystemAction.meal.name, today, now);

    final active = await db.hudQueueDao.watchActive(today).first;
    expect(active.length, 1);
    expect(active.single.systemAction, SystemAction.meal.name);
  });

  test('insertIfAbsent never revives an action the user already dismissed', () async {
    await db.hudQueueDao.upsert(SystemAction.meal.name, today, now);
    final id = (await db.hudQueueDao.watchActive(today).first).single.id;
    await db.hudQueueDao.dismiss(id);

    // Simulates a repeated level-triggered check (ticker tick, app restart).
    await db.hudQueueDao.insertIfAbsent(
      SystemAction.meal.name,
      today,
      now.add(const Duration(minutes: 1)),
    );
    await db.hudQueueDao.insertIfAbsent(
      SystemAction.meal.name,
      today,
      now.add(const Duration(minutes: 2)),
    );

    expect(await db.hudQueueDao.watchActive(today).first, isEmpty);
  });

  test('watchActive is scoped to the given day', () async {
    await db.hudQueueDao.upsert(SystemAction.toilet.name, yesterday, now);

    expect(await db.hudQueueDao.watchActive(today).first, isEmpty);
    expect(await db.hudQueueDao.watchActive(yesterday).first, hasLength(1));
  });

  test('deleteNotToday purges rows stamped with a different day', () async {
    await db.hudQueueDao.upsert(SystemAction.toilet.name, yesterday, now);
    await db.hudQueueDao.upsert(SystemAction.meal.name, today, now);

    await db.hudQueueDao.deleteNotToday(today);

    expect(await db.hudQueueDao.watchActive(today).first, hasLength(1));
    expect(await db.hudQueueDao.watchActive(yesterday).first, isEmpty);
  });
}
