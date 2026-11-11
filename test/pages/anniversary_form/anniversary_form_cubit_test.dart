// Plan 0005, U3: form rules UI-3 to UI-6 and UI-10 on the Cubit.
import 'package:ever_moon/pages/anniversary_form/anniversary_draft.dart';
import 'package:ever_moon/pages/anniversary_form/anniversary_form_cubit.dart';
import 'package:ever_moon/pages/anniversary_form/anniversary_form_state.dart';
import 'package:ever_moon/services/lunar/anniversary_resolver.dart';
import 'package:ever_moon/services/lunar/lunar_calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../services/lunar/fake_lunar_calendar_service.dart';
import 'memory_anniversary_repository.dart';

void main() {
  // Lunar 2005 repeats month 9 in this synthetic calendar.
  final calendar = FakeLunarCalendarService(leapMonths: {2005: 9});
  final today = calendar.toSolar(const LunarDate(2002, 4, 5)) ?? DateTime(0);
  late MemoryAnniversaryRepository repository;
  late AnniversaryFormCubit cubit;

  AnniversaryFormEditing editing() => cubit.state as AnniversaryFormEditing;

  Future<void> open([String? id]) async {
    cubit = AnniversaryFormCubit(
      repository,
      AnniversaryResolver(calendar),
      today: () => today,
    );
    await cubit.load(id);
  }

  void fillValid() {
    cubit
      ..changeName('  Ông nội ')
      ..changeDay(5)
      ..changeMonth(4);
  }

  setUp(() => repository = MemoryAnniversaryRepository());
  tearDown(() => cubit.close());

  test(
    'UI-4 an empty form does not save and flags every missing field',
    () async {
      await open();
      expect(editing().visibleErrors, isEmpty);
      await cubit.save();
      expect(editing().visibleErrors, {
        AnniversaryFormError.nameRequired,
        AnniversaryFormError.dayInvalid,
        AnniversaryFormError.monthInvalid,
      });
      expect(repository.records, isEmpty);
    },
  );

  test(
    'UI-4 day outside 1 to 30 and month outside 1 to 12 are rejected',
    () async {
      await open();
      cubit
        ..changeName('A')
        ..changeDay(31)
        ..changeMonth(13);
      await cubit.save();
      expect(editing().visibleErrors, {
        AnniversaryFormError.dayInvalid,
        AnniversaryFormError.monthInvalid,
      });
      cubit
        ..changeDay(0)
        ..changeMonth(0);
      expect(editing().visibleErrors, hasLength(2));
      expect(repository.records, isEmpty);
    },
  );

  test(
    'UI-5 leap question only when the death year repeats the month',
    () async {
      await open();
      cubit.changeMonth(9);
      expect(editing().canBeLeapMonth, isFalse);
      cubit.changeYear(2005);
      expect(editing().canBeLeapMonth, isTrue);
      cubit.changeLeapMonth(true);
      expect(editing().draft.diedInLeapMonth, isTrue);
      cubit.changeMonth(8);
      expect(editing().canBeLeapMonth, isFalse);
      expect(editing().draft.diedInLeapMonth, isFalse);
      cubit.changeMonth(9);
      expect(editing().canBeLeapMonth, isTrue);
      expect(editing().draft.diedInLeapMonth, isFalse);
    },
  );

  test('UI-5 clearing the year hides the question and clears it', () async {
    await open();
    cubit
      ..changeMonth(9)
      ..changeYear(2005)
      ..changeLeapMonth(true)
      ..changeYear(null);
    expect(editing().canBeLeapMonth, isFalse);
    expect(editing().draft.diedInLeapMonth, isFalse);
    cubit.changeLeapMonth(true);
    expect(editing().draft.diedInLeapMonth, isFalse);
  });

  test('UI-3 a valid new form creates the record and closes', () async {
    await open();
    fillValid();
    cubit
      ..changeAddress('   ')
      ..changeNote(' Cúng chay ')
      ..changeDaysBefore(3)
      ..changeReminderTime(18 * 60 + 30);
    await cubit.save();
    expect(cubit.state, const AnniversaryFormDone());
    final saved = repository.records.values.single;
    expect(saved.name, 'Ông nội');
    expect(saved.date.lunarDay, 5);
    expect(saved.date.lunarMonth, 4);
    expect(saved.date.deathYear, isNull);
    expect(saved.address, isNull);
    expect(saved.note, 'Cúng chay');
    expect(saved.remindDaysBefore, 3);
    expect(saved.remindMinuteOfDay, 18 * 60 + 30);
  });

  test(
    'UI-10 only 0, 1, 3 and 7 days and a real time of day are taken',
    () async {
      await open();
      cubit
        ..changeDaysBefore(2)
        ..changeDaysBefore(30)
        ..changeReminderTime(24 * 60)
        ..changeReminderTime(-1);
      expect(editing().draft.remindDaysBefore, 0);
      expect(editing().draft.remindMinuteOfDay, 7 * 60);
      cubit.changeDaysBefore(7);
      expect(editing().draft.remindDaysBefore, 7);
    },
  );

  test('UI-10 the reminder can be off and keeps its settings', () async {
    await open();
    fillValid();
    cubit
      ..changeDaysBefore(1)
      ..changeReminder(false);
    await cubit.save();
    final saved = repository.records.values.single;
    expect(saved.reminderEnabled, isFalse);
    expect(saved.remindDaysBefore, 1);
  });

  test('the next holding of the drafted date is shown', () async {
    await open();
    expect(editing().nextHolding, isNull);
    cubit
      ..changeDay(9)
      ..changeMonth(4);
    expect(
      editing().nextHolding?.solar,
      calendar.toSolar(const LunarDate(2002, 4, 9)),
    );
  });

  test(
    'UI-3 editing keeps the identity and clears a blanked address',
    () async {
      final stored = storedAnniversary();
      repository = MemoryAnniversaryRepository([stored]);
      await open('a');
      expect(editing().isEdit, isTrue);
      expect(editing().draft.name, 'Bà nội');
      cubit
        ..changeName('Bà ngoại')
        ..changeAddress('');
      await cubit.save();
      expect(cubit.state, const AnniversaryFormDone());
      final saved = repository.records['a'];
      expect(saved?.name, 'Bà ngoại');
      expect(saved?.address, isNull);
      expect(saved?.createdAt, stored.createdAt);
    },
  );

  test('a stored lead time the form does not offer must be changed', () async {
    repository = MemoryAnniversaryRepository([
      storedAnniversary(remindDaysBefore: 2),
    ]);
    await open('a');
    await cubit.save();
    expect(editing().visibleErrors, {AnniversaryFormError.daysBeforeInvalid});
    cubit.changeDaysBefore(3);
    await cubit.save();
    expect(cubit.state, const AnniversaryFormDone());
  });

  test('UI-6 delete goes through the repository and closes', () async {
    repository = MemoryAnniversaryRepository([storedAnniversary()]);
    await open('a');
    expect(cubit.storedName, 'Bà nội');
    await cubit.delete();
    expect(cubit.state, const AnniversaryFormDone());
    expect(repository.deleted, ['a']);
  });

  test('a new form cannot delete', () async {
    await open();
    await cubit.delete();
    expect(cubit.state, isA<AnniversaryFormEditing>());
    expect(repository.deleted, isEmpty);
  });

  test('a missing record is unavailable', () async {
    await open('missing');
    expect(cubit.state, const AnniversaryFormUnavailable());
  });

  test('a failed save keeps the input and reports it once', () async {
    await open();
    fillValid();
    repository.failWrites = true;
    await cubit.save();
    expect(editing().notice, AnniversaryFormNotice.saveFailed);
    expect(editing().busy, isFalse);
    expect(editing().draft.name, '  Ông nội ');
    repository.failWrites = false;
    await cubit.save();
    expect(cubit.state, const AnniversaryFormDone());
  });

  test('input typed while a save fails is kept', () async {
    await open();
    fillValid();
    repository.failWrites = true;
    final saving = cubit.save();
    expect(editing().busy, isTrue);
    cubit.changeName('Ông ngoại');
    await saving;
    expect(editing().busy, isFalse);
    expect(editing().notice, AnniversaryFormNotice.saveFailed);
    expect(editing().draft.name, 'Ông ngoại');
  });

  test('no reminder summary when the lead time reaches before today', () async {
    await open();
    cubit
      ..changeDay(6) // tomorrow
      ..changeMonth(4)
      ..changeDaysBefore(7);
    expect(editing().daysUntilNext, 1);
    expect(editing().reminderStillAhead, isFalse);
    cubit.changeDaysBefore(1);
    expect(editing().reminderStillAhead, isTrue);
  });

  test('a failed delete keeps the record and reports it', () async {
    repository = MemoryAnniversaryRepository([storedAnniversary()]);
    await open('a');
    repository.failWrites = true;
    await cubit.delete();
    expect(editing().notice, AnniversaryFormNotice.deleteFailed);
    expect(repository.records, contains('a'));
  });
}
