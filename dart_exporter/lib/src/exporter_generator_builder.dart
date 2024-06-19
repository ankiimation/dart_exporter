import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'package:dart_exporter/src/exports_builder.dart';
import 'package:dart_exporter_annotation/dart_exporter_annotation.dart';

/// visit all files to remember they path
class DartExporterInitializeBuilder implements Builder {
  static const exportExtension = '.exports';
  @override
  final buildExtensions = const {
    '.dart': [exportExtension]
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // hiddenElements.clear();
    // forceExportElements.clear();
    DartExporterBuilder.packageName = buildStep.inputId.package;

    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;

    final libraryElements = await buildStep.inputLibrary;

    final elements = [libraryElements, ...libraryElements.topLevelElements];

    final defaultElements = List<Element>.from(elements);

    for (final element in elements) {
      if (element.isPublic) {
        defaultElements.add(element);
      }
    }
    if (defaultElements.isNotEmpty) {
      final json = jsonEncode({
        'elements': defaultElements
            .where((element) => element.displayName.isNotEmpty)
            .map(
          (e) {
            final doNotExportAnnotation = TypeChecker.fromRuntime(DoNotExport);
            final exportAnnotation = TypeChecker.fromRuntime(Export);
            final freezedAnnotation = TypeChecker.fromRuntime(Freezed);

            final hide = doNotExportAnnotation.hasAnnotationOf(e,
                throwOnUnresolved: false);
            final show =
                exportAnnotation.hasAnnotationOf(e, throwOnUnresolved: false);
            final hasFreezed =
                freezedAnnotation.hasAnnotationOf(e, throwOnUnresolved: false);
            final forceShow = (exportAnnotation
                    .firstAnnotationOf(
                      e,
                      throwOnUnresolved: false,
                    )
                    ?.getField('forceExportItems')
                    ?.toListValue()
                    ?.map((e) => e.toStringValue()!))?.toList() ??
                [];
            return DartExportElement(
              className: e.displayName,
              hide: hide,
              show: show,
              uri: e.librarySource?.uri.toString(),
              forceExportItems: forceShow,
              isUsingFreezed: hasFreezed,
            ).toMap();
          },
        ).toList(),
      });

      await buildStep.writeAsString(
        buildStep.inputId.changeExtension(exportExtension),
        json,
      );
    }
  }
}

class DartExportElement {
  final String className;
  final String? uri;
  final bool hide;
  final bool show;
  final List<String> forceExportItems;
  final bool isUsingFreezed;
  DartExportElement({
    required this.className,
    required this.uri,
    required this.hide,
    required this.show,
    required this.forceExportItems,
    required this.isUsingFreezed,
  });

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'uri': uri,
      'hide': hide,
      'show': show,
      'forceExportItems': forceExportItems,
      'isUsingFreezed': isUsingFreezed,
    };
  }

  factory DartExportElement.fromMap(Map<String, dynamic> map) {
    return DartExportElement(
      className: map['className'] ?? '',
      uri: map['uri'],
      hide: map['hide'] ?? false,
      show: map['show'] ?? false,
      forceExportItems: List<String>.from(map['forceExportItems']),
      isUsingFreezed: map['isUsingFreezed'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory DartExportElement.fromJson(String source) =>
      DartExportElement.fromMap(json.decode(source));
}
