import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Time Register'**
  String get appTitle;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @summaryTab.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get weeklySummary;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @toCollect.
  ///
  /// In en, this message translates to:
  /// **'To Collect'**
  String get toCollect;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @viewSummary.
  ///
  /// In en, this message translates to:
  /// **'View Summary'**
  String get viewSummary;

  /// No description provided for @noEntriesFilter.
  ///
  /// In en, this message translates to:
  /// **'No entries match the current filter'**
  String get noEntriesFilter;

  /// No description provided for @weekOf.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String weekOf(String date);

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @markAsUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Unpaid'**
  String get markAsUnpaid;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRate;

  /// No description provided for @defaultRate.
  ///
  /// In en, this message translates to:
  /// **'Default Hourly Rate'**
  String get defaultRate;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeAndColor.
  ///
  /// In en, this message translates to:
  /// **'Theme & Colors'**
  String get themeAndColor;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get appInfo;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @colors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get colors;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteEntry;

  /// No description provided for @deleteEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this entry?'**
  String get deleteEntryConfirm;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get undo;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get noEntries;

  /// No description provided for @addWorkEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Work Entry'**
  String get addWorkEntry;

  /// No description provided for @editWorkEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Work Entry'**
  String get editWorkEntry;

  /// No description provided for @saveEntry.
  ///
  /// In en, this message translates to:
  /// **'Save Entry'**
  String get saveEntry;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @lunchBreak.
  ///
  /// In en, this message translates to:
  /// **'Lunch Break'**
  String get lunchBreak;

  /// No description provided for @deductLunch.
  ///
  /// In en, this message translates to:
  /// **'Deduct 0.5 hours'**
  String get deductLunch;

  /// No description provided for @rateForEntry.
  ///
  /// In en, this message translates to:
  /// **'Rate for this entry'**
  String get rateForEntry;

  /// No description provided for @defaultRateFromSettings.
  ///
  /// In en, this message translates to:
  /// **'Default rate from settings'**
  String get defaultRateFromSettings;

  /// No description provided for @totalHours.
  ///
  /// In en, this message translates to:
  /// **'Total Hours'**
  String get totalHours;

  /// No description provided for @estimatedEarnings.
  ///
  /// In en, this message translates to:
  /// **'Estimated Earnings'**
  String get estimatedEarnings;

  /// No description provided for @enterRate.
  ///
  /// In en, this message translates to:
  /// **'Please enter a rate'**
  String get enterRate;

  /// No description provided for @validRate.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid positive number'**
  String get validRate;

  /// No description provided for @endTimeAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get endTimeAfterStart;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @allEntries.
  ///
  /// In en, this message translates to:
  /// **'All Entries'**
  String get allEntries;

  /// No description provided for @paidOnly.
  ///
  /// In en, this message translates to:
  /// **'Paid Only'**
  String get paidOnly;

  /// No description provided for @unpaidOnly.
  ///
  /// In en, this message translates to:
  /// **'Unpaid Only'**
  String get unpaidOnly;

  /// No description provided for @paidStatus.
  ///
  /// In en, this message translates to:
  /// **'This entry has been paid'**
  String get paidStatus;

  /// No description provided for @unpaidStatus.
  ///
  /// In en, this message translates to:
  /// **'This entry has not been paid yet'**
  String get unpaidStatus;

  /// No description provided for @errorMsg.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorMsg(String message);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @editHourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Edit Hourly Rate'**
  String get editHourlyRate;

  /// No description provided for @enterHourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Enter your hourly rate'**
  String get enterHourlyRate;

  /// No description provided for @enterRateValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a rate'**
  String get enterRateValidation;

  /// No description provided for @enterValidNumberValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid positive number'**
  String get enterValidNumberValidation;

  /// No description provided for @rateUpdated.
  ///
  /// In en, this message translates to:
  /// **'Hourly rate updated successfully'**
  String get rateUpdated;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your app experience with different color schemes and dark/light modes.'**
  String get appearanceSubtitle;

  /// No description provided for @hourlyRateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This rate will be applied to new work entries. Existing entries will keep their original rate.'**
  String get hourlyRateSubtitle;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'per hour'**
  String get perHour;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Track your work hours and earnings'**
  String get appDescription;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to Use'**
  String get howToUse;

  /// No description provided for @howToUseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn how to track your work hours'**
  String get howToUseSubtitle;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get gotIt;

  /// No description provided for @helpAddWorkEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Add Work Entry'**
  String get helpAddWorkEntryTitle;

  /// No description provided for @helpAddWorkEntryDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button on the home screen to log your daily work hours.'**
  String get helpAddWorkEntryDesc;

  /// No description provided for @helpSetTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Set Times'**
  String get helpSetTimesTitle;

  /// No description provided for @helpSetTimesDesc.
  ///
  /// In en, this message translates to:
  /// **'Select your start and end times. Toggle lunch break to deduct 0.5 hours.'**
  String get helpSetTimesDesc;

  /// No description provided for @helpViewSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'3. View Summary'**
  String get helpViewSummaryTitle;

  /// No description provided for @helpViewSummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Check the Summary tab to see your weekly earnings and hours.'**
  String get helpViewSummaryDesc;

  /// No description provided for @helpUpdateRateTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Update Rate'**
  String get helpUpdateRateTitle;

  /// No description provided for @helpUpdateRateDesc.
  ///
  /// In en, this message translates to:
  /// **'Change your hourly rate in Settings. New entries will use the updated rate.'**
  String get helpUpdateRateDesc;

  /// No description provided for @lunchStart.
  ///
  /// In en, this message translates to:
  /// **'Lunch Start'**
  String get lunchStart;

  /// No description provided for @lunchEnd.
  ///
  /// In en, this message translates to:
  /// **'Lunch End'**
  String get lunchEnd;

  /// No description provided for @descriptionNote.
  ///
  /// In en, this message translates to:
  /// **'Description / Note'**
  String get descriptionNote;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add details about this work entry...'**
  String get descriptionHint;

  /// No description provided for @lunchWithinShift.
  ///
  /// In en, this message translates to:
  /// **'Lunch break must be within the work shift'**
  String get lunchWithinShift;

  /// No description provided for @endsNextDay.
  ///
  /// In en, this message translates to:
  /// **'Ends the next day'**
  String get endsNextDay;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @markedAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Marked as paid'**
  String get markedAsPaid;

  /// No description provided for @markedAsUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Marked as unpaid'**
  String get markedAsUnpaid;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @editCurrency.
  ///
  /// In en, this message translates to:
  /// **'Edit Currency Symbol'**
  String get editCurrency;

  /// No description provided for @enterCurrencySymbol.
  ///
  /// In en, this message translates to:
  /// **'Enter the symbol shown next to amounts'**
  String get enterCurrencySymbol;

  /// No description provided for @enterSymbolValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a symbol'**
  String get enterSymbolValidation;

  /// No description provided for @currencyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Currency symbol updated'**
  String get currencyUpdated;

  /// No description provided for @currencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'This symbol is shown next to all amounts in the app.'**
  String get currencySubtitle;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs / Clients'**
  String get jobs;

  /// No description provided for @jobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage jobs and their hourly rates'**
  String get jobsSubtitle;

  /// No description provided for @addJob.
  ///
  /// In en, this message translates to:
  /// **'Add Job'**
  String get addJob;

  /// No description provided for @editJob.
  ///
  /// In en, this message translates to:
  /// **'Edit Job'**
  String get editJob;

  /// No description provided for @jobName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get jobName;

  /// No description provided for @enterNameValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get enterNameValidation;

  /// No description provided for @jobRateOptional.
  ///
  /// In en, this message translates to:
  /// **'Hourly rate (optional)'**
  String get jobRateOptional;

  /// No description provided for @jobRateHelper.
  ///
  /// In en, this message translates to:
  /// **'Overrides the default rate for this job'**
  String get jobRateHelper;

  /// No description provided for @jobColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get jobColor;

  /// No description provided for @deleteJob.
  ///
  /// In en, this message translates to:
  /// **'Delete Job'**
  String get deleteJob;

  /// No description provided for @deleteJobConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this job? Its entries will be kept, without a job.'**
  String get deleteJobConfirm;

  /// No description provided for @noJobs.
  ///
  /// In en, this message translates to:
  /// **'No jobs yet. Add one to organize your entries by client.'**
  String get noJobs;

  /// No description provided for @job.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get job;

  /// No description provided for @noJob.
  ///
  /// In en, this message translates to:
  /// **'No job'**
  String get noJob;

  /// No description provided for @archiveJob.
  ///
  /// In en, this message translates to:
  /// **'Archived (hidden for new entries)'**
  String get archiveJob;

  /// No description provided for @defaultRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Default rate'**
  String get defaultRateLabel;

  /// No description provided for @clockIn.
  ///
  /// In en, this message translates to:
  /// **'Clock In'**
  String get clockIn;

  /// No description provided for @clockOut.
  ///
  /// In en, this message translates to:
  /// **'Clock Out'**
  String get clockOut;

  /// No description provided for @shiftInProgress.
  ///
  /// In en, this message translates to:
  /// **'Shift in progress'**
  String get shiftInProgress;

  /// No description provided for @shiftStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Started at {time}'**
  String shiftStartedAt(String time);

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Back Up Data'**
  String get backupData;

  /// No description provided for @backupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save all your entries and settings to a file'**
  String get backupSubtitle;

  /// No description provided for @restoreData.
  ///
  /// In en, this message translates to:
  /// **'Restore Data'**
  String get restoreData;

  /// No description provided for @restoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Load entries and settings from a backup file'**
  String get restoreSubtitle;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'This will replace ALL current entries and settings with the backup contents. This cannot be undone.'**
  String get restoreConfirmMsg;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully'**
  String get restoreSuccess;

  /// No description provided for @restoreInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'The selected file is not a valid Time Register backup'**
  String get restoreInvalidFile;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @nothingToExport.
  ///
  /// In en, this message translates to:
  /// **'No entries to export'**
  String get nothingToExport;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How your data is handled'**
  String get privacyPolicySubtitle;

  /// No description provided for @privacyPolicyContent.
  ///
  /// In en, this message translates to:
  /// **'Time Register does not collect, transmit, or share any personal data.\n\nEverything you enter (work entries, rates, notes, and settings) is stored only in a local database on your device. The app does not connect to the internet, has no analytics, and shows no ads.\n\nUninstalling the app permanently deletes all of its data. The full policy is available in the project repository on GitHub.'**
  String get privacyPolicyContent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
