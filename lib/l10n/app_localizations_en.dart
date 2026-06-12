// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Time Register';

  @override
  String get homeTab => 'Home';

  @override
  String get summaryTab => 'Summary';

  @override
  String get settingsTab => 'Settings';

  @override
  String get weeklySummary => 'Weekly Summary';

  @override
  String get outstanding => 'Outstanding';

  @override
  String get toCollect => 'To Collect';

  @override
  String get thisWeek => 'This Week';

  @override
  String get performance => 'Performance';

  @override
  String get thisMonth => 'This Month';

  @override
  String get viewSummary => 'View Summary';

  @override
  String get noEntriesFilter => 'No entries match the current filter';

  @override
  String weekOf(String date) {
    return 'Week of $date';
  }

  @override
  String get markAsPaid => 'Mark as Paid';

  @override
  String get markAsUnpaid => 'Mark as Unpaid';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get settings => 'Settings';

  @override
  String get general => 'General';

  @override
  String get hourlyRate => 'Hourly Rate';

  @override
  String get defaultRate => 'Default Hourly Rate';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeAndColor => 'Theme & Colors';

  @override
  String get appInfo => 'App Info';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get help => 'Help';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get about => 'About';

  @override
  String get mode => 'Mode';

  @override
  String get colors => 'Colors';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get deleteEntry => 'Delete Entry';

  @override
  String get deleteEntryConfirm =>
      'Are you sure you want to delete this entry?';

  @override
  String get undo => 'UNDO';

  @override
  String get noEntries => 'No entries yet';

  @override
  String get addWorkEntry => 'Add Work Entry';

  @override
  String get editWorkEntry => 'Edit Work Entry';

  @override
  String get saveEntry => 'Save Entry';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get date => 'Date';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get lunchBreak => 'Lunch Break';

  @override
  String get deductLunch => 'Deduct 0.5 hours';

  @override
  String get rateForEntry => 'Rate for this entry';

  @override
  String get defaultRateFromSettings => 'Default rate from settings';

  @override
  String get totalHours => 'Total Hours';

  @override
  String get estimatedEarnings => 'Estimated Earnings';

  @override
  String get enterRate => 'Please enter a rate';

  @override
  String get validRate => 'Please enter a valid positive number';

  @override
  String get endTimeAfterStart => 'End time must be after start time';

  @override
  String get hours => 'Hours';

  @override
  String get earnings => 'Earnings';

  @override
  String get allEntries => 'All Entries';

  @override
  String get paidOnly => 'Paid Only';

  @override
  String get unpaidOnly => 'Unpaid Only';

  @override
  String get paidStatus => 'This entry has been paid';

  @override
  String get unpaidStatus => 'This entry has not been paid yet';

  @override
  String errorMsg(String message) {
    return 'Error: $message';
  }

  @override
  String get retry => 'Retry';

  @override
  String get editHourlyRate => 'Edit Hourly Rate';

  @override
  String get enterHourlyRate => 'Enter your hourly rate';

  @override
  String get enterRateValidation => 'Please enter a rate';

  @override
  String get enterValidNumberValidation =>
      'Please enter a valid positive number';

  @override
  String get rateUpdated => 'Hourly rate updated successfully';

  @override
  String get appearanceSubtitle =>
      'Customize your app experience with different color schemes and dark/light modes.';

  @override
  String get hourlyRateSubtitle =>
      'This rate will be applied to new work entries. Existing entries will keep their original rate.';

  @override
  String get perHour => 'per hour';

  @override
  String get appDescription => 'Track your work hours and earnings';

  @override
  String get howToUse => 'How to Use';

  @override
  String get howToUseSubtitle => 'Learn how to track your work hours';

  @override
  String get gotIt => 'Got it!';

  @override
  String get helpAddWorkEntryTitle => '1. Add Work Entry';

  @override
  String get helpAddWorkEntryDesc =>
      'Tap the + button on the home screen to log your daily work hours.';

  @override
  String get helpSetTimesTitle => '2. Set Times';

  @override
  String get helpSetTimesDesc =>
      'Select your start and end times. Toggle lunch break to deduct 0.5 hours.';

  @override
  String get helpViewSummaryTitle => '3. View Summary';

  @override
  String get helpViewSummaryDesc =>
      'Check the Summary tab to see your weekly earnings and hours.';

  @override
  String get helpUpdateRateTitle => '4. Update Rate';

  @override
  String get helpUpdateRateDesc =>
      'Change your hourly rate in Settings. New entries will use the updated rate.';

  @override
  String get lunchStart => 'Lunch Start';

  @override
  String get lunchEnd => 'Lunch End';

  @override
  String get descriptionNote => 'Description / Note';

  @override
  String get descriptionHint => 'Add details about this work entry...';

  @override
  String get lunchWithinShift => 'Lunch break must be within the work shift';

  @override
  String get endsNextDay => 'Ends the next day';

  @override
  String get paid => 'Paid';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get markedAsPaid => 'Marked as paid';

  @override
  String get markedAsUnpaid => 'Marked as unpaid';

  @override
  String get currency => 'Currency';

  @override
  String get editCurrency => 'Edit Currency Symbol';

  @override
  String get enterCurrencySymbol => 'Enter the symbol shown next to amounts';

  @override
  String get enterSymbolValidation => 'Please enter a symbol';

  @override
  String get currencyUpdated => 'Currency symbol updated';

  @override
  String get currencySubtitle =>
      'This symbol is shown next to all amounts in the app.';

  @override
  String get statsTab => 'Statistics';

  @override
  String get lastWeeksChart => 'Last 8 weeks';

  @override
  String get lastMonthsChart => 'Last 6 months';

  @override
  String get earningsByJobChart => 'Earnings by job (this month)';

  @override
  String get noChartData =>
      'Not enough data yet. Add some work entries to see your statistics.';

  @override
  String get deductions => 'Deductions';

  @override
  String get deductionsSubtitle =>
      'Estimate taxes or other deductions as a percentage of your earnings. When disabled, deductions are not shown anywhere in the app.';

  @override
  String get enableDeductions => 'Enable deductions';

  @override
  String get deductionRate => 'Deduction percentage';

  @override
  String get editDeductionRate => 'Edit Deduction Percentage';

  @override
  String get enterPercentValidation => 'Enter a percentage between 0 and 100';

  @override
  String get net => 'Net';

  @override
  String get estimatedNet => 'Estimated net';

  @override
  String get deductionsUpdated => 'Deductions updated';

  @override
  String get jobs => 'Jobs / Clients';

  @override
  String get jobsSubtitle => 'Manage jobs and their hourly rates';

  @override
  String get addJob => 'Add Job';

  @override
  String get editJob => 'Edit Job';

  @override
  String get jobName => 'Name';

  @override
  String get enterNameValidation => 'Please enter a name';

  @override
  String get jobRateOptional => 'Hourly rate (optional)';

  @override
  String get jobRateHelper => 'Overrides the default rate for this job';

  @override
  String get jobColor => 'Color';

  @override
  String get deleteJob => 'Delete Job';

  @override
  String get deleteJobConfirm =>
      'Delete this job? Its entries will be kept, without a job.';

  @override
  String get noJobs =>
      'No jobs yet. Add one to organize your entries by client.';

  @override
  String get job => 'Job';

  @override
  String get noJob => 'No job';

  @override
  String get archiveJob => 'Archived (hidden for new entries)';

  @override
  String get defaultRateLabel => 'Default rate';

  @override
  String get clockIn => 'Clock In';

  @override
  String get clockOut => 'Clock Out';

  @override
  String get shiftInProgress => 'Shift in progress';

  @override
  String shiftStartedAt(String time) {
    return 'Started at $time';
  }

  @override
  String get dataSection => 'Data';

  @override
  String get backupData => 'Back Up Data';

  @override
  String get backupSubtitle => 'Save all your entries and settings to a file';

  @override
  String get restoreData => 'Restore Data';

  @override
  String get restoreSubtitle => 'Load entries and settings from a backup file';

  @override
  String get restoreConfirmTitle => 'Restore from backup?';

  @override
  String get restoreConfirmMsg =>
      'This will replace ALL current entries and settings with the backup contents. This cannot be undone.';

  @override
  String get restore => 'Restore';

  @override
  String get restoreSuccess => 'Backup restored successfully';

  @override
  String get restoreInvalidFile =>
      'The selected file is not a valid Time Register backup';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get nothingToExport => 'No entries to export';

  @override
  String get total => 'Total';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get privacyPolicySubtitle => 'How your data is handled';

  @override
  String get privacyPolicyContent =>
      'Time Register does not collect, transmit, or share any personal data.\n\nEverything you enter (work entries, rates, notes, and settings) is stored only in a local database on your device. The app does not connect to the internet, has no analytics, and shows no ads.\n\nUninstalling the app permanently deletes all of its data. The full policy is available in the project repository on GitHub.';
}
