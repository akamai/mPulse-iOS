# Boomerang iOS Project Info

## Project Overview

This project contains the code for mPulse Mobile Boomerang for iOS.

It consists of several components:

1. `Boomerang/`: mPulse Mobile Boomerang iOS library.

2. `BoomerangTests/`: Tests for the the library.

3. `BoomerangTestsWithPods/`: Tests for other CocoaPods libraries.

### mPulse Mobile Boomerang iOS code

The mPulse Mobile Boomerang iOS library is contained in the `Boomerang/` directory.  The project can be loaded in XCode via `Boomerang.xcworkspace`.  There is also a project file `Boomerang.xcodeproj`, but the workspace should be used as it contains the Pods files and test targets.

The library can be built via:

```
./build.sh [build number] [Release/Debug] [Code sign true/false]
```

The output will then be in `build/`:

* `build/`: All files
    * `build/DynamicLibraries/`: Dynamic libraries
    * `build/StaticLibraries/`: Static libraries
        * `build/StaticLibraries/MPulse.framework.zip`: Framework file
        * `build/StaticLibraries/Pods/`: Files for CocoaPods

### BoomerangTests

The core tests are in `BoomerangTests/`.  They will be available when you load `Boomerang.xcworkspace`.

Tests can be run via XCode or by:

```
./test.sh
```

You can also run a subset of tests via:

```
./test-one.sh MPURLSessionTests
./test-one.sh MPURLSessionTests testThreadedDataTaskWithRequestSuccess
```

### Versioning

The project version is set via `build.version`:

```
1.0
```

The Jenkins build number is tacked on to the end of the `major.minor` version during `build.sh [build number]`.  e.g. for build 100, the version will be `1.0.100`.

This version number is swapped into the following files during `./build.sh`:

1. `Boomerang/MPulse.h`
1. `Boomerang/MPulse.m`

## MPulse.framework.zip

`build/StaticLibraries/MPulse.framework.zip` is generated during build by `post-build.sh`.

## CocoaPods

CocoaPods files in `build/StaticLibraries/Pods` are generated during build by `post-build.sh`.

## Lint

Linting is done via [ObjClean](http://objclean.com/).

The ObjClean configuration is in `StyleSettings.plist`.

Lint is run during build and in XCode.
