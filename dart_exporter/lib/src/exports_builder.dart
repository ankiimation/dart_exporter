import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:dart_exporter/src/exporter_generator_builder.dart';
import 'package:glob/glob.dart';
import 'package:yaml/yaml.dart';

/// the ExportsBuilder will create the file to
/// export all dart files
class DartExporterBuilder implements Builder {
  static var packageName = '';
  static const generatedFilePath = 'src/exports.dart_exporter.dart';

  final File pubspecFile;
  DartExporterBuilder({
    required this.pubspecFile,
  });

  @override
  final Map<String, List<String>> buildExtensions = {
    r'$lib$': [generatedFilePath]
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    print('[DART_EXPORTER] - Creating exports file');
    final exports = buildStep.findAssets(
        Glob('**/*${DartExporterInitializeBuilder.exportExtension}'));

    late final List<String> ignoredExtensions;
    try {
      final pubspec = await loadPubspecConfig(pubspecFile);
      ignoredExtensions = pubspec.dart_exporter.ingore_if_path_matched;
    } catch (e) {
      ignoredExtensions = [];
    }
    final exportList = <String>[];
    final content = ['//! AUTO GENERATE FILE, DONT MODIFY!!'];
    content.add(
        '// ignored: \n${ignoredExtensions.map((e) => '//$e').join('\n')}');
    await for (final exportLibrary in exports) {
      final exportUri = exportLibrary.changeExtension('.dart').uri;
      if (exportUri.toString().substring(0, 5) != 'asset') {
        if (exportUri.toString() != 'package:$packageName/$packageName.dart') {
          final expStr =
              getExportString(exportUri, ignoredExtensions: ignoredExtensions);
          exportList.add(expStr);
        }
      }
    }

    content.addAll(exportList);
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

  String getExportString(Uri exportUri,
      {List<String> ignoredExtensions = const []}) {
    final expStr = "export '$exportUri'${getHiddenClass(exportUri)};";
    for (final ignoredExtension in ignoredExtensions) {
      if (exportUri.toString().contains(
            RegExp(ignoredExtension, caseSensitive: true),
          )) {
        return '//ignored_file_extension [$ignoredExtension]:  $expStr';
      }
    }
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

  Future<Pubspec> loadPubspecConfig(File pubspecFile) async {
    final content =
        await pubspecFile.readAsString().catchError((dynamic error) {
      throw FileSystemException(
          'Cannot open pubspec.yaml: ${pubspecFile.absolute}');
    });
    final userMap = loadYaml(content);
    final pubspec = Pubspec.fromJson(jsonEncode(userMap));
    return pubspec;
  }
}

class Pubspec {
  final DartExporter dart_exporter;
  Pubspec({
    required this.dart_exporter,
  });

  Map<String, dynamic> toMap() {
    return {
      'dart_exporter': dart_exporter.toMap(),
    };
  }

  factory Pubspec.fromMap(Map<String, dynamic> map) {
    return Pubspec(
      dart_exporter: DartExporter.fromMap(map['dart_exporter']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Pubspec.fromJson(String source) =>
      Pubspec.fromMap(json.decode(source));
}

class DartExporter {
  final List<String> ingore_if_path_matched;
  DartExporter({
    required this.ingore_if_path_matched,
  });

  Map<String, dynamic> toMap() {
    return {
      'ingore_if_path_matched': ingore_if_path_matched,
    };
  }

  factory DartExporter.fromMap(Map<String, dynamic> map) {
    return DartExporter(
      ingore_if_path_matched: List<String>.from(map['ingore_if_path_matched']),
    );
  }

  String toJson() => json.encode(toMap());

  factory DartExporter.fromJson(String source) =>
      DartExporter.fromMap(json.decode(source));
}
