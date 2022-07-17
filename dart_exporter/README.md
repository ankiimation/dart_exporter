Create exports with build runner

## Usage
Add package to dev_dependencies
```yaml
dev_dependencies:
  build_runner: 
  dart_exporter: {version}
```

```
dart pub run build_runner build
```

## Features and bugs
You need to DELETE generated file named ```exports.dart_exporter.dart``` before run build_runner to generate updated exports
