import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:path/path.dart' as p;

import 'package:sqlite3/src/hook/description.dart';
import 'package:sqlite3/src/hook/used_symbols.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }

    final sqlite = SqliteBinary.forBuild(input);
    switch (sqlite) {
      case PrecompiledBinary():
        final library = sqlite.resolveLibrary(input.config.code);
        library.checkSupported();

        // 本地预编译库：先找 local_path_<os>（例如 local_path_windows /
        // local_path_android），找不到再回退到旧配置项 local_path。
        //
        // 命中时直接复制本地文件，跳过 GitHub 下载与 hash 校验；没有配置的
        // 平台（Linux / macOS 等）保持原有的下载行为，因此可以只为本机需要
        // 的平台提供离线库，而不会影响其它平台的构建。
        final targetOS = input.config.code.targetOS;
        final localPathUri =
            input.userDefines.path('local_path_${targetOS.name}') ??
            input.userDefines.path('local_path');

        File downloaded;
        if (localPathUri != null) {
          final localFile = File.fromUri(localPathUri);
          if (!localFile.existsSync()) {
            throw FileSystemException(
              'local_path 文件不存在',
              localPathUri.toFilePath(),
            );
          }
          // 让构建系统知道依赖了这个库文件，文件变化时会重新运行 hook。
          output.dependencies.add(localPathUri);

          // 复制到输出目录
          final dir = Directory(
            input.outputDirectoryShared.resolve(library.dirname).toFilePath(),
          );
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          final fileName = targetOS.libraryFileName(
            library.type.basename,
            DynamicLoadingBundled(),
          );
          downloaded = await localFile.copy('${dir.path}/$fileName');
        } else {
          downloaded = await sqlite.downloadIntoOutputDirectoryShared(
            input,
            output,
            library,
          );
        }

        output.assets.code.add(
          CodeAsset(
            package: package,
            name: name,
            linkMode: DynamicLoadingBundled(),
            file: downloaded.uri,
          ),
        );
      case CompileSqlite(:final sourceFile, :final defines):
        // With Flutter on Linux (which already dynamically links SQLite through
        // its libgtk dependency), we run into issues where loading our SQLite
        // build causes internal symbols to be resolved against the already
        // loaded library from the system.
        // This is terrible and not what we ever want. A proper solution may be
        // to use namespaces or RTLD_DEEPBIND, but hooks don't support that yet.
        // An alternative that seems to work is to pass -Bsymbolic-functions to
        // the linker.
        // For the full discussion, see https://github.com/dart-lang/native/issues/2724

        String? linkerScript;
        if (input.config.code.targetOS == OS.linux) {
          linkerScript = input.outputDirectory.resolve('sqlite.map').path;

          await File(linkerScript).writeAsString('''
{
  global:
${usedSqliteSymbols.map((symbol) => '    $symbol;').join('\n')}
  local:
    *;
};
''');
        }

        final library = CBuilder.library(
          name: 'sqlite3',
          packageName: 'sqlite3',
          assetName: name,
          sources: [sourceFile],
          includes: [p.dirname(sourceFile)],
          defines: defines,
          flags: [
            if (input.config.code.targetOS == OS.linux) ...[
              // This avoids loading issues on Linux, see comment above.
              '-Wl,-Bsymbolic',
              // And since we already have a designated list of symbols to
              // export, we might as well strip the rest.
              // TODO: Port this to other targets too.
              '-Wl,--version-script=$linkerScript',
              '-ffunction-sections',
              '-fdata-sections',
              '-Wl,--gc-sections',
            ],
            if (input.config.code.targetOS case OS.iOS || OS.macOS) ...[
              '-headerpad_max_install_names',
              // clang would use the temporary directory passed by
              // native_toolchain_c otherwise. So this makes improves
              // reproducibility.
              '-install_name',
              '@rpath/libsqlite3.dylib',
            ],
          ],
          libraries: [
            if (input.config.code.targetOS == OS.android)
              // We need to link the math library on Android.
              'm',
          ],
        );

        await library.run(input: input, output: output);
      case ExternalSqliteBinary():
        output.assets.code.add(
          CodeAsset(
            package: package,
            name: name,
            linkMode: sqlite.resolveLinkMode(input),
          ),
        );
    }
  });
}

const package = 'sqlite3';
const name = 'src/ffi/libsqlite3.g.dart';
