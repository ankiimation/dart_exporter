import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_exporter/src/exports_builder.dart';
import 'package:dart_exporter_annotation/dart_exporter_annotation.dart';
import 'package:source_gen/source_gen.dart';

/// visit all files to remember they path
class DartExporterInitializeBuilder implements Builder {
  static const exportExtension = '.exports';
  static final List<Element> hiddenElements = [];
  static final List<Element> forceExportElements = [];
  @override
  final buildExtensions = const {
    '.dart': [exportExtension]
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    DartExporterBuilder.packageName = buildStep.inputId.package;

    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;

    final libraryElements = await buildStep.inputLibrary;

    final elements = [libraryElements, ...libraryElements.topLevelElements];
    final doNotExportAnnotation = TypeChecker.fromRuntime(DoNotExport);
    final exportAnnotation = TypeChecker.fromRuntime(Export);

    final defaultElements = <Element>[];
    for (final element in elements) {
      if (doNotExportAnnotation.hasAnnotationOf(element)) {
        hiddenElements.add(element);
      }
      if (exportAnnotation.hasAnnotationOf(element)) {
        forceExportElements.add(element);
      }
      defaultElements.add(element);
    }
    if (defaultElements.isNotEmpty) {
      await buildStep.writeAsString(
          buildStep.inputId.changeExtension(exportExtension),
          defaultElements.join(','));
    }
  }
}
