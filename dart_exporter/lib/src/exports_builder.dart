import 'package:build/build.dart';
import 'package:dart_exporter/src/exporter_generator_builder.dart';
import 'package:glob/glob.dart';

/// the ExportsBuilder will create the file to
/// export all dart files
class DartExporterBuilder implements Builder {
  static var packageName = '';
  static const generatedFilePath = 'src/exports.dart_exporter.dart';

  @override
  final Map<String, List<String>> buildExtensions = {
    r'$lib$': [generatedFilePath]
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    print('[DART_EXPORTER] - Creating exports file');
    final exports = buildStep.findAssets(
        Glob('**/*${DartExporterInitializeBuilder.exportExtension}'));
    final expList = <String>[];
    final content = ['//! AUTO GENERATE FILE, DONT MODIFY!!'];
    await for (final exportLibrary in exports) {
      final exportUri = exportLibrary.changeExtension('.dart').uri;
      if (exportUri.toString().substring(0, 5) != 'asset') {
        if (exportUri.toString() != 'package:$packageName/$packageName.dart') {
          final expStr = getExportString(exportUri);
          expList.add(expStr);
        }
      }
    }

    content.addAll(expList);
    content.insert(0, '// $packageName');
    if (content.isNotEmpty) {
      await buildStep.writeAsString(
          AssetId(
              buildStep.inputId.package, 'lib/src/exports.dart_exporter.dart'),
          content.join('\n'));
    }
    print(
      '[DART_EXPORTER] add to your library main file $packageName.dart'
      '\n'
      "export '$generatedFilePath';",
    );
  }

  String getExportString(Uri exportUri) {
    final expStr = "export '$exportUri'${getHiddenClass(exportUri)};";
    return expStr;
  }

  String getHiddenClass(Uri exportUri) {
    final hiddenElements = DartExporterInitializeBuilder.hiddenElements;
    final hiddenClasses = <String>{};
    for (final hiddenElement in hiddenElements) {
      if (hiddenElement.source?.uri == exportUri) {
        final className = hiddenElement.name;
        if (className != null) {
          hiddenClasses.add(className);
        }
      }
    }
    var result = '';
    if (hiddenClasses.isNotEmpty) {
      result = ' hide ';
      result += hiddenClasses.join(',');
    }
    return result;
  }
}
