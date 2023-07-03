/// Support for doing something awesome.
///
/// More dartdocs go here.
library dart_exporter_annotation;

const doNotExport = DoNotExport();
const export = Export();

class DoNotExport {
  const DoNotExport();
}

class Export {
  final List<String> forceExportItems;
  const Export({
    this.forceExportItems = const [],
  });
}
