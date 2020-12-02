## Sub-task-1
Code challenge sub-task-1 documentation

### Task requirements

1. Create a simple application which has a single “/version” endpoint.

### Operations and files used in this section

```diff
├── package.json
├── server.js


+install-dep                              Intall nodejs dependencies in package.json
+update-version                           Update node pakage.json version in package.json
+run-node                                 Run nodejs application $(APPS)
+kill-node                                Kill nodejs process
```

### Work and validation 

#### Install node dependencies
```bash

$ make install-dep
npm notice created a lockfile as package-lock.json. You should commit this file.
npm WARN code_challenge_node_app@1.0.0 No repository field.
npm WARN code_challenge_node_app@1.0.0 No license field.

added 50 packages from 37 contributors and audited 50 packages in 3.374s
found 0 vulnerabilities
```

#### Run node application
```bash

$ make run-node

{
  "myapplication": [
    {
      "version": "1.0.0",
      "lastcommitsha": "805a297",
      "description": "pre-interview technical test"
    }
  ]
}
```

#### Validate running nodejs process and kill it to prepare for next code change
```bash

$ ps -ef | grep node
jso        19518    1376  0 22:05 pts/0    00:00:00 node server.js
jso        19563   16478  0 22:08 pts/0    00:00:00 grep --color=auto node

$ make kill-node

$ ps -ef | grep node
jso        19575   16478  0 22:08 pts/0    00:00:00 grep --color=auto node
```

#### Advance nodejs application version in package.json as code change and re-run application
```bash
$ make update-version
v1.0.3

$ make run-node

{
  "myapplication": [
    {
      "version": "1.0.3",
      "lastcommitsha": "ebe7643",
      "description": "pre-interview technical test"
    }
  ]
}

$ git rev-parse --short HEAD
ebe7643

$ grep version package.json
  "version": "1.0.3",

$ make kill-node
```
