import 'package:dart_exporter_annotation/dart_exporter_annotation.dart';

class A {}

@Export()
class AExport {}

@Export(
  forceExportItems: ['test_'],
)
class AExportPremium {}
