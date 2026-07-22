import 'package:flutter_test/flutter_test.dart';
import 'package:inkflow/models/settings.dart';
import 'package:inkflow/services/image_host/image_path_builder.dart';

void main() {
  group('buildRemoteImagePath', () {
    test('基础路径 + 原始文件名', () {
      final result = buildRemoteImagePath(
        'images',
        'photo.png',
        dateFolderMode: ImageDateFolderMode.none,
        namingMode: ImageNamingMode.original,
      );
      expect(result, 'images/photo.png');
    });

    test('带日期子目录', () {
      final now = DateTime.now();
      final result = buildRemoteImagePath(
        'images',
        'photo.png',
        dateFolderMode: ImageDateFolderMode.yearMonth,
        namingMode: ImageNamingMode.original,
      );
      expect(result, contains('images/'));
      expect(result, contains('/${now.month.toString().padLeft(2, '0')}/'));
      expect(result, endsWith('/photo.png'));
    });

    test('时间戳命名模式', () {
      final result = buildRemoteImagePath(
        'img',
        'photo.jpg',
        dateFolderMode: ImageDateFolderMode.none,
        namingMode: ImageNamingMode.timestamp,
      );
      // 应以数字时间戳开头，保留扩展名
      final filename = result.split('/').last;
      expect(filename, matches(RegExp(r'^\d+\.jpg$')));
    });

    test('时间戳_原始名 命名模式', () {
      final result = buildRemoteImagePath(
        'img',
        'photo.jpg',
        dateFolderMode: ImageDateFolderMode.none,
        namingMode: ImageNamingMode.timestampOriginal,
      );
      final filename = result.split('/').last;
      expect(filename, matches(RegExp(r'^\d+_photo\.jpg$')));
    });

    test('空基础路径不产生前导斜杠', () {
      final result = buildRemoteImagePath(
        '',
        'photo.png',
        dateFolderMode: ImageDateFolderMode.none,
        namingMode: ImageNamingMode.original,
      );
      expect(result, 'photo.png');
      expect(result, isNot(startsWith('/')));
    });

    test('基础路径首尾多余斜杠被清理', () {
      final result = buildRemoteImagePath(
        '/images/',
        'photo.png',
        dateFolderMode: ImageDateFolderMode.none,
        namingMode: ImageNamingMode.original,
      );
      expect(result, 'images/photo.png');
    });

    test('日期子目录 + 时间戳命名组合', () {
      final now = DateTime.now();
      final result = buildRemoteImagePath(
        'uploads',
        'test.png',
        dateFolderMode: ImageDateFolderMode.yearMonth,
        namingMode: ImageNamingMode.timestamp,
      );
      expect(result, startsWith('uploads/'));
      expect(result, contains('${now.year}/'));
      final filename = result.split('/').last;
      expect(filename, matches(RegExp(r'^\d+\.png$')));
    });
  });
}
