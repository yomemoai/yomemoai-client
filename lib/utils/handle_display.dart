import 'package:flutter/material.dart';

/// Presentation for a memory handle: category, short label, and icon.
/// Keeps UI consistent without hardcoding rule ids (handles are dynamic).
class HandleDisplay {
  const HandleDisplay({
    required this.category,
    required this.label,
    required this.icon,
  });

  final String category;
  final String label;
  final IconData icon;

  /// Full display line for section headers: "Category · label" or just "label" when obvious.
  String get sectionTitle => label == category ? category : '$category · $label';
}

const IconData _folder = Icons.folder_outlined;
const IconData _mic = Icons.mic;
const IconData _calendar = Icons.calendar_today_outlined;
const IconData _doc = Icons.article_outlined;
const IconData _task = Icons.task_alt_outlined;
const IconData _flag = Icons.flag_outlined;
const IconData _goal = Icons.emoji_events_outlined;

/// Returns display info for [handle]. Handles are dynamic (e.g. from API);
/// we infer category from prefix/pattern for UI only.
HandleDisplay handleDisplay(String handle) {
  final h = handle.trim();
  if (h.isEmpty) return HandleDisplay(category: 'Other', label: 'No handle', icon: _folder);

  final lower = h.toLowerCase();
  if (lower.startsWith('voice-')) {
    final suffix = h.substring(6).trim();
    return HandleDisplay(
      category: 'Voice',
      label: suffix.isEmpty ? 'Voice' : suffix,
      icon: _mic,
    );
  }
  if (lower.startsWith('daily-')) {
    final suffix = h.substring(6).trim();
    return HandleDisplay(
      category: 'Daily',
      label: suffix.isEmpty ? 'Daily' : suffix,
      icon: _calendar,
    );
  }
  if (lower.startsWith('yomemo-')) {
    final suffix = h.substring(7).trim();
    final short = suffix.isEmpty ? 'YoMemo' : suffix;
    return HandleDisplay(
      category: 'YoMemo',
      label: short,
      icon: lower.contains('task') ? _task : _doc,
    );
  }
  if (lower == 'plan') return HandleDisplay(category: 'Plan', label: 'Plan', icon: _flag);
  if (lower == 'user-goals' || lower == 'goals') {
    return HandleDisplay(category: 'Goals', label: 'Goals', icon: _goal);
  }

  return HandleDisplay(category: 'Other', label: h, icon: _folder);
}

/// Category order for sorting handles in the list.
int handleCategoryOrder(String handle) {
  final lower = handle.trim().toLowerCase();
  if (lower.startsWith('voice-')) return 0;
  if (lower.startsWith('daily-')) return 1;
  if (lower.startsWith('yomemo-')) return 2;
  if (lower == 'plan') return 3;
  if (lower == 'user-goals' || lower == 'goals') return 4;
  return 5;
}

/// First segment of [handle] when split by "-". Used for grouping.
/// e.g. "yomemo-doc" -> "yomemo", "voice-2029-02-09" -> "voice", "plan" -> "plan".
String handlePrefix(String handle) {
  final h = handle.trim();
  if (h.isEmpty) return 'other';
  final parts = h.split('-');
  return parts.first.toLowerCase();
}

/// Order for prefix groups (same as handle category).
int prefixOrder(String prefix) {
  final p = prefix.toLowerCase();
  if (p == 'voice') return 0;
  if (p == 'daily') return 1;
  if (p == 'yomemo') return 2;
  if (p == 'plan') return 3;
  if (p == 'user-goals' || p == 'goals') return 4;
  return 5;
}
