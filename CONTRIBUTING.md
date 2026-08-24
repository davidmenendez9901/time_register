# Contributing to Time Register

Thanks for your interest in contributing! This document explains how to get set up and what we expect from contributions.

## Getting started

1. Fork and clone the repository.
2. Install [Flutter](https://docs.flutter.dev/get-started/install) **3.44.1** (stable; this is what CI runs). `pubspec.yaml` requires Dart `^3.9.2`.
3. Install dependencies and run the app:

   ```bash
   flutter pub get
   flutter run
   ```

## Before opening a pull request

CI runs these checks on every PR, so make sure they pass locally:

```bash
dart format lib test        # code formatting
flutter analyze             # static analysis (zero issues)
flutter test                # full test suite
```

If you change any string in `lib/l10n/*.arb`, add it to **both** `app_en.arb` and `app_es.arb` and regenerate the localizations:

```bash
flutter gen-l10n
```

Commit the generated `lib/l10n/app_localizations*.dart` files in the same PR.

## Guidelines

- **Architecture**: Clean Architecture. Domain logic in `lib/core/` (entities, use cases, repository interfaces, pure utils), persistence in `lib/data/`, UI in `lib/presentation/` (BLoC/Cubit + pages + widgets). Keep new code in the matching layer. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
- **Database changes**: never modify an existing migration. Bump the version in `DatabaseHelper` and add a new `if (oldVersion < N)` block in `_onUpgrade`. Keep `_onCreate` in sync with the latest schema (including indexes).
- **Tests**: add or update tests for behavior changes, especially use cases, BLoCs, and pure utils (`backup_codec`, exporters, `stats`).
- **Commits**: use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:`...).
- **Scope**: prefer small, focused PRs. Open an issue first for large features so we can discuss the approach.

Common pitfalls (Play Store `applicationId`, overnight shifts, backup restore, ARB keys): [docs/DEVELOPER.md](docs/DEVELOPER.md).

## Reporting bugs and requesting features

Open an issue describing:

- What you expected and what happened instead.
- Steps to reproduce (for bugs).
- Device/OS and app version.

All data in this app is stored locally on the device. This project is **100% offline** and **open source**:

- Never add analytics, crash reporting, ads, accounts or other network calls without discussing it in an issue first.
- Keep the Android **release** build free of the `INTERNET` permission.
- Do not enable Google Fonts runtime fetching (`GoogleFonts.config.allowRuntimeFetching` must stay `false`).
