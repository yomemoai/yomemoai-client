// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Yomemo.AI';

  @override
  String get configuration => 'Configuration';

  @override
  String get pleaseSetApiKey => 'Please set your API Key to get started';

  @override
  String get yomemoApiKey => 'YoMemo API Key';

  @override
  String get enterApiKey => 'Enter API Key';

  @override
  String get configured => 'Configured';

  @override
  String get leaveEmptyToKeepCurrent => 'Leave empty to keep current';

  @override
  String get privateKeyFile => 'Private Key File';

  @override
  String get selectFileForEncryptionKey =>
      'Select a file to use as encryption key';

  @override
  String get localLock => 'Local Lock';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get lockTimeoutMinutes => 'Lock Timeout (minutes)';

  @override
  String get editor => 'Editor';

  @override
  String get confirmSwipeToDelete => 'Confirm swipe-to-delete';

  @override
  String get confirmSwipeToDeleteSubtitle =>
      'Ask for confirmation when deleting a memory by swipe.';

  @override
  String get autoSaveIntervalSeconds => 'Auto-save Interval (seconds)';

  @override
  String get autoSaveHelperText => 'Also saves on blur. Range: 1-300';

  @override
  String get export => 'Export';

  @override
  String get exportMemories => 'Export memories';

  @override
  String get exportMemoriesSubtitle =>
      'Export to folder, memories.pl, or other formats.';

  @override
  String get homeDefaultExpandedGroups => 'Home: Default expanded groups';

  @override
  String get homeDefaultExpandedGroupsHelp =>
      'Which groups (by handle prefix) are expanded by default on first open. After you expand/collapse on Home, your choice is remembered.';

  @override
  String get resetHomeToDefault => 'Reset Home to this default';

  @override
  String get insightsAndNotifications => 'Insights & Notifications';

  @override
  String get showRedBadgeOnInsights => 'Show red badge on Insights';

  @override
  String get showRedBadgeOnInsightsSubtitle =>
      'Display the number of rules with non-empty results in the app bar.';

  @override
  String get enableHapticsForNewInsights => 'Enable haptics for new insights';

  @override
  String get enableHapticsForNewInsightsSubtitle =>
      'Light vibration / click when new high-priority insights appear (when supported by device).';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get saveAndConnect => 'Save & Connect';

  @override
  String get homeExpandedGroupsReset =>
      'Home expanded groups reset to default. Return to Home to see the change.';

  @override
  String get categoryVoice => 'Voice';

  @override
  String get categoryDaily => 'Daily';

  @override
  String get categoryYoMemo => 'YoMemo';

  @override
  String get categoryPlan => 'Plan';

  @override
  String get categoryGoals => 'Goals';

  @override
  String get categoryOther => 'Other';

  @override
  String get labelNoHandle => 'No handle';

  @override
  String get encrypted => 'Encrypted';

  @override
  String get lock => 'Lock';

  @override
  String get searchHandles => 'Search handles...';

  @override
  String get all => 'All';

  @override
  String get insights => 'Insights';

  @override
  String get noMemoriesFound => 'No memories found. Tap + to create one.';

  @override
  String get overview => 'Overview';

  @override
  String get refresh => 'Refresh';

  @override
  String get overviewTagline1 =>
      'Immutable, zero-trust memory for every LLM session.';

  @override
  String get overviewTagline2 =>
      'YoMemo protects memory at rest and in retrieval.';

  @override
  String get memories => 'Memories';

  @override
  String get handles => 'Handles';

  @override
  String lastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String lastAttempt(String time) {
    return 'Last attempt: $time';
  }

  @override
  String lastError(String error) {
    return 'Last error: $error';
  }

  @override
  String get docs => 'Docs';

  @override
  String get github => 'GitHub';

  @override
  String failedToOpen(String label) {
    return 'Failed to open $label';
  }

  @override
  String get helpAndDocs => 'Help & Docs';

  @override
  String get addMemoryInHandle => 'Add memory in this handle';

  @override
  String get deleteAllInHandle => 'Delete all in this handle';

  @override
  String get deleteMemory => 'Delete memory?';

  @override
  String get deleteMemoryConfirm =>
      'This cannot be undone. The memory will be removed.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String deleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get deleted => 'Deleted';

  @override
  String get newBadge => 'NEW';

  @override
  String get copied => 'Copied';

  @override
  String get copy => 'Copy';

  @override
  String get edit => 'Edit';

  @override
  String get deleteEntireHandle => 'Delete entire handle?';

  @override
  String deleteEntireHandleConfirm(int count, String handle) {
    return 'Delete all $count memories in \"$handle\"? This cannot be undone.';
  }

  @override
  String get deleteAll => 'Delete all';

  @override
  String deletedCountMemories(int count) {
    return 'Deleted $count memories';
  }

  @override
  String get exportMemoriesTitle => 'Export memories';

  @override
  String get chooseExportFormat =>
      'Choose an export format. More options may be added later.';

  @override
  String get exportToFolder => 'Export to folder';

  @override
  String get exportToFolderSubtitle =>
      'One subfolder per handle; each has metadata.json and one .txt file per memory.';

  @override
  String get noMemoriesToExport => 'No memories to export';

  @override
  String get exportCancelledOrNotSupported =>
      'Export cancelled or not supported on this platform';

  @override
  String exportedHandlesCount(int count) {
    return 'Exported $count handle(s) to selected folder';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get exportMemoriesPl => 'Export memories.pl';

  @override
  String get exportMemoriesPlSubtitle =>
      'Prolog facts + rules for debug. Share/save file, or copy to clipboard if share fails.';

  @override
  String get memoriesPlReady => 'memories.pl ready (saved or shared)';

  @override
  String get shareFailedCopiedToClipboard =>
      'Share failed; copied to clipboard. Paste and save as memories.pl';

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get copyMemoriesPlToClipboard => 'Copy memories.pl to clipboard';

  @override
  String get copyMemoriesPlSubtitle =>
      'Paste into a file and save as memories.pl.';

  @override
  String get copiedPasteSaveMemoriesPl =>
      'Copied. Paste into a file and save as memories.pl';

  @override
  String copyFailed(String error) {
    return 'Copy failed: $error';
  }

  @override
  String get setLocalPassword => 'Set Local Password';

  @override
  String get createLocalPasswordHint =>
      'Create a local password to protect your memories on this device.';

  @override
  String get savePassword => 'Save Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get locked => 'Locked';

  @override
  String get password => 'Password';

  @override
  String get incorrectPassword => 'Incorrect password';

  @override
  String get unlock => 'Unlock';

  @override
  String get editMemory => 'Edit Memory';

  @override
  String get newMemory => 'New Memory';

  @override
  String get writing => 'Writing...';

  @override
  String get handle => 'Handle';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get startWritingMemory => 'Start writing your memory...';

  @override
  String get speakToCaptureMemory => 'Speak to capture this memory';

  @override
  String get voiceCaptureOnlyMobile =>
      'Voice capture is only available on mobile.';

  @override
  String speechError(String error) {
    return 'Speech error: $error';
  }

  @override
  String get speechRecognitionNotAvailable =>
      'Speech recognition not available';

  @override
  String get contentRequired => 'Content is required';

  @override
  String failedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get memoryDetail => 'Memory Detail';

  @override
  String get noRulesToDisplay => 'No rules to display.';

  @override
  String get resetToDefaultRules => 'Reset to default rules';

  @override
  String get openDetails => 'Open details';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';
}
