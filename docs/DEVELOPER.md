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

Primary targets are Android, iOS and macOS. Linux and Windows use SQLite via
FFI (`lib/core/database/desktop_sqlite.dart`) and are not store targets. Web
is marketing HTML in `docs/` only — the Flutter web client is not supported
(`kIsWeb` skips FFI init).

```bash
# Desktop (needs the FFI factory; main() already calls it)
flutter run -d linux    # or windows / macos
```

Release APK/AAB signing: if `android/key.properties` is missing, the Gradle
release build falls back to the debug keystore so contributors can still
assemble a release locally. Play Store signing and the upload-key reset are
documented in [play_store/README.md](../play_store/README.md).

Play Console `applicationId` is `time_register.davidmenendez.dev` (see
`android/app/build.gradle.kts`). The Kotlin namespace is
`dev.davidmenendez.timeregister`. Apple / Linux identifiers use
`dev.davidmenendez.timeregister`. Do not “fix” the applicationId to match
the namespace — Play Store package names cannot change.

Release Android builds also:

- minify + shrink resources (R8); `proguard-rules.pro` keeps `org.sqlite.**`
- filter locales to `en` and `es` (`androidResources.localeFilters`)
- target Java 17 with `desugar_jdk_libs`

Current store version in `pubspec.yaml`: **1.1.1+5** (`versionName` 1.1.1,
`versionCode` 5). The Settings about tile still hardcodes `'1.1.1'`.

Enable the pre-push hook once per clone if you work on Pro branches:

```bash
git config core.hooksPath .githooks
```

The hook blocks pushing `pro/*` refs or anything under `lib/pro/` to a repo
that is not private (`gh repo view … visibility`). The public GitHub repo
must stay MIT / offline-only.

## Checks (same as CI)

```bash
dart format lib test
flutter analyze
flutter test
```

Workflow: `.github/workflows/ci.yml` (format, analyze, test on `main` and PRs).
`analysis_options.yaml` excludes generated platform folders (`android/`,
`ios/`, `web/`, `windows/`, `macos/`, `linux/`, `build/`). `tool/` is not
part of `flutter test` (icon generator lives there on purpose).

If you change strings, edit **both** `lib/l10n/app_en.arb` and
`lib/l10n/app_es.arb`, then:

```bash
flutter gen-l10n
```

`l10n.yaml` uses English as the template. Generated files
(`app_localizations*.dart`) are committed; include them in the same PR.

## Database migrations

`DatabaseHelper` opens `time_register.db` at **version 10**.

| Version | Change |
|---------|--------|
| 2 | `settings.theme_mode` |
| 3 | `settings.app_palette` |
| 4 | lunch times + `description` on entries |
| 5 | `settings.currency_symbol` |
| 6 | `settings.active_shift_start` (live timer) |
| 7 | `jobs` table + `work_entries.job_id` |
| 8 | `settings.deductions_enabled` / `deduction_rate` |
| 9 | indexes on `work_entries(date)`, `(job_id)`, `(is_paid)` |
| 10 | `work_entries.expenses` (JSON receipts) + `settings.expense_tax_rate` (default 7.0) |

Rules:

1. **Never modify an existing `if (oldVersion < N)` block.** Devices already
   ran it.
2. Bump `version:` in `openDatabase` and add a new block.
3. Keep `_onCreate` matching the latest schema so new installs skip upgrades
   (including the v9 indexes via `_createWorkEntryIndexes` and the v10
   receipt columns).
4. Default settings row is inserted only in `_onCreate` (`hourly_rate: 14.0`,
   `app_palette: 'Blue'`). `expense_tax_rate` relies on the column default.

Upgrade path to test: install an older build, add data, then install the new
build **without uninstalling**. Play Store updates must keep rows intact from
v4 → v10.

## Workflows

### Live shift (clock in / out)

1. Home AppBar **play** → `ShiftTimerCubit.start()` stores `DateTime.now()` in
   `settings.active_shift_start`. Survives process death. **Add** (FAB / glass
   `+` / sidebar) is a separate path (empty form, no timer).
2. Banner **Clock Out** opens `WorkEntryFormPage` with `initialStart` /
   `initialEnd`. The timer is **not** cleared yet.
3. Saving the form pops `true`; Home then calls `stop()` (clears the column).
4. Backing out of the form leaves the shift running.

There is a single running shift (one nullable column). No job is attached until
the user picks one on the form. The elapsed clock ticks every second inside a
`RepaintBoundary` (`ActiveShiftBanner`). Long timers must stay clear of the
clock-out button (the banner layout already accounts for this).

### Jobs / clients

Managed from Settings → Jobs (`JobsPage`). Color is one of eight presets in
`jobColors`. Optional rate overrides the global default on the form when that
job is selected.

Delete unlinks entries (`job_id` set to null) inside a SQLite transaction.
Archive keeps the row but hides it from the form picker.

### Receipts

From the work-entry form, add/edit a product on `ExpenseFormPage`. Settings →
Receipts tax rate is the **default for new products only**.

Tax is stored on each `Expense` so old receipts stay put. JSON lives in
`work_entries.expenses`. Empty → `NULL`.

Home and Summary headers that show money use `totalToCollect` (hours +
receipts). Stats charts do **not**. PDF net (deductions) is hours only; the
“total to collect” line is gross hours + receipts.

### Mark as paid

- Home and Summary: toggle dispatches `MarkEntryAsPaid(id, !isPaid)` (no
  confirm dialog).
- Edit form: switch, persisted through `UpdateWorkEntry`.
- Summary filters (all / paid / unpaid) also apply to CSV/PDF export.

### CSV and PDF export

From Summary overflow / export actions. Exports the **currently filtered**
list. Empty list → snackbar, no share sheet. iPad share sheets need
`shareOriginOf(context)`.

| | CSV | PDF |
|---|-----|-----|
| Builder | `CsvExporter.buildCsv` | `PdfExporter.build` |
| Order | date ascending | date ascending |
| Lunch columns | yes | no |
| Receipts | columns always; product block if any | extra columns + table if any; landscape A4 |
| Totals | last row (hours, earnings, receipts, to-collect) | footer box; optional hours-net line; receipts + to-collect |
| Share | `share_plus` temp file | same, MIME `application/pdf` |
| Fonts | n/a | bundled Lato Regular/Bold |

CSV dates are `yyyy-MM-dd`, times `HH:mm`. Job names come from `JobsCubit`
(`jobNames[e.jobId]`; missing job → empty cell).

### Backup and restore

Settings → backup/restore. Format is JSON, not CSV. Backup is shared as
`time_register_backup_yyyy-MM-dd.json`. Restore confirms, then
`file_selector` picks a `.json` file (`application/json` or `text/plain`;
iOS UTIs `public.json` / `public.plain-text`).

```json
{
  "format": "time_register_backup",
  "version": 1,
  "exported_at": "…",
  "settings": { "hourly_rate": 14.0, "theme_mode": "system", "expense_tax_rate": 7.0, "…" },
  "jobs": [ { "id": 1, "name": "Acme", "color": 4278222848, "hourly_rate": 20.0, "archived": 0 } ],
  "work_entries": [ { "date": "2026-06-10", "start_time": "09:00", "expenses": "[{\"name\":\"Paint\",\"price\":10,\"tax_rate\":7}]", "…" } ]
}
```

Codec: `BackupCodec` (`lib/core/utils/backup_codec.dart`). I/O:
`BackupService`. The Settings page constructs
`BackupService(DatabaseHelper())` — the helper is a singleton, so this is
the same DB the rest of the app uses.

Constraints:

- `format` must be `time_register_backup` or decode throws `FormatException`.
- Each work entry must include `date`, `start_time`, `end_time`,
  `total_hours`, `hourly_rate`, and `earnings`.
- Unknown keys are dropped (forward-compatible restore onto older app builds).
- `jobs` is optional so pre-multi-job backups still restore.
- `expenses` is optional (older backups have none). Non-string values are
  stripped so they cannot break the TEXT column.
- Settings keys in the file: rate, theme, palette, currency, deductions,
  `expense_tax_rate`. **`active_shift_start` is not included.**
- Palette strings: a never-changed install backups `'Blue'` (SQL default).
  After the user picks a palette, the value is the enum identifier
  (`green`, not `Green`). `AppSettings.fromMap` maps `'Blue'` only via
  `orElse: AppPalette.blue`.
- Restore is destructive: `restoreAll` deletes all entries and jobs, then
  inserts the backup, then updates the existing settings row (`id = 1`).
- After restore, Settings and Time Tracking reload. **`JobsCubit` and
  `ShiftTimerCubit` do not.** Tabs live in an `IndexedStack`, so a Jobs
  screen that was already opened keeps its old list until restart (or a
  cubit `load()`). A shift that was running locally is not cleared by
  restore (that column is omitted from the UPDATE).

User-made JSON backups are the portable path across devices. System backups
are **not** equivalent:

| Platform | What happens |
|----------|----------------|
| Android | Auto Backup / device transfer excluded (`allowBackup=false` + XML rules). |
| iOS / iPadOS / macOS | Documents-directory SQLite **may** ride along in iCloud or Time Machine. The project does not set `NSURLIsExcludedFromBackupKey`. |

### Statistics

Pure functions in `lib/core/utils/stats.dart`, rendered by `StatsPage` with
`fl_chart`. Toggle hours vs earnings for the bar charts. Job pie/breakdown
uses this month only. Totals are hours earnings — receipts are not included.

### Demo data and store screenshots

Screenshot builds seed six months of sample jobs/entries/receipts plus a live
shift when the database is empty:

```bash
flutter build ios --simulator --debug --dart-define=DEMO_DATA=true
flutter build apk --release --dart-define=DEMO_DATA=true --dart-define=DEMO_LOCALE=es
```

`kDemoData` / `kDemoLocale` are compile-time (`bool.fromEnvironment` /
`String.fromEnvironment`). Store releases must leave them unset.
`seedDemoDataIfEmpty` is a no-op when any work entry already exists.

Framed App Store / Play shots: [goldie/README.md](../goldie/README.md). iOS
Argent flows tap Flutter widgets by coordinates (UIKit cannot see them);
Android flows select by visible text.

### Appearance

Settings → Appearance (`AppearancePage`): theme mode and palette as checkmark
lists. Palette persistence is the Dart enum `.name` (`blue`, not `Blue`).

### Privacy policy link

Settings shows an in-app dialog (`privacyPolicyContent` from l10n) and can
open `https://davidmenendez9901.github.io/time_register/privacy.html` via
`url_launcher` in an external browser. If the intent fails, a snackbar is
shown. This is not an in-app HTTP client and must not require adding
`INTERNET` to the release manifest.

The ARB string is a **short summary**. The full policy (Android + iPhone/iPad/Mac,
share-sheet exports, Android Auto Backup off vs Apple system backups) lives in
`PRIVACY_POLICY.md` and `docs/privacy.html` (last updated **23 Sep 2026**).
Keep those two files in lockstep. Only change `privacyPolicyContent` in
**both** ARB files if a fact in the short dialog text itself changes.

### Launcher icons

Source PNGs in `assets/icon/` are drawn by Canvas (no binary design files):

```bash
flutter test tool/generate_icons_test.dart
dart run flutter_launcher_icons
```

The generator loads Roboto from `$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/`.
Config: `flutter_launcher_icons.yaml` (Android adaptive, iOS with alpha
removed, macOS). This is **not** run by CI.

### GitHub Pages

`docs/` is the Pages root (`index.html`, `privacy.html`, `screenshots/`,
`assets/`). Engineering markdown in this folder is fine; do not rename or
break the HTML/screenshot paths the README and the app depend on.

### Release version bump

There is no `package_info` lookup. Bump **all** of:

1. `pubspec.yaml` `version:` (`x.y.z+N` — `+N` is Android `versionCode`)
2. Hardcoded `'1.1.1'` on the Settings about tile
   (`lib/presentation/pages/settings_page.dart`)
3. `play_store/README.md` if you are preparing a store upload

Then run the Play kit checklist.

## Pitfalls

| Symptom | Cause / fix |
|---------|-------------|
| Analyzer / tests fail in CI but pass locally | Match Flutter **3.44.1**. |
| Missing strings in Spanish (or English) | ARB key added to only one file; run `flutter gen-l10n`. |
| Release build tries to download fonts / crashes offline | Keep `allowRuntimeFetching = false`. Add new font files under `assets/google_fonts/` and to `pubspec.yaml` assets. PDF must `rootBundle.load` those files. |
| Play upload rejected for package name | `applicationId` must stay `time_register.davidmenendez.dev`. |
| Play upload rejected for signing | Upload key was reset; see [play_store/README.md](../play_store/README.md). `versionCode` in `pubspec.yaml` (`+N`) must be higher than the last uploaded build. |
| Settings still shows the old version after a bump | Also edit the hardcoded string in `settings_page.dart`. |
| Users lose data after an “update” | They uninstalled; local SQLite died. Prefer JSON backup/restore. Never drop tables in a migration. Android Auto Backup is already off; Apple system backups may still hold a copy. |
| Expecting iOS/macOS to skip iCloud like Android | There is no backup-exclusion flag in this repo. Documents-directory `time_register.db` can appear in iCloud / Time Machine. |
| macOS release vs debug network | Release entitlements: sandbox + user-selected files only. DebugProfile also has `network.server` + JIT for the Flutter tool — do not copy that into Release. |
| Overnight shift hours look negative or huge | Persist `HH:mm` only; reconstruct next-day end in `WorkEntry.fromMap`. |
| Job rate didn’t apply | Job has a null `hourly_rate` — form keeps the previous field value. |
| Jobs list empty / stale after restore | `JobsCubit` is not reloaded; tabs stay mounted. Restart the app. |
| Palette stuck on blue after restore | SQL default / old backups may store `'Blue'`; runtime writes `blue`. `fromMap` accepts `'Blue'` only through `orElse`. Do not use `AppPaletteExtension.name` for persistence. |
| Cannot log tomorrow’s shift | Date pickers cap at `DateTime.now()`. |
| Native `+` in the iPad-on-Mac sidebar has no label | Use `runsOnMac`; HomePage already switches to a `FilledButton`. |
| Glass tab bar replays its selection animation | Keep `ValueKey`s on the add button and tab bar; do not rebuild the native view when the add button appears. |
| Home money ≠ Stats money | Home/Summary use `totalToCollect` (hours + receipts). Stats uses hours earnings only. |
| PDF “total to collect” ignores deductions | By design: net line is hours only; to-collect is gross hours + receipts. |
| Changing the Settings tax rate rewrote old receipts | It must not. Tax is stored per `Expense`. Only new products use the default. |
| Store APK has six months of fake shifts | You shipped `--dart-define=DEMO_DATA=true`. Leave it unset for store builds. |
| `flutter test` can’t open SQLite | Prefer tests on pure utils (`backup_codec`, exporters, `stats`, `expense`) and BLoCs with mocks. |
| Debug has network, release does not | Flutter debug/profile manifests add INTERNET. Feature work must not assume connectivity. |
| Linux/Windows: missing plugin / empty DB | `initDesktopSqliteIfNeeded()` must run before opening SQLite (`sqflite_common_ffi`). |
| R8 strips SQLite | Keep the `-keep class org.sqlite.**` rules in `proguard-rules.pro`. |
| UI flicker on every save | `TimeTrackingBloc` patches in memory; do not emit `TimeTrackingLoading` on mutations. |
| Icon generator fails | Needs `FLUTTER_ROOT` and a Flutter SDK with cached Roboto. |
| Accidental Pro push to the public repo | Enable `.githooks` (`core.hooksPath`). Pro lives on `pro/*` and `lib/pro/`. |

## Tests worth mirroring

| Area | Test |
|------|------|
| Backup JSON | `test/core/utils/backup_codec_test.dart` |
| CSV columns / totals / receipts | `test/core/utils/csv_exporter_test.dart` |
| PDF builds (incl. landscape receipts) | `test/core/utils/pdf_exporter_test.dart` |
| Week/month aggregation | `test/core/utils/stats_test.dart` |
| Receipt tax rounding / JSON | `test/core/entities/expense_test.dart` |
| Use cases (CRUD / paid) | `test/core/usecases/time_tracking_usecase_test.dart` |
| BLoC paid/CRUD | `test/presentation/blocs/time_tracking_bloc_test.dart` |
| Summary filters | `test/presentation/pages/weekly_summary_page_test.dart` |
| Icon PNGs (manual) | `tool/generate_icons_test.dart` |

Add tests next to these when changing the matching codepath.
