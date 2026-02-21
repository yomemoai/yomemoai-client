// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Yomemo.AI';

  @override
  String get configuration => '配置';

  @override
  String get pleaseSetApiKey => '请先设置 API Key 以开始使用';

  @override
  String get yomemoApiKey => 'YoMemo API Key';

  @override
  String get enterApiKey => '输入 API Key';

  @override
  String get configured => '已配置';

  @override
  String get leaveEmptyToKeepCurrent => '留空则保持当前';

  @override
  String get privateKeyFile => '私钥文件';

  @override
  String get selectFileForEncryptionKey => '选择用作加密密钥的文件';

  @override
  String get localLock => '本地锁定';

  @override
  String get newPassword => '新密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get lockTimeoutMinutes => '锁定超时（分钟）';

  @override
  String get editor => '编辑器';

  @override
  String get confirmSwipeToDelete => '滑动删除前确认';

  @override
  String get confirmSwipeToDeleteSubtitle => '滑动删除记忆时弹出确认。';

  @override
  String get autoSaveIntervalSeconds => '自动保存间隔（秒）';

  @override
  String get autoSaveHelperText => '失焦时也会保存。范围：1-300';

  @override
  String get export => '导出';

  @override
  String get exportMemories => '导出记忆';

  @override
  String get exportMemoriesSubtitle => '导出到文件夹、memories.pl 或其他格式。';

  @override
  String get homeDefaultExpandedGroups => '首页：默认展开分组';

  @override
  String get homeDefaultExpandedGroupsHelp =>
      '首次打开时按 handle 前缀默认展开哪些分组。在首页展开/折叠后，会记住你的选择。';

  @override
  String get resetHomeToDefault => '将首页恢复为此默认';

  @override
  String get insightsAndNotifications => '洞察与通知';

  @override
  String get showRedBadgeOnInsights => '在洞察上显示红点';

  @override
  String get showRedBadgeOnInsightsSubtitle => '在应用栏显示有非空结果的规则数量。';

  @override
  String get enableHapticsForNewInsights => '新洞察时触觉反馈';

  @override
  String get enableHapticsForNewInsightsSubtitle => '出现新的高优先级洞察时轻微震动（在设备支持时）。';

  @override
  String get passwordsDoNotMatch => '两次密码不一致';

  @override
  String get settingsSaved => '设置已保存';

  @override
  String get saveAndConnect => '保存并连接';

  @override
  String get homeExpandedGroupsReset => '首页展开分组已恢复为默认。返回首页查看。';

  @override
  String get categoryVoice => '语音';

  @override
  String get categoryDaily => '每日';

  @override
  String get categoryYoMemo => 'YoMemo';

  @override
  String get categoryPlan => '计划';

  @override
  String get categoryGoals => '目标';

  @override
  String get categoryOther => '其他';

  @override
  String get labelNoHandle => '无 handle';

  @override
  String get encrypted => '已加密';

  @override
  String get lock => '锁定';

  @override
  String get searchHandles => '搜索 handle...';

  @override
  String get all => '全部';

  @override
  String get insights => '洞察';

  @override
  String get noMemoriesFound => '暂无记忆，点击 + 创建';

  @override
  String get overview => '概览';

  @override
  String get refresh => '刷新';

  @override
  String get overviewTagline1 => '为每次 LLM 会话提供不可变、零信任记忆。';

  @override
  String get overviewTagline2 => 'YoMemo 保护静态与检索中的记忆。';

  @override
  String get memories => '记忆';

  @override
  String get handles => 'Handle';

  @override
  String lastSync(String time) {
    return '上次同步：$time';
  }

  @override
  String lastAttempt(String time) {
    return '上次尝试：$time';
  }

  @override
  String lastError(String error) {
    return '上次错误：$error';
  }

  @override
  String get docs => '文档';

  @override
  String get github => 'GitHub';

  @override
  String failedToOpen(String label) {
    return '无法打开 $label';
  }

  @override
  String get helpAndDocs => '帮助与文档';

  @override
  String get addMemoryInHandle => '在此 handle 下添加记忆';

  @override
  String get deleteAllInHandle => '删除此 handle 下全部';

  @override
  String get deleteMemory => '删除这条记忆？';

  @override
  String get deleteMemoryConfirm => '此操作不可撤销，记忆将被移除。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String deleteFailed(String error) {
    return '删除失败：$error';
  }

  @override
  String get deleted => '已删除';

  @override
  String get newBadge => '新';

  @override
  String get copied => '已复制';

  @override
  String get copy => '复制';

  @override
  String get edit => '编辑';

  @override
  String get deleteEntireHandle => '删除整个 handle？';

  @override
  String deleteEntireHandleConfirm(int count, String handle) {
    return '确定删除 \"$handle\" 下的 $count 条记忆？此操作不可撤销。';
  }

  @override
  String get deleteAll => '全部删除';

  @override
  String deletedCountMemories(int count) {
    return '已删除 $count 条记忆';
  }

  @override
  String get exportMemoriesTitle => '导出记忆';

  @override
  String get chooseExportFormat => '选择导出格式，后续可能增加更多选项。';

  @override
  String get exportToFolder => '导出到文件夹';

  @override
  String get exportToFolderSubtitle =>
      '每个 handle 一个子文件夹，内含 metadata.json 与每条记忆的 .txt 文件。';

  @override
  String get noMemoriesToExport => '没有可导出的记忆';

  @override
  String get exportCancelledOrNotSupported => '已取消或当前平台不支持导出';

  @override
  String exportedHandlesCount(int count) {
    return '已导出 $count 个 handle 到所选文件夹';
  }

  @override
  String exportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get exportMemoriesPl => '导出 memories.pl';

  @override
  String get exportMemoriesPlSubtitle =>
      'Prolog 事实与规则，用于调试。分享/保存文件，若分享失败可复制到剪贴板。';

  @override
  String get memoriesPlReady => 'memories.pl 已就绪（已保存或分享）';

  @override
  String get shareFailedCopiedToClipboard => '分享失败；已复制到剪贴板。粘贴并另存为 memories.pl';

  @override
  String saveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String get copyMemoriesPlToClipboard => '复制 memories.pl 到剪贴板';

  @override
  String get copyMemoriesPlSubtitle => '粘贴到文件中并另存为 memories.pl。';

  @override
  String get copiedPasteSaveMemoriesPl => '已复制。粘贴到文件并另存为 memories.pl';

  @override
  String copyFailed(String error) {
    return '复制失败：$error';
  }

  @override
  String get setLocalPassword => '设置本地密码';

  @override
  String get createLocalPasswordHint => '创建本地密码以保护本设备上的记忆。';

  @override
  String get savePassword => '保存密码';

  @override
  String get passwordRequired => '请输入密码';

  @override
  String get locked => '已锁定';

  @override
  String get password => '密码';

  @override
  String get incorrectPassword => '密码错误';

  @override
  String get unlock => '解锁';

  @override
  String get editMemory => '编辑记忆';

  @override
  String get newMemory => '新建记忆';

  @override
  String get writing => '写作中...';

  @override
  String get handle => 'Handle';

  @override
  String get descriptionOptional => '描述（选填）';

  @override
  String get startWritingMemory => '开始写下你的记忆...';

  @override
  String get speakToCaptureMemory => '说话以录入记忆';

  @override
  String get voiceCaptureOnlyMobile => '语音录入仅在移动端可用。';

  @override
  String speechError(String error) {
    return '语音错误：$error';
  }

  @override
  String get speechRecognitionNotAvailable => '语音识别不可用';

  @override
  String get contentRequired => '请填写内容';

  @override
  String failedToSave(String error) {
    return '保存失败：$error';
  }

  @override
  String get memoryDetail => '记忆详情';

  @override
  String get noRulesToDisplay => '暂无规则可展示。';

  @override
  String get resetToDefaultRules => '恢复默认规则';

  @override
  String get openDetails => '查看详情';

  @override
  String get language => '语言';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get memoryPanelToday => '今日新增';

  @override
  String get memoryPanelAll => '全部记忆';

  @override
  String get settingsDefaultMemoryPanel => '记忆列表默认显示';

  @override
  String get settingsDefaultMemoryPanelDesc => '打开首页时默认显示的列表。';
}
