library pretty_imports.transformer;

import 'dart:async';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as native_path;
import 'package:analyzer/analyzer.dart';
import 'package:source_maps/refactor.dart' show TextEditTransaction;
import 'package:source_maps/span.dart' show SourceFile;

final path = native_path.url;

class PrettyTransformerGroup implements TransformerGroup {
  final Iterable<Iterable> phases;

  PrettyTransformerGroup(TransformOptions options)
      : phases = _createPhases(options);

  PrettyTransformerGroup.asPlugin(BarbackSettings settings)
      : this(_parseSettings(settings.configuration));
}

TransformOptions _parseSettings(Map args) {
  return new TransformOptions();
}

List<List<Transformer>> _createPhases(TransformOptions options) {
  return [
    [new PrettyTransformer(options)],
  ];
}

class TransformOptions {
}

class PrettyTransformer extends Transformer {
  final TransformOptions options;

  PrettyTransformer(this.options);

  // Accept all Dart files.
  String get allowedExtensions => '.dart';

  Future apply(Transform transform) {
    var input = transform.primaryInput;
    return input.readAsString().then((contents) {
      var file = new SourceFile.text(input.id.path, contents);
      var transaction = new TextEditTransaction(contents, file);

      var unit = parseDirectives(contents, suppressErrors: true);
      var imports = unit.directives
          .where((d) => d is UriBasedDirective)
          .map((d) => d.uri)
          .where((uri) => uri.stringValue.startsWith('package:'))
          .map((importUri) {
            var uri = Uri.parse(importUri.stringValue);
            var parts = path.split(uri.path);
            if (parts.length == 1) {
              parts.add(parts[0]);
            } else if (parts.last.endsWith('.dart')) {
              return null;
            }
            var packagePath = parts.skip(1);
            var importAssetId = new AssetId(parts[0], 'lib/${path.joinAll(packagePath)}.dart');
            return transform.getInput(importAssetId).then((asset) {
              transaction.edit(importUri.beginToken.offset,  importUri.end,  
                  "'package:${path.joinAll(parts)}.dart'");
            }, onError: (e) => null);
          })
          .where((future) => future != null);
      return Future.wait(imports).then((_) {
        if (!transaction.hasEdits) {
          transform.addOutput(input);
          return;
        }
        var printer = transaction.commit();
        printer.build(file.url);
        transform.addOutput(new Asset.fromString(input.id, printer.text));
      });      
    });
  }
}