import 'dart:convert';

/// Decoded backup contents in database-map form.
class BackupData {
  final Map<String, dynamic> settings;
  final List<Map<String, dynamic>> entries;
  final List<Map<String, dynamic>> jobs;

  const BackupData({
    required this.settings,
    required this.entries,
    this.jobs = const [],
  });
}

/// Encodes/decodes full app backups as JSON. Pure logic, no I/O.
///
/// Unknown keys are dropped on decode so a backup created by a newer app
/// version restores cleanly on an older one (minus the newer fields).
class BackupCodec {
  static const format = 'time_register_backup';
  static const version = 1;

  static const _settingsKeys = {
    'hourly_rate',
    'theme_mode',
    'app_palette',
    'currency_symbol',
    'deductions_enabled',
    'deduction_rate',
  };

  static const _entryKeys = {
    'id',
    'date',
    'start_time',
    'end_time',
    'lunch_taken',
    'total_hours',
    'hourly_rate',
    'earnings',
    'is_paid',
    'created_at',
    'lunch_start_time',
    'lunch_end_time',
    'description',
    'job_id',
  };

  static const _jobKeys = {'id', 'name', 'color', 'hourly_rate', 'archived'};

  static const _requiredEntryKeys = {
    'date',
    'start_time',
    'end_time',
    'total_hours',
    'hourly_rate',
    'earnings',
  };

  static String encode({
    required Map<String, dynamic> settings,
    required List<Map<String, dynamic>> entries,
    required DateTime exportedAt,
    List<Map<String, dynamic>> jobs = const [],
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'version': version,
      'exported_at': exportedAt.toIso8601String(),
      'settings': _filterKeys(settings, _settingsKeys),
      'jobs': [for (final j in jobs) _filterKeys(j, _jobKeys)],
      'work_entries': [for (final e in entries) _filterKeys(e, _entryKeys)],
    });
  }

  /// Throws [FormatException] when the JSON is not a valid backup.
  static BackupData decode(String json) {
    final dynamic root;
    try {
      root = jsonDecode(json);
    } on Object {
      throw const FormatException('Not a JSON document');
    }

    if (root is! Map<String, dynamic> || root['format'] != format) {
      throw const FormatException('Not a Time Register backup');
    }

    final settings = root['settings'];
    final entries = root['work_entries'];
    if (settings is! Map<String, dynamic> || entries is! List) {
      throw const FormatException('Malformed backup contents');
    }

    final parsedEntries = <Map<String, dynamic>>[];
    for (final entry in entries) {
      if (entry is! Map<String, dynamic> ||
          !_requiredEntryKeys.every(entry.containsKey)) {
        throw const FormatException('Malformed work entry in backup');
      }
      parsedEntries.add(_filterKeys(entry, _entryKeys));
    }

    // Jobs are optional so backups from before multi-job support restore.
    final jobs = root['jobs'];
    final parsedJobs = <Map<String, dynamic>>[];
    if (jobs is List) {
      for (final job in jobs) {
        if (job is! Map<String, dynamic> ||
            job['name'] is! String ||
            job['color'] is! int) {
          throw const FormatException('Malformed job in backup');
        }
        parsedJobs.add(_filterKeys(job, _jobKeys));
      }
    }

    return BackupData(
      settings: _filterKeys(settings, _settingsKeys),
      entries: parsedEntries,
      jobs: parsedJobs,
    );
  }

  static Map<String, dynamic> _filterKeys(
    Map<String, dynamic> map,
    Set<String> allowed,
  ) {
    return {
      for (final entry in map.entries)
        if (allowed.contains(entry.key)) entry.key: entry.value,
    };
  }
}
