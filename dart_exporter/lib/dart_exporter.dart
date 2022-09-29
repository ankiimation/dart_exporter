library dart_exporter;

import 'dart:io';

import 'package:build/build.dart';
import 'package:dart_exporter/src/exporter_generator_builder.dart';
import 'package:dart_exporter/src/exports_builder.dart';

Builder dartExporterInitializeBuilder(BuilderOptions options) {
  return DartExporterInitializeBuilder();
}

Builder dartExporterBuilder(BuilderOptions options) {
  return DartExporterBuilder(pubspecFile: File('pubspec.yaml'));
}
