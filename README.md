# Time Register

[![CI](https://github.com/davidmenendez9901/time_register/actions/workflows/ci.yml/badge.svg)](https://github.com/davidmenendez9901/time_register/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A Flutter application for tracking daily work hours and calculating earnings. Perfect for freelancers, consultants, and hourly workers who need to keep accurate records of their time and income.

All data stays on your device — no account, no cloud, no tracking.

## 🎯 Features

### ⏰ Time Tracking
- **Easy Entry Creation**: Simple form to log work hours with start/end times
- **Live Timer**: Clock in/out from the home screen; the running shift survives app restarts
- **Jobs / Clients**: Organize entries by job, each with its own color and optional hourly rate
- **Overnight Shifts**: Shifts that cross midnight (e.g. 22:00 – 06:00) are handled automatically
- **Lunch Break Control**: Optional lunch break with custom start/end times
- **Notes**: Attach a description to any entry
- **Automatic Calculations**: Real-time calculation of total hours and earnings
- **Edit & Delete**: Full CRUD operations for work entries

### 💰 Payment Management
- **Payment Status**: Mark entries as paid or unpaid
- **Outstanding Balance**: See at a glance how much you are owed
- **Filtering**: View all, paid only, or unpaid entries
- **Per-Entry Rate**: Each entry keeps the hourly rate it was created with
- **CSV & PDF Export**: Share your entries (all, paid, or unpaid) as a spreadsheet-ready file or a printable work report
- **Backup & Restore**: Save everything to a file and load it on a new device

### 📊 Summaries
- **Weekly Grouping**: Entries organized by work weeks with expandable details
- **This Week / This Month / Outstanding** summary cards
- **Statistics**: Bar charts for the last 8 weeks and 6 months (hours or earnings) and an earnings-by-job breakdown
- **Daily Totals**: Hours and earnings per day on the home screen
- **Date Filter**: Jump to any day's entries

### ⚙️ Customization
- **Hourly Rate**: Configurable default rate for new entries
- **Currency Symbol**: Use $, €, or any symbol you like
- **Deduction Estimates**: Optional percentage (taxes etc.) showing net earnings; fully hidden when disabled
- **Theme Support**: Light, dark, and system theme modes with four color palettes
- **Languages**: English and Spanish
- **Persistent Settings**: All configurations saved locally

## 🌐 Website

Check out the landing page: **<https://davidmenendez9901.github.io/time_register/>**

## 📱 Screenshots

| Home | Summary | Statistics |
|------|---------|------------|
| ![Home](docs/screenshots/home.png) | ![Summary](docs/screenshots/summary.png) | ![Statistics](docs/screenshots/stats.png) |

| Summary (dark) | Statistics (dark) |
|----------------|-------------------|
| ![Summary dark](docs/screenshots/summary-dark.png) | ![Statistics dark](docs/screenshots/stats-dark.png) |

## 🏗️ Architecture

This app follows **Clean Architecture** principles with clear separation of concerns:

- **Presentation Layer** (`lib/presentation/`): BLoC pattern for state management, pages and widgets
- **Domain Layer** (`lib/core/`): Entities, use cases, and repository interfaces
- **Data Layer** (`lib/data/`): Local data sources and repository implementations
- **Database**: SQLite with versioned migrations

```
lib/
├── core/            # Domain layer
│   ├── entities/    # Business entities
│   ├── usecases/    # Business logic
│   ├── repositories/# Repository interfaces
│   ├── database/    # SQLite helper and migrations
│   └── theme/       # App themes and palettes
├── data/            # Data layer
│   ├── datasources/ # Local data sources
│   ├── models/      # Data models
│   └── repositories/# Repository implementations
├── presentation/    # UI layer
│   ├── blocs/       # State management
│   ├── pages/       # Screen widgets
│   ├── widgets/     # Reusable components
│   └── utils/       # UI helpers
└── l10n/            # Localization (en, es)
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- Android Studio / VS Code
- Android device or emulator

### Installation

```bash
git clone https://github.com/davidmenendez9901/time_register.git
cd time_register
flutter pub get
flutter run
```

### Running the checks

```bash
dart format lib test
flutter analyze
flutter test
```

## 📦 Main Dependencies

- **flutter_bloc**: State management
- **sqflite**: Local SQLite database
- **intl** + **flutter_localizations**: Date formatting and localization
- **font_awesome_flutter**: Icons
- **google_fonts**: Typography
- **animations**: Page transitions

## 🗄️ Database Schema

### Work Entries Table
```sql
CREATE TABLE work_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  lunch_taken INTEGER NOT NULL DEFAULT 0,
  total_hours REAL NOT NULL,
  hourly_rate REAL NOT NULL,
  earnings REAL NOT NULL,
  is_paid INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  lunch_start_time TEXT,
  lunch_end_time TEXT,
  description TEXT
)
```

### Settings Table
```sql
CREATE TABLE settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  hourly_rate REAL NOT NULL DEFAULT 0.0,
  theme_mode TEXT NOT NULL DEFAULT 'system',
  app_palette TEXT NOT NULL DEFAULT 'Blue',
  currency_symbol TEXT NOT NULL DEFAULT '$'
)
```

## 🔒 Privacy & Security

- **Local Data**: All information stored on device
- **No Cloud**: No external services or data transmission
- **No Network Permission**: The Android release build cannot access the internet
- **User Control**: Complete ownership of personal data

See the full [Privacy Policy](PRIVACY_POLICY.md).

## 📱 Platform Support

- ✅ Android (primary target)
- ✅ iOS
- ✅ macOS

## 🚀 Roadmap

- [x] CSV export
- [x] Backup and restore
- [x] Live timer (clock in / clock out)
- [x] Multiple jobs/clients with per-job rates
- [x] Tax/deduction estimates (optional, off by default)
- [x] Charts and analytics
- [x] PDF export
- [ ] Overtime rules (1.5x / 2x after N hours)
- [ ] Shift templates

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for setup instructions and guidelines, then open a pull request.

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

**Time Register** — Track your time, calculate your earnings, stay organized.
