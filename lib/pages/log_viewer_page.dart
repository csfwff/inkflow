import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../services/log_service.dart';

/// 日志等级筛选
enum _LogLevelFilter { all, info, warn, error, userAction }

/// 日志条目
class _LogEntry {
  final DateTime? time;
  final LogLevel? level;
  final String tag;
  final String message;
  final String raw;

  _LogEntry({
    this.time,
    this.level,
    required this.tag,
    required this.message,
    required this.raw,
  });
}

class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key});

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  _LogLevelFilter _filter = _LogLevelFilter.all;
  List<_LogEntry> _entries = [];
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    final content = await LogService.instance.readAll();
    final lines = content.split('\n').where((l) => l.isNotEmpty).toList();
    final entries = lines.map(_parseLine).toList().reversed.toList();
    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  _LogEntry _parseLine(String line) {
    // 格式: [2026-07-01 12:34:56.789][INFO ][Sync] message
    final regex = RegExp(r'^\[(.+?)\]\s*\[(\w+)\s*\]\[(.+?)\]\s*(.+)$');
    final match = regex.firstMatch(line);

    if (match != null) {
      final timeStr = match.group(1)!;
      final levelStr = match.group(2)!;
      final tag = match.group(3)!;
      final message = match.group(4)!;

      DateTime? time;
      try {
        time = DateTime.parse(timeStr.replaceFirst(' ', 'T'));
      } catch (_) {}

      LogLevel? level;
      switch (levelStr.toUpperCase()) {
        case 'DEBUG':
          level = LogLevel.debug;
        case 'INFO':
          level = LogLevel.info;
        case 'WARN':
          level = LogLevel.warn;
        case 'ERROR':
          level = LogLevel.error;
      }

      return _LogEntry(time: time, level: level, tag: tag, message: message, raw: line);
    }

    // 旧格式或截断标记
    return _LogEntry(tag: 'App', message: line, raw: line);
  }

  List<_LogEntry> get _filteredEntries {
    switch (_filter) {
      case _LogLevelFilter.all:
        return _entries;
      case _LogLevelFilter.info:
        return _entries.where((e) => e.level == LogLevel.info && e.tag != 'UserAction').toList();
      case _LogLevelFilter.warn:
        return _entries.where((e) => e.level == LogLevel.warn).toList();
      case _LogLevelFilter.error:
        return _entries.where((e) => e.level == LogLevel.error).toList();
      case _LogLevelFilter.userAction:
        return _entries.where((e) => e.tag == 'UserAction').toList();
    }
  }

  Future<void> _copyAll() async {
    final content = _filteredEntries.map((e) => e.raw).join('\n');
    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.current.logCopied)),
      );
    }
  }

  Future<void> _clearLogs() async {
    final s = AppStrings.current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.logClear),
        content: Text(s.logClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.logClear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LogService.instance.clear();
      await _loadLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.current;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.logViewer),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: s.logViewer,
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(s),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEntries.isEmpty
                    ? Center(
                        child: Text(
                          s.logEmpty,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : _buildLogList(),
          ),
          _buildBottomBar(s),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppStrings s) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(s.logAll, _LogLevelFilter.all),
          const SizedBox(width: 8),
          _buildFilterChip(s.logInfo, _LogLevelFilter.info),
          const SizedBox(width: 8),
          _buildFilterChip(s.logWarn, _LogLevelFilter.warn),
          const SizedBox(width: 8),
          _buildFilterChip(s.logError, _LogLevelFilter.error),
          const SizedBox(width: 8),
          _buildFilterChip(s.logUserAction, _LogLevelFilter.userAction),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, _LogLevelFilter filter) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  Widget _buildLogList() {
    final filtered = _filteredEntries;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (ctx, index) => _buildLogItem(filtered[index]),
    );
  }

  Widget _buildLogItem(_LogEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间
          if (entry.time != null)
            Text(
              _formatTime(entry.time!),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          if (entry.time != null) const SizedBox(width: 8),
          // 等级标签
          if (entry.level != null) _buildLevelChip(entry.level!),
          if (entry.level != null) const SizedBox(width: 4),
          // Tag 标签
          if (entry.tag.isNotEmpty && entry.tag != 'App')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.tag,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (entry.tag.isNotEmpty && entry.tag != 'App') const SizedBox(width: 8),
          // 消息内容
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                fontSize: 13,
                color: entry.level == LogLevel.error
                    ? Theme.of(context).colorScheme.error
                    : entry.level == LogLevel.warn
                        ? Colors.orange
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelChip(LogLevel level) {
    final (color, label) = switch (level) {
      LogLevel.debug => (Colors.grey, 'DBG'),
      LogLevel.info => (Colors.blue, 'INF'),
      LogLevel.warn => (Colors.orange, 'WRN'),
      LogLevel.error => (Colors.red, 'ERR'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  Widget _buildBottomBar(AppStrings s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_filteredEntries.length} entries',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _copyAll,
            icon: const Icon(Icons.copy, size: 16),
            label: Text(s.logCopyAll),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _clearLogs,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: Text(s.logClear),
          ),
        ],
      ),
    );
  }
}
