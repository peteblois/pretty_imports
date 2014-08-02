library pretty_imports.pretty_imports_test;

import 'package:code_transformers/tests' as tests;
import 'package:pretty_imports/transformer';
import 'package:unittest/compact_vm_config';
import 'package:unittest';

main() {
  useCompactVMConfiguration();

  var options = new TransformOptions();

  var phases = [
    [new PrettyTransformer(options)],
  ];

  test('modifies imports', () {
    return tests.applyTransformers(phases,
          inputs: {
            'a|web/main.dart': '''
                import 'package:path';
                ''',
            'path|lib/path.dart': '',
          },
          results: {
            'a|web/main.dart': '''
                import 'package:path/path.dart';
                ''',
          });
  });
  
  test('does not modify to incorrect imports', () {
      return tests.applyTransformers(phases,
            inputs: {
              'a|web/main.dart': '''
                import 'package:path';
                ''',
            },
            results: {
              'a|web/main.dart': '''
                import 'package:path';
                ''',
            });
    });
  
  test('modifies package libraries', () {
        return tests.applyTransformers(phases,
              inputs: {
                'a|web/main.dart': '''
                import 'package:polymer/publish';
                ''',
                'polymer|lib/publish.dart': '',
              },
              results: {
                'a|web/main.dart': '''
                import 'package:polymer/publish.dart';
                ''',
              });
      });
}