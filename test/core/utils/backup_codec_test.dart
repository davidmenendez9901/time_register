import 'package:flutter_test/flutter_test.dart';
import 'package:time_register/core/utils/backup_codec.dart';

final settings = {
  'hourly_rate': 14.0,
  'theme_mode': 'dark',
  'app_palette': 'Green',
  'currency_symbol': '€',
};

final entry = {
  'id': 1,
  'date': '2026-06-10',
  'start_time': '09:00',
  'end_time': '17:00',
  'lunch_taken': 0,
  'total_hours': 8.0,
  'hourly_rate': 14.0,
  'earnings': 112.0,
  'is_paid': 1,
  'created_at': '2026-06-10T17:01:00.000',
  'lunch_start_time': null,
  'lunch_end_time': null,
  'description': 'desk work',
};

void main() {
  test('encode/decode roundtrip preserves settings and entries', () {
    final json = BackupCodec.encode(
      settings: settings,
      entries: [entry],
      exportedAt: DateTime(2026, 6, 12),
    );
    final data = BackupCodec.decode(json);

    expect(data.settings, settings);
    expect(data.entries, [entry]);
  });

  test('encode strips the settings row id and unknown keys', () {
    final json = BackupCodec.encode(
      settings: {...settings, 'id': 1, 'future_field': true},
      entries: [
        {...entry, 'future_column': 'x'},
      ],
      exportedAt: DateTime(2026, 6, 12),
    );
    final data = BackupCodec.decode(json);

    expect(data.settings.containsKey('id'), isFalse);
    expect(data.settings.containsKey('future_field'), isFalse);
    expect(data.entries.single.containsKey('future_column'), isFalse);
  });

  test('decode rejects non-JSON input', () {
    expect(() => BackupCodec.decode('not json'), throwsFormatException);
  });

  test('decode rejects JSON that is not a backup', () {
    expect(() => BackupCodec.decode('{"foo": 1}'), throwsFormatException);
    expect(() => BackupCodec.decode('[1, 2]'), throwsFormatException);
  });

  test('decode rejects entries missing required fields', () {
    final json = BackupCodec.encode(
      settings: settings,
      entries: [entry],
      exportedAt: DateTime(2026, 6, 12),
    ).replaceAll('"date"', '"fecha"');

    expect(() => BackupCodec.decode(json), throwsFormatException);
  });
}
