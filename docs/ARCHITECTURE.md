# Architecture — Time Register

Time Register is an offline Flutter app for logging work hours and calculating
earnings. All state lives in a local SQLite database. There is no account, no
backend, and the Android **release** build has no `INTERNET` permission.

This document describes how the current code is structured. For setup,
migrations, and troubleshooting, see [DEVELOPER.md](DEVELOPER.md).

## Layers

The project follows Clean Architecture with BLoC/Cubit at the UI boundary.
Dependencies point inward: UI → use cases → repository interfaces → data.

| Layer | Path | Responsibility |
|-------|------|----------------|
| Presentation | `lib/presentation/` | Pages, widgets, BLoCs/Cubits |
| Domain | `lib/core/` | Entities, use cases, repository interfaces, SQLite helper, pure utils |
| Data | `lib/data/` | Local data sources, models, repository implementations, backup I/O |

Composition root: `lib/main.dart`. It calls `initDesktopSqliteIfNeeded()` (FFI
factory on Linux/Windows), disables Google Fonts runtime fetch, then wires
`DatabaseHelper` → data sources → repositories → use cases →
`MultiBlocProvider`. There is no DI framework. `DatabaseHelper` is a
singleton (`factory`); Settings backup/restore constructs
`BackupService(DatabaseHelper())` and still hits the same database.

```
lib/
├── core/
│   ├── database/      # SQLite (DatabaseHelper v9, desktop FFI)
│   ├── entities/      # WorkEntry, AppSettings, Job
│   ├── repositories/  # Abstract repositories
│   ├── usecases/      # One class per operation
│   ├── theme/         # Material 3 palettes
│   └── utils/         # CSV/PDF exporters, backup codec, stats (no I/O)
├── data/
│   ├── datasources/   # SQLite access
│   ├── models/        # WorkEntryModel
│   ├── repositories/  # Implementations
│   └── services/      # BackupService (file JSON ↔ database)
├── presentation/
│   ├── blocs/         # TimeTrackingBloc, SettingsBloc, ShiftTimerCubit, JobsCubit
│   ├── pages/         # Home, summary, stats, settings, jobs, entry form
│   ├── widgets/       # Floating nav, active-shift banner
│   └── utils/         # Currency helper
└── l10n/              # ARB sources + generated localizations (en, es)
```

`GetWeeklyEntries` exists in `lib/core/usecases/` but is **not** used by the
UI. Home, Summary, and Stats all read the in-memory `TimeTrackingBloc` list.
`WorkEntryModel.fromMap` duplicates overnight parsing from `WorkEntry.fromMap`
— keep both in sync.

## Screens and state

`HomePage` hosts four tabs in an `IndexedStack` (tabs stay mounted when you
switch) plus a floating nav bar and a gradient scrim so content fades as it
scrolls behind the bar. List views use ~100 px bottom padding for the bar.

Because tabs stay mounted, a restore that reloads `SettingsBloc` and
`TimeTrackingBloc` but not `JobsCubit` leaves the Jobs screen on the old list
until the cubit is reloaded (open Jobs again after a restart, or call
`JobsCubit.load()`).

| Tab | Page | Reads |
|-----|------|--------|
| Home | `HomeContent` | entries, live shift, jobs |
| Summary | `WeeklySummaryPage` | entries grouped by ISO week (Monday start) |
| Statistics | `StatsPage` | last 8 weeks, last 6 months, earnings-by-job this month |
| Settings | `SettingsPage` | rates, theme, currency, deductions, backup, jobs, privacy link |

Home-only chrome:

- **FAB (+)** opens an empty `WorkEntryFormPage` (add mode).
- **AppBar play** clocks in (`ShiftTimerCubit.start`). Hidden while a shift
  is running.
- **Date filter** (AppBar calendar) limits the list to one day. Range is
  2020–today, same as the entry form.

```mermaid
flowchart LR
  UI[Pages / widgets]
  BLoC[TimeTrackingBloc / SettingsBloc]
  Cubit[ShiftTimerCubit / JobsCubit]
  UC[Use cases]
  Repo[Repository interfaces]
  DS[Local data sources]
  DB[(SQLite time_register.db)]

  UI --> BLoC
  UI --> Cubit
  BLoC --> UC
  Cubit --> Repo
  UC --> Repo
  Repo --> DS
  DS --> DB
```

| Store | State | Persistence | After a write |
|-------|-------|-------------|----------------|
| `TimeTrackingBloc` | All `WorkEntry` rows | `work_entries` | Patches the in-memory list |
| `SettingsBloc` | `AppSettings` | `settings` (except the live shift) | Re-reads SQLite |
| `ShiftTimerCubit` | `DateTime?` clock-in | `settings.active_shift_start` | Emits the new value |
| `JobsCubit` | `List<Job>` including archived | `jobs` | Reloads the full list |

`TimeTrackingBloc` keeps the list in memory. After add / update / delete /
mark-paid it patches that list (sorted by date desc, then `createdAt` desc)
instead of re-querying SQLite. A full reload happens only on
`LoadWorkEntries`, or when the current state is not `TimeTrackingLoaded`.
`LoadWorkEntries` does **not** emit `TimeTrackingLoading` if a list is already
on screen (avoids a spinner flash). Add uses the insert `id` via
`entry.copyWith(id: id)`.

`SettingsBloc` likewise skips the loading state when settings are already
loaded, but **mutations still call `getSettings()`**. `MaterialApp` rebuilds
only when `themeMode` or `palette` changes (`buildWhen` in `main.dart`), so
rate/currency edits do not rebuild the tree.

Cubits reload (`JobsCubit`) or emit (`ShiftTimerCubit`) after each write.

## Domain rules (verified in code)

### Hours and earnings

`WorkEntry.calculateTotalHours` uses minute precision. If lunch is enabled and
both lunch times are set, that duration is subtracted; otherwise a **0.5 h**
fallback is used (legacy rows). Hours are clamped at 0. Earnings are
`totalHours * hourlyRate` and are **snapshotted on the row** — later rate
changes do not rewrite history.

The per-entry rate is filled from, in order: the selected job’s optional rate
(only when that job has one), else the global default in Settings (or `14.0`
if settings have not loaded yet). Changing job on the form applies the job
rate only when that job has one; it does not revert to the global default
when you pick “no job” or a job without a rate.

New entries always persist `isPaid: false`. The paid switch is edit-mode only.
Home and Summary can toggle paid via `MarkEntryAsPaid` (no confirm dialog).

The form rejects a zero-length shift (`end == start`). If lunch is on, lunch
must have a non-zero duration and lunch end must not be after shift end
(`lunchWithinShift`). Inline field errors also raise a snackbar
(`fixFormErrors`) because the invalid field may be scrolled out of view.

Hourly rate on the form and in Settings must be **> 0**. Currency symbol is
required and max **5** characters. Deduction rate is **0–100**.

The date picker on the form and the home filter both use `firstDate: 2020`
and `lastDate: DateTime.now()` — future dates cannot be logged.

Add-mode defaults (when not clocking out): date today, **09:00–17:00**, lunch
off, lunch times **12:00–12:30** if later enabled.

Clearing the job on edit uses `copyWith(clearJobId: true)` so `job_id` becomes
`NULL` instead of keeping the previous id.

### Overnight shifts

Times are stored as `HH:mm` on the entry’s `date`. If end &lt; start, the shift
crosses midnight and end is treated as the next calendar day. Lunch times use
the same rule (lunch start before shift start → +1 day; lunch end before lunch
start → +1 day).

### Jobs

- Optional `hourly_rate` overrides the global default when creating/editing.
- Color is one of eight presets in `jobs_page.dart` (`jobColors`).
- Archiving hides the job from the form picker except if it is already on the
  entry being edited. Archived jobs stay in the jobs list (struck through).
- Deleting a job **unlinks** entries (`job_id = NULL`); entries are kept.
  Confirm dialog first. `job_id` is not a SQLite foreign key.
- List order from SQLite: `archived ASC, name ASC`.
- `Job.copyWith(clearHourlyRate: true)` is how a job drops its override.

### Deductions

Optional percentage (0–100) stored on settings. Off by default. When enabled,
net is `AppSettings.netOf(gross)` → `gross * (1 - rate/100)` in the UI and on
the PDF totals line. It is an estimate only — not written onto `work_entries`.

### Weeks and stats

Weeks start Monday (`date.weekday - 1`). `weeklyTotals` / `monthlyTotals` fill
empty periods with zeros. `earningsByJob` on the stats tab covers the current
calendar month `[firstOfMonth, firstOfNextMonth)`. Stats is empty until at
least one entry exists.

### Palettes

`AppPalette` values: `blue`, `purple`, `green`, `orange`. Seed colors live on
the `AppPaletteExtension` (`primary` / `secondary`). `AppTheme.getTheme`
builds Material 3 from `ColorScheme.fromSeed`.

Persisted `app_palette` is the Dart enum identifier (`blue`, not `Blue`).
`AppPaletteExtension.name` (`Blue`, …) is shadowed by the enum’s own `.name`
and is **not** used at runtime. `_onCreate` still inserts `'Blue'`;
`AppSettings.fromMap` only maps that capitalized default through
`orElse: AppPalette.blue`. After the user picks a palette, the row stores
`blue` / `purple` / `green` / `orange`.

### CSV vs PDF

Both export the **currently filtered** Summary list, date ascending, via
`share_plus`. Empty list → snackbar, no share sheet.

| | CSV | PDF |
|---|-----|-----|
| Lunch columns | yes/no + start/end | omitted |
| Money | raw numbers | currency symbol prefix |
| Net line | no | yes, when deductions are enabled |
| Fonts | n/a | bundled Lato Regular/Bold |

## Persistence

Database file: app documents directory / `time_register.db`. Current schema
version: **9**. Never edit an existing migration; add a new `oldVersion < N`
block. See [DEVELOPER.md](DEVELOPER.md#database-migrations).

Indexes (created in `_onCreate` and in migration 9):

- `idx_work_entries_date`
- `idx_work_entries_job_id`
- `idx_work_entries_is_paid`

### `work_entries`

| Column | Notes |
|--------|--------|
| `date` | `yyyy-MM-dd` |
| `start_time`, `end_time` | `HH:mm` |
| `lunch_taken` | 0/1 |
| `lunch_start_time`, `lunch_end_time` | nullable `HH:mm` |
| `total_hours`, `hourly_rate`, `earnings` | stored numbers |
| `is_paid` | 0/1 |
| `description` | nullable |
| `job_id` | nullable FK-like (no SQLite FK constraint) |
| `created_at` | ISO-8601 |

### `settings` (single row, `id = 1`)

`hourly_rate` (default 14.0), `theme_mode` (`light`/`dark`/`system`),
`app_palette` (see Palettes above), `currency_symbol`,
`active_shift_start` (ISO-8601 or null), `deductions_enabled`, `deduction_rate`.

`AppSettings` does **not** include the live shift; that column is owned by
`ShiftTimerCubit`. Theme is stored as `themeMode.toString().split('.').last`.

### `jobs`

`name`, `color` (ARGB int), `hourly_rate` (nullable), `archived` (0/1).

## Offline and privacy constraints

- `GoogleFonts.config.allowRuntimeFetching = false` in `main()`. UI typeface
  is bundled **Lato** (`GoogleFonts.latoTextTheme`). PDF export loads
  `Lato-Regular.ttf` / `Lato-Bold.ttf` via `rootBundle`.
- Android **release** has no `INTERNET` permission (debug/profile manifests
  add it for the Flutter tool). `url_launcher` opens the published privacy
  page in the **system browser** (`LaunchMode.externalApplication`); the
  app itself does not fetch that URL. The main manifest declares a
  `https` `VIEW` query for package visibility.
- OS cloud backup of the database is disabled
  (`android:allowBackup="false"`, `backup_rules.xml` /
  `data_extraction_rules.xml` exclude `time_register.db`).
- iOS `PrivacyInfo.xcprivacy`: no tracking, no collected data types.
  Accessed-API reasons are FileTimestamp `C617.1`, DiskSpace `E174.1`,
  UserDefaults `CA92.1` (Flutter/plugin requirements).
- Do not add network calls or telemetry without an explicit product decision.

Privacy copy lives in **three** places: `PRIVACY_POLICY.md`,
`docs/privacy.html` (GitHub Pages; the URL the app opens), and
`privacyPolicyContent` in both ARB files (in-app dialog). The Play Store kit
still links the GitHub blob of `PRIVACY_POLICY.md` — keep that in sync too.

## Related docs

- Product overview and schema snapshot: [README](../README.md)
- Setup, runbooks, pitfalls: [DEVELOPER.md](DEVELOPER.md)
- Contributing checklist: [CONTRIBUTING.md](../CONTRIBUTING.md)
- Play Store upload kit: [play_store/README.md](../play_store/README.md)
