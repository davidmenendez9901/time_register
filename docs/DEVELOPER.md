# Developer guide — Time Register

Setup, operational workflows, and pitfalls for working in this repo.
Architecture and domain rules: [ARCHITECTURE.md](ARCHITECTURE.md).

## Setup

CI uses **Flutter 3.44.1** (stable). `pubspec.yaml` requires Dart `^3.9.2`.

```bash
git clone https://github.com/davidmenendez9901/time_register.git
cd time_register
flutter pub get
flutter run
```

Primary target is Android; iOS and macOS also build. Linux/Windows folders exist
from the Flutter template but are not first-class targets.

Release APK/AAB signing: if `android/key.properties` is missing, the Gradle
release build falls back to the debug keystore so contributors can still
assemble a release locally.

Play Console `applicationId` is `time_register.davidmenendez.dev` (see
`android/app/build.gradle.kts`). The Kotlin namespace is
`dev.davidmenendez.time_register`. Do not “fix” the applicationId to match
the namespace — Play Store package names cannot change.

## Checks (same as CI)

```bash
dart format lib test
flutter analyze
flutter test
```

Workflow: `.github/workflows/ci.yml` (format, analyze, test on `main` and PRs).

If you change strings, edit **both** `lib/l10n/app_en.arb` and
`lib/l10n/app_es.arb`, then:

```bash
flutter gen-l10n
```

`l10n.yaml` uses English as the template. Generated files
(`app_localizations*.dart`) are committed; include them in the same PR.

## Database migrations

`DatabaseHelper` opens `time_register.db` at **version 8**.

| Version | Change |
|---------|--------|
| 2 | `settings.theme_mode` |
| 3 | `settings.app_palette` |
| 4 | lunch times + `description` on entries |
| 5 | `settings.currency_symbol` |
| 6 | `settings.active_shift_start` (live timer) |
| 7 | `jobs` table + `work_entries.job_id` |
| 8 | `settings.deductions_enabled` / `deduction_rate` |

Rules:

1. **Never modify an existing `if (oldVersion < N)` block.** Devices already
   ran it.
2. Bump `version:` in `openDatabase` and add a new block.
3. Keep `_onCreate` matching the latest schema so new installs skip upgrades.
4. Default settings row is inserted only in `_onCreate` (`hourly_rate: 14.0`).

Upgrade path to test: install an older build, add data, then install the new
build **without uninstalling**. Play Store updates must keep rows intact from
v4 → v8.

## Workflows

### Live shift (clock in / out)

1. Home FAB **Clock In** → `ShiftTimerCubit.start()` stores `DateTime.now()` in
   `settings.active_shift_start`. Survives process death.
2. Banner **Clock Out** opens `WorkEntryFormPage` with `initialStart` /
   `initialEnd`. The timer is **not** cleared yet.
3. Saving the form pops `true`; Home then calls `stop()` and reloads entries.
4. Backing out of the form leaves the shift running.

There is a single running shift (one nullable column). No job is attached until
the user picks one on the form.

### Jobs / clients

Managed from Settings → Jobs (`JobsPage`). Color is one of eight presets.
Optional rate overrides the global default on the form when that job is
selected.

Delete unlinks entries (`job_id` set to null) inside a SQLite transaction.
Archive keeps the row but hides it from the form picker.

### Mark as paid

- Home and Summary: toggle dispatches `MarkEntryAsPaid(id, !isPaid)` (no
  confirm dialog).
- Edit form: switch, persisted through `UpdateWorkEntry`.
- Summary filters (all / paid / unpaid) also apply to CSV/PDF export.

### CSV and PDF export

From Summary overflow / export actions. Exports the **currently filtered**
list. Empty list → snackbar, no share sheet.

| | CSV | PDF |
|---|-----|-----|
| Builder | `CsvExporter.buildCsv` | `PdfExporter.build` |
| Order | date ascending | date ascending |
| Totals | last row (hours + earnings) | footer box; optional net line |
| Share | `share_plus` temp file | same, MIME `application/pdf` |
| Fonts | n/a | bundled Lato Regular/Bold |

CSV dates are `yyyy-MM-dd`, times `HH:mm`. Job names come from `JobsCubit`
(`jobNames[e.jobId]`; missing job → empty cell).

### Backup and restore

Settings → backup/restore. Format is JSON, not CSV.

```json
{
  "format": "time_register_backup",
  "version": 1,
  "exported_at": "…",
  "settings": { "hourly_rate": 14.0, "theme_mode": "system", "…" },
  "jobs": [ { "id": 1, "name": "Acme", "color": 4278222848, "hourly_rate": 20.0, "archived": 0 } ],
  "work_entries": [ { "date": "2026-06-10", "start_time": "09:00", "…" } ]
}
```

Codec: `BackupCodec` (`lib/core/utils/backup_codec.dart`). I/O:
`BackupService`.

Constraints:

- `format` must be `time_register_backup` or decode throws `FormatException`.
- Unknown keys are dropped (forward-compatible restore onto older app builds).
- `jobs` is optional so pre-multi-job backups still restore.
- Settings keys in the file: rate, theme, palette, currency, deductions.
  **`active_shift_start` is not included.**
- Restore is destructive: `restoreAll` deletes all entries and jobs, then
  inserts the backup, then updates the existing settings row (`id = 1`).
- After restore, Settings and Time Tracking reload. **`JobsCubit` and
  `ShiftTimerCubit` do not.** Open Jobs again or restart the app to see
  restored jobs. A shift that was running locally is not cleared by restore
  (that column is omitted from the UPDATE).

### Statistics

Pure functions in `lib/core/utils/stats.dart`, rendered by `StatsPage` with
`fl_chart`. Toggle hours vs earnings for the bar charts. Job pie/breakdown
uses this month only.

## Pitfalls

| Symptom | Cause / fix |
|---------|-------------|
| Analyzer / tests fail in CI but pass locally | Match Flutter **3.44.1**. |
| Missing strings in Spanish (or English) | ARB key added to only one file; run `flutter gen-l10n`. |
| Release build tries to download fonts / crashes offline | Keep `allowRuntimeFetching = false`. Add new font files under `assets/google_fonts/` and to `pubspec.yaml` assets. PDF must `rootBundle.load` those files. |
| Play upload rejected for package name | `applicationId` must stay `time_register.davidmenendez.dev`. |
| Users lose data after an “update” | They uninstalled; local SQLite died. Prefer backup/restore. Never drop tables in a migration. |
| Overnight shift hours look negative or huge | Persist `HH:mm` only; reconstruct next-day end in `WorkEntry.fromMap` / the form. |
| Job rate didn’t apply | Job has a null `hourly_rate` — form keeps the previous field value. |
| Jobs list empty after restore | Reload `JobsCubit` (restart app). |
| `flutter test` can’t open SQLite | Prefer tests on pure utils (`backup_codec`, `csv_exporter`, `pdf_exporter`, `stats`) and BLoCs with mocks. |
| Debug has network, release does not | Flutter debug manifest adds INTERNET. Feature work must not assume connectivity. |

## Tests worth mirroring

| Area | Test |
|------|------|
| Backup JSON | `test/core/utils/backup_codec_test.dart` |
| CSV columns / totals | `test/core/utils/csv_exporter_test.dart` |
| PDF builds | `test/core/utils/pdf_exporter_test.dart` |
| Week/month aggregation | `test/core/utils/stats_test.dart` |
| BLoC paid/CRUD | `test/presentation/blocs/time_tracking_bloc_test.dart` |
| Summary filters | `test/presentation/pages/weekly_summary_page_test.dart` |

Add tests next to these when changing the matching codepath.
