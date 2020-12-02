# Sub-task-3
Code challenge sub-task-3 documentation

## Task requirements

3. Create a CI pipeline for your application

### github workflow file 
```yaml

name: Node.js CI to Docker hub 

on:
  push:
    branches: [ main ]

env:
  IMAGE_NAME: node-web
  DOCKER_REGISTRY: docker.io

jobs:
  build_push_docker:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [10.x]

    steps:
    - uses: actions/checkout@v2
    - name: Use Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v1
      with:
        node-version: ${{ matrix.node-version }}
    - run: npm install
    - run: npm run build --if-present
    - run: npm test
      env:
        CI: true

    - name: Checkout
      uses: actions/checkout@v2

    - name: Login to DockerHub
      if: success()
      uses: docker/login-action@v1 
      with:
        username: ${{ secrets.DOCKER_HUB_USERNAME }}
        password: ${{ secrets.DOCKER_HUB_PASSWORD }}

    - name: Set version from package.json
      run: |
        version=$(grep version package.json | awk -F':' '{ print $2 }' | sed 's/[", ]//g')
        echo "::set-output name=VERSION::$version"
      id: package-json-version

    - name: Docker build image
      if: success()
      run: docker build . --file Dockerfile --tag ${{ secrets.DOCKER_HUB_USERNAME }}/$IMAGE_NAME:${{ steps.package-json-version.outputs.VERSION }}

    - name: Push image to docker.io
      if: success()
      run: docker push $DOCKER_REGISTRY/${{ secrets.DOCKER_HUB_USERNAME }}/$IMAGE_NAME:${{ steps.package-json-version.outputs.VERSION }}

```

### Github workflow screenshot

<p align="center">
<img src="https://github.com/JackySo-MYOB/code-challenge-3/blob/main/images/github-action.PNG" width="600" height="600">
</p>

