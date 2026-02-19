import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Yomemo.AI'**
  String get appTitle;

  /// No description provided for @configuration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configuration;

  /// No description provided for @pleaseSetApiKey.
  ///
  /// In en, this message translates to:
  /// **'Please set your API Key to get started'**
  String get pleaseSetApiKey;

  /// No description provided for @yomemoApiKey.
  ///
  /// In en, this message translates to:
  /// **'YoMemo API Key'**
  String get yomemoApiKey;

  /// No description provided for @enterApiKey.
  ///
  /// In en, this message translates to:
  /// **'Enter API Key'**
  String get enterApiKey;

  /// No description provided for @configured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get configured;

  /// No description provided for @leaveEmptyToKeepCurrent.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to keep current'**
  String get leaveEmptyToKeepCurrent;

  /// No description provided for @privateKeyFile.
  ///
  /// In en, this message translates to:
  /// **'Private Key File'**
  String get privateKeyFile;

  /// No description provided for @selectFileForEncryptionKey.
  ///
  /// In en, this message translates to:
  /// **'Select a file to use as encryption key'**
  String get selectFileForEncryptionKey;

  /// No description provided for @localLock.
  ///
  /// In en, this message translates to:
  /// **'Local Lock'**
  String get localLock;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @lockTimeoutMinutes.
  ///
  /// In en, this message translates to:
  /// **'Lock Timeout (minutes)'**
  String get lockTimeoutMinutes;

  /// No description provided for @editor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editor;

  /// No description provided for @confirmSwipeToDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm swipe-to-delete'**
  String get confirmSwipeToDelete;

  /// No description provided for @confirmSwipeToDeleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask for confirmation when deleting a memory by swipe.'**
  String get confirmSwipeToDeleteSubtitle;

  /// No description provided for @autoSaveIntervalSeconds.
  ///
  /// In en, this message translates to:
  /// **'Auto-save Interval (seconds)'**
  String get autoSaveIntervalSeconds;

  /// No description provided for @autoSaveHelperText.
  ///
  /// In en, this message translates to:
  /// **'Also saves on blur. Range: 1-300'**
  String get autoSaveHelperText;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportMemories.
  ///
  /// In en, this message translates to:
  /// **'Export memories'**
  String get exportMemories;

  /// No description provided for @exportMemoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export to folder, memories.pl, or other formats.'**
  String get exportMemoriesSubtitle;

  /// No description provided for @homeDefaultExpandedGroups.
  ///
  /// In en, this message translates to:
  /// **'Home: Default expanded groups'**
  String get homeDefaultExpandedGroups;

  /// No description provided for @homeDefaultExpandedGroupsHelp.
  ///
  /// In en, this message translates to:
  /// **'Which groups (by handle prefix) are expanded by default on first open. After you expand/collapse on Home, your choice is remembered.'**
  String get homeDefaultExpandedGroupsHelp;

  /// No description provided for @resetHomeToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset Home to this default'**
  String get resetHomeToDefault;

  /// No description provided for @insightsAndNotifications.
  ///
  /// In en, this message translates to:
  /// **'Insights & Notifications'**
  String get insightsAndNotifications;

  /// No description provided for @showRedBadgeOnInsights.
  ///
  /// In en, this message translates to:
  /// **'Show red badge on Insights'**
  String get showRedBadgeOnInsights;

  /// No description provided for @showRedBadgeOnInsightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display the number of rules with non-empty results in the app bar.'**
  String get showRedBadgeOnInsightsSubtitle;

  /// No description provided for @enableHapticsForNewInsights.
  ///
  /// In en, this message translates to:
  /// **'Enable haptics for new insights'**
  String get enableHapticsForNewInsights;

  /// No description provided for @enableHapticsForNewInsightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light vibration / click when new high-priority insights appear (when supported by device).'**
  String get enableHapticsForNewInsightsSubtitle;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @saveAndConnect.
  ///
  /// In en, this message translates to:
  /// **'Save & Connect'**
  String get saveAndConnect;

  /// No description provided for @homeExpandedGroupsReset.
  ///
  /// In en, this message translates to:
  /// **'Home expanded groups reset to default. Return to Home to see the change.'**
  String get homeExpandedGroupsReset;

  /// No description provided for @categoryVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get categoryVoice;

  /// No description provided for @categoryDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get categoryDaily;

  /// No description provided for @categoryYoMemo.
  ///
  /// In en, this message translates to:
  /// **'YoMemo'**
  String get categoryYoMemo;

  /// No description provided for @categoryPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get categoryPlan;

  /// No description provided for @categoryGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get categoryGoals;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @labelNoHandle.
  ///
  /// In en, this message translates to:
  /// **'No handle'**
  String get labelNoHandle;

  /// No description provided for @encrypted.
  ///
  /// In en, this message translates to:
  /// **'Encrypted'**
  String get encrypted;

  /// No description provided for @lock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lock;

  /// No description provided for @searchHandles.
  ///
  /// In en, this message translates to:
  /// **'Search handles...'**
  String get searchHandles;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @noMemoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No memories found. Tap + to create one.'**
  String get noMemoriesFound;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @overviewTagline1.
  ///
  /// In en, this message translates to:
  /// **'Immutable, zero-trust memory for every LLM session.'**
  String get overviewTagline1;

  /// No description provided for @overviewTagline2.
  ///
  /// In en, this message translates to:
  /// **'YoMemo protects memory at rest and in retrieval.'**
  String get overviewTagline2;

  /// No description provided for @memories.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get memories;

  /// No description provided for @handles.
  ///
  /// In en, this message translates to:
  /// **'Handles'**
  String get handles;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String lastSync(String time);

  /// No description provided for @lastAttempt.
  ///
  /// In en, this message translates to:
  /// **'Last attempt: {time}'**
  String lastAttempt(String time);

  /// No description provided for @lastError.
  ///
  /// In en, this message translates to:
  /// **'Last error: {error}'**
  String lastError(String error);

  /// No description provided for @docs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get docs;

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github;

  /// No description provided for @failedToOpen.
  ///
  /// In en, this message translates to:
  /// **'Failed to open {label}'**
  String failedToOpen(String label);

  /// No description provided for @helpAndDocs.
  ///
  /// In en, this message translates to:
  /// **'Help & Docs'**
  String get helpAndDocs;

  /// No description provided for @addMemoryInHandle.
  ///
  /// In en, this message translates to:
  /// **'Add memory in this handle'**
  String get addMemoryInHandle;

  /// No description provided for @deleteAllInHandle.
  ///
  /// In en, this message translates to:
  /// **'Delete all in this handle'**
  String get deleteAllInHandle;

  /// No description provided for @deleteMemory.
  ///
  /// In en, this message translates to:
  /// **'Delete memory?'**
  String get deleteMemory;

  /// No description provided for @deleteMemoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. The memory will be removed.'**
  String get deleteMemoryConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(String error);

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newBadge;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @deleteEntireHandle.
  ///
  /// In en, this message translates to:
  /// **'Delete entire handle?'**
  String get deleteEntireHandle;

  /// No description provided for @deleteEntireHandleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all {count} memories in \"{handle}\"? This cannot be undone.'**
  String deleteEntireHandleConfirm(int count, String handle);

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @deletedCountMemories.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} memories'**
  String deletedCountMemories(int count);

  /// No description provided for @exportMemoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Export memories'**
  String get exportMemoriesTitle;

  /// No description provided for @chooseExportFormat.
  ///
  /// In en, this message translates to:
  /// **'Choose an export format. More options may be added later.'**
  String get chooseExportFormat;

  /// No description provided for @exportToFolder.
  ///
  /// In en, this message translates to:
  /// **'Export to folder'**
  String get exportToFolder;

  /// No description provided for @exportToFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One subfolder per handle; each has metadata.json and one .txt file per memory.'**
  String get exportToFolderSubtitle;

  /// No description provided for @noMemoriesToExport.
  ///
  /// In en, this message translates to:
  /// **'No memories to export'**
  String get noMemoriesToExport;

  /// No description provided for @exportCancelledOrNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled or not supported on this platform'**
  String get exportCancelledOrNotSupported;

  /// No description provided for @exportedHandlesCount.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} handle(s) to selected folder'**
  String exportedHandlesCount(int count);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @exportMemoriesPl.
  ///
  /// In en, this message translates to:
  /// **'Export memories.pl'**
  String get exportMemoriesPl;

  /// No description provided for @exportMemoriesPlSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prolog facts + rules for debug. Share/save file, or copy to clipboard if share fails.'**
  String get exportMemoriesPlSubtitle;

  /// No description provided for @memoriesPlReady.
  ///
  /// In en, this message translates to:
  /// **'memories.pl ready (saved or shared)'**
  String get memoriesPlReady;

  /// No description provided for @shareFailedCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Share failed; copied to clipboard. Paste and save as memories.pl'**
  String get shareFailedCopiedToClipboard;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(String error);

  /// No description provided for @copyMemoriesPlToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy memories.pl to clipboard'**
  String get copyMemoriesPlToClipboard;

  /// No description provided for @copyMemoriesPlSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste into a file and save as memories.pl.'**
  String get copyMemoriesPlSubtitle;

  /// No description provided for @copiedPasteSaveMemoriesPl.
  ///
  /// In en, this message translates to:
  /// **'Copied. Paste into a file and save as memories.pl'**
  String get copiedPasteSaveMemoriesPl;

  /// No description provided for @copyFailed.
  ///
  /// In en, this message translates to:
  /// **'Copy failed: {error}'**
  String copyFailed(String error);

  /// No description provided for @setLocalPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Local Password'**
  String get setLocalPassword;

  /// No description provided for @createLocalPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a local password to protect your memories on this device.'**
  String get createLocalPasswordHint;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save Password'**
  String get savePassword;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPassword;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @editMemory.
  ///
  /// In en, this message translates to:
  /// **'Edit Memory'**
  String get editMemory;

  /// No description provided for @newMemory.
  ///
  /// In en, this message translates to:
  /// **'New Memory'**
  String get newMemory;

  /// No description provided for @writing.
  ///
  /// In en, this message translates to:
  /// **'Writing...'**
  String get writing;

  /// No description provided for @handle.
  ///
  /// In en, this message translates to:
  /// **'Handle'**
  String get handle;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @startWritingMemory.
  ///
  /// In en, this message translates to:
  /// **'Start writing your memory...'**
  String get startWritingMemory;

  /// No description provided for @speakToCaptureMemory.
  ///
  /// In en, this message translates to:
  /// **'Speak to capture this memory'**
  String get speakToCaptureMemory;

  /// No description provided for @voiceCaptureOnlyMobile.
  ///
  /// In en, this message translates to:
  /// **'Voice capture is only available on mobile.'**
  String get voiceCaptureOnlyMobile;

  /// No description provided for @speechError.
  ///
  /// In en, this message translates to:
  /// **'Speech error: {error}'**
  String speechError(String error);

  /// No description provided for @speechRecognitionNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition not available'**
  String get speechRecognitionNotAvailable;

  /// No description provided for @contentRequired.
  ///
  /// In en, this message translates to:
  /// **'Content is required'**
  String get contentRequired;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSave(String error);

  /// No description provided for @memoryDetail.
  ///
  /// In en, this message translates to:
  /// **'Memory Detail'**
  String get memoryDetail;

  /// No description provided for @noRulesToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No rules to display.'**
  String get noRulesToDisplay;

  /// No description provided for @resetToDefaultRules.
  ///
  /// In en, this message translates to:
  /// **'Reset to default rules'**
  String get resetToDefaultRules;

  /// No description provided for @openDetails.
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get openDetails;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
