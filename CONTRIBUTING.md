# Contributing to Time Register

Thanks for your interest in contributing! This document explains how to get set up and what we expect from contributions.

## Getting started

1. Fork and clone the repository.
2. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable channel, see `environment.sdk` in `pubspec.yaml` for the minimum Dart SDK).
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

## Guidelines

- **Architecture**: the project follows Clean Architecture. Domain logic lives in `lib/core/` (entities, use cases, repository interfaces), persistence in `lib/data/`, and UI in `lib/presentation/` (BLoC + pages + widgets). Keep new code in the matching layer.
- **Database changes**: never modify an existing migration. Bump the version in `DatabaseHelper` and add a new `if (oldVersion < N)` block in `_onUpgrade`.
- **Tests**: add or update tests for behavior changes, especially use cases and BLoCs.
- **Commits**: use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:`...).
- **Scope**: prefer small, focused PRs. Open an issue first for large features so we can discuss the approach.

## Reporting bugs and requesting features

Open an issue describing:

- What you expected and what happened instead.
- Steps to reproduce (for bugs).
- Device/OS and app version.

All data in this app is stored locally on the device — please never add code that transmits user data without discussing it in an issue first.
