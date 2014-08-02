pretty_imports
==============

Transform your superfluous import woes away!

Removes the need for redundant path components from your import statements.

Syntax:
```
import 'package:unittest';
import 'package:unittest/vm_config';
```

Results in:
```
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
```
