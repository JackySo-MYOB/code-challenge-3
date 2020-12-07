## Add eslint into github workflow to validate server.js syntax before build and publish docker

### Install and configure eslint into nodejs

```bash
npm install --save-dev eslint@^4.19.1
```

```bash
./node_modules/.bin/eslint --init

1. ? How would you like to congure ESLint? (Use arrow keys) Use a popular style guide
2. ? Which style guide do you want to follow?  Standard
3. ? What format do you want your cong le to be in? JavaScript
4. ? The style guide "standard" requires eslint@>=6.2.2. You are currently using eslint@4.19.1.
Do you want to upgrade?  Yes
```

### Add valiate into package.json and run validate

```bash

$grep validate server.json
  "validate": "./node_modules/.bin/eslint server.js"

```

```bash
$ npm run validate

> code_challenge_node_app@2.1.0 validate /home1/jso/myob-work/work/aws-cf/git-repo/code-challenge-3
> eslint server.js


/home1/jso/myob-work/work/aws-cf/git-repo/code-challenge-3/server.js
   1:13   error    Extra semicolon                                      semi
   3:35   error    Extra semicolon                                      semi
   4:46   error    Extra semicolon                                      semi
   7:18   error    Extra semicolon                                      semi
   8:23   error    Extra semicolon                                      semi
  16:22   error    Extra semicolon                                      semi
  17:19   error    A space is required after ','                        comma-spacing
  17:28   error    Missing space before function parentheses            space-before-function-paren
  17:32   error    A space is required after ','                        comma-spacing
  17:37   error    Missing space before opening brace                   space-before-blocks
  18:1    error    Expected indentation of 2 spaces but found 4         indent
  18:5    warning  Unexpected var, use let or const instead             no-var
  18:20   error    Unexpected whitespace before semicolon               semi-spacing
  18:21   error    Extra semicolon                                      semi
  19:1    error    Expected indentation of 2 spaces but found 4         indent
  19:29   error    There should be no space after '['                   array-bracket-spacing
  19:30   error    A space is required after '{'                        object-curly-spacing
  19:31   error    Strings must use singlequote                         quotes
  19:31   error    Unnecessarily quoted property 'version' found        quote-props
  19:51   error    Unnecessarily quoted property 'lastcommitsha' found  quote-props
  19:51   error    Strings must use singlequote                         quotes
  19:76   error    Unnecessarily quoted property 'description' found    quote-props
  19:76   error    Strings must use singlequote                         quotes
  19:91   error    Strings must use singlequote                         quotes
  19:121  error    A space is required before '}'                       object-curly-spacing
  19:122  error    There should be no space before ']'                  array-bracket-spacing
  19:124  error    Extra semicolon                                      semi
  20:1    error    Unexpected tab character                             no-tabs
  20:1    error    Expected indentation of 2 spaces but found 1 tab     indent
  20:18   error    Extra semicolon                                      semi
  21:3    error    Extra semicolon                                      semi
  23:23   error    Extra semicolon                                      semi
  24:14   error    Extra semicolon                                      semi

✖ 33 problems (32 errors, 1 warning)
  31 errors and 1 warning potentially fixable with the `--fix` option.

```

### Fix syntax error reported in server.js

```diff
$ git diff HEAD@{1} server.js
diff --git a/server.js b/server.js
index e40d558..465db20 100644
--- a/server.js
+++ b/server.js
@@ -1,11 +1,11 @@
-'use strict';
+'use strict'
 
-const express = require('express');
-const { version } = require('./package.json');
+const express = require('express')
+const { version } = require('./package.json')
 
 // Constants
-const PORT = 8080;
-const HOST = '0.0.0.0';
+const PORT = 8080
+const HOST = '0.0.0.0'
 
 // Fetch git sha
 const gitsha = require('child_process')
@@ -13,12 +13,12 @@ const gitsha = require('child_process')
   .toString().trim()
 
 // App
-const app = express();
-app.get('/version',function(req,res){
-    var myJson = {} ;
-    myJson.myapplication = [ {"version": version, "lastcommitsha": gitsha, "description": "pre-interview technical test"} ];
-       res.json(myJson);
-});
+const app = express()
+app.get('/version', function (req, res) {
+  const myJson = {}
+  myJson.myapplication = [{ version: version, lastcommitsha: gitsha, description: 'pre-interview technical test' }]
+  res.json(myJson)
+})
 
-app.listen(PORT, HOST);
-console.log();
+app.listen(PORT, HOST)
+console.log()
```

### Add validate routine into github docker.yml workflow

```bash
    steps:
    - uses: actions/checkout@v2
    - name: Use Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v1
      with:
        node-version: ${{ matrix.node-version }}
    - run: npm install
    - run: npm run build --if-present
    - run: npm test
    - run: npm run validate
```
