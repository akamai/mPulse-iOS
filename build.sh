#!/bin/bash

# Fail on first error
set -e

USER_HOME=$(eval echo ~${SUDO_USER})
BUILD_MAJOR_MINOR=`cat build.version`
BUILD_NUMBER="0"
BUILD_MODE="Release"
CODE_SIGN=true

if [ $# -eq 0 ]; then
  # Nothing to do
  echo "Using default build settings..."
elif [ $# -eq 1 ]; then
  BUILD_NUMBER=$1
elif [ $# -eq 2 ]; then
  BUILD_NUMBER=$1
  BUILD_MODE=$2
elif [ $# -eq 3 ]; then
  BUILD_NUMBER=$1
  BUILD_MODE=$2
  CODE_SIGN=$3
fi

BUILD_VERSION_NUMBER=${BUILD_MAJOR_MINOR}.${BUILD_NUMBER}

echo "Build # ${BUILD_VERSION} - ${BUILD_MODE} - Code sign: ${CODE_SIGN}"

# Inject Build Version Number into MPulse.h and MPulse.m
sed -i "" s/"^\/\/ mPulse Build Number.*"/"\/\/ mPulse Build Number - ${BUILD_VERSION_NUMBER}"/ Boomerang/MPulse.h
sed -i "" s/"MPULSE_BUILD_VERSION_NUMBER = @\".*\""/"MPULSE_BUILD_VERSION_NUMBER = @\"${BUILD_VERSION_NUMBER}\""/ Boomerang/MPulse.m

# This function assumes that:
# 1. First argument would be the prefix of Xcode project built. (Example: Boomerang)
# 2. Second argument would be the Xcode target to be built. (Example: BoomerangLib)
# 3. Third argument would be the library name without the suffix. (Example: libMPulse)
function buildLibrary
{
  XCODE_PROJECT=$1
  XCODE_TARGET=$2
  XCODE_LIB=$3

  # Remove any old slices we might have
  rm -rf build/StaticLibraries/${XCODE_LIB}*
  rm -rf build/DynamicLibraries/${XCODE_LIB}*

  # Build the armv7, armv7s, arm64 and i386 slices
  /usr/bin/xcodebuild -version
  /usr/bin/xcodebuild -target $XCODE_TARGET -project ${XCODE_PROJECT}.xcodeproj -configuration $BUILD_MODE clean build

  # Codesign the dynamic library
  if [ "$CODE_SIGN" = "true" ]; then
    /usr/bin/codesign --timestamp=none -f -s "iPhone Distribution: SOASTA Inc." "build/DynamicLibraries/${XCODE_LIB}.dylib"
  fi

  # Removing the armv6 individual slice.
  rm -rf build/StaticLibraries/${XCODE_LIB}_armv6.*
  rm -rf build/DynamicLibraries/${XCODE_LIB}_armv6.*
}

# Build mPulse Mobile Library
buildLibrary "Boomerang" "BoomerangLib" "libMPulse"
