import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkflow/services/clipboard_image_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('pasteboard');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('inkflow_clipboard_test');
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// 模拟剪贴板：没有位图，只有 [files] 列出的文件。
  void mockClipboardFiles(List<String> files) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return switch (call.method) {
        'image' => null,
        'files' => files,
        _ => null,
      };
    });
  }

  Future<File> writeFile(String name, List<int> bytes) async {
    final file = File('${tempDir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  test('剪贴板里没有图片文件时返回空列表', () async {
    final txt = await writeFile('notes.txt', const [1, 2, 3]);
    final pdf = await writeFile('doc.pdf', const [4, 5, 6]);
    mockClipboardFiles([txt.path, pdf.path]);

    expect(await ClipboardImage.readAll(), isEmpty);
    expect(await ClipboardImage.read(), isNull);
  });

  test('剪贴板里有图片文件时按顺序读取并保留文件名', () async {
    final png = await writeFile('photo.png', const [
      0x89,
      0x50,
      0x4E,
      0x47,
      1,
      2,
      3,
      4,
    ]);
    final jpg = await writeFile('cover.JPG', const [0xFF, 0xD8, 0xFF, 9, 9]);
    final txt = await writeFile('notes.txt', const [1, 2, 3]);
    mockClipboardFiles([
      png.path,
      txt.path,
      jpg.path,
      '${tempDir.path}${Platform.pathSeparator}missing.png',
    ]);

    final images = await ClipboardImage.readAll();

    expect(images.length, 2);
    expect(images[0].filename, 'photo.png');
    expect(images[1].filename, 'cover.JPG');
    expect(images.every((image) => image.fromFile), isTrue);
    expect(images[0].bytes.length, 8);

    final first = await ClipboardImage.read();
    expect(first?.filename, 'photo.png');
  });

  test('跳过目录和空文件', () async {
    final dir = Directory('${tempDir.path}${Platform.pathSeparator}folder.png');
    await dir.create();
    final empty = await writeFile('empty.png', const []);
    mockClipboardFiles([dir.path, empty.path]);

    expect(await ClipboardImage.readAll(), isEmpty);
  });

  test('Windows 反斜杠路径也能取出文件名', () async {
    if (!Platform.isWindows) return;
    final file = await writeFile('win.png', const [0x89, 0x50, 0x4E, 0x47, 7]);
    mockClipboardFiles([file.path.replaceAll('/', '\\')]);

    final images = await ClipboardImage.readAll();
    expect(images.length, 1);
    expect(images.single.filename, 'win.png');
  });

  test('剪贴板位图数据仍然优先', () async {
    final file = await writeFile('from-file.png', const [
      0x89,
      0x50,
      0x4E,
      0x47,
      1,
    ]);
    final bitmapBytes = Uint8List.fromList(const [0x89, 0x50, 0x4E, 0x47, 2]);
    final bitmapPath = await writeFile('bitmap.bmp', bitmapBytes);

    messenger.setMockMethodCallHandler(channel, (call) async {
      return switch (call.method) {
        // Windows 的 pasteboard 插件返回临时文件路径，其它平台返回字节。
        'image' => Platform.isWindows ? bitmapPath.path : bitmapBytes,
        'files' => [file.path],
        _ => null,
      };
    });

    final images = await ClipboardImage.readAll();
    expect(images.length, 1);
    expect(images.single.fromFile, isFalse);
    expect(images.single.filename, startsWith('clipboard-'));
    expect(images.single.filename, endsWith('.png'));
  });
}
