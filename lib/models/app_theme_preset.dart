import 'package:flutter/material.dart';

class AppThemePreset {
  final String id;
  final String zhName;
  final String enName;
  final Color seedColor;

  const AppThemePreset({
    required this.id,
    required this.zhName,
    required this.enName,
    required this.seedColor,
  });

  String label({required bool zh}) => zh ? zhName : enName;
}

class AppThemePresets {
  static const defaultId = 'inkGreen';

  static const all = [
    AppThemePreset(
      id: defaultId,
      zhName: '墨绿',
      enName: 'Ink Green',
      seedColor: Color(0xFF277568),
    ),
    AppThemePreset(
      id: 'oceanBlue',
      zhName: '海蓝',
      enName: 'Ocean Blue',
      seedColor: Color(0xFF1565C0),
    ),
    AppThemePreset(
      id: 'violet',
      zhName: '堇紫',
      enName: 'Violet',
      seedColor: Color(0xFF6D4AFF),
    ),
    AppThemePreset(
      id: 'rose',
      zhName: '蔷薇',
      enName: 'Rose',
      seedColor: Color(0xFFB3365B),
    ),
    AppThemePreset(
      id: 'graphite',
      zhName: '石墨',
      enName: 'Graphite',
      seedColor: Color(0xFF53606A),
    ),
    AppThemePreset(
      id: 'amber',
      zhName: '琥珀',
      enName: 'Amber',
      seedColor: Color(0xFFB7791F),
    ),
  ];

  static AppThemePreset byId(String id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return all.first;
  }
}
