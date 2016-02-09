#!/bin/bash

#Fail on first error
set -e

#This script assumes that:
#1. First argument would be the mPulse build version
#2. Second argument would be the path to Xcode
#3. Third argument would be the build mode for Xcode build
#4. Fourth arugment is whether or not to code-sign

USER_HOME=$(eval echo ~${SUDO_USER})
XCODE4_PATH="$USER_HOME/Desktop/Xcode.app"
BUILD_VERSION_NUMBER="1.0.0"
BUILD_MODE="Release"
CODE_SIGN=true
if [ $# -eq 0 ]; then
  # Nothing to do
  echo "Using default build settings..."
elif [ $# -eq 1 ]; then
  BUILD_VERSION_NUMBER=$1
elif [ $# -eq 2 ]; then
  BUILD_VERSION_NUMBER=$1
  XCODE4_PATH=$2
elif [ $# -eq 3 ]; then
  BUILD_VERSION_NUMBER=$1
  XCODE4_PATH=$2
  BUILD_MODE=$3
elif [ $# -eq 4 ]; then
  BUILD_VERSION_NUMBER=$1
  XCODE4_PATH=$2
  BUILD_MODE=$3
  CODE_SIGN=$4
fi

#This function assumes that:
#1. First argument would be the prefix of Xcode project built. (Example: Boomerang)
#2. Second argument would be the Xcode target to be built. (Example: BoomerangLib)
#3. Third argument would be the library name without the suffix. (Example: libMPulse)
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
  if [ "$CODE_SIGN" -eq "true" ]; then
    /usr/bin/codesign --timestamp=none -f -s "iPhone Distribution: SOASTA Inc." "build/DynamicLibraries/${XCODE_LIB}.dylib"
  fi

  # Removing the armv6 individual slice.
  rm -rf build/StaticLibraries/${XCODE_LIB}_armv6.*
  rm -rf build/DynamicLibraries/${XCODE_LIB}_armv6.*
}

# Inject Build Version Number into MPulse.m file
sed -i.bak s/"mPulse Build Number"/"mPulse Build Number - $BUILD_VERSION_NUMBER"/ Boomerang/MPulse.h
sed -i.bak s/"MPULSE_BUILD_VERSION_NUMBER = @\"\""/"MPULSE_BUILD_VERSION_NUMBER = @\"$BUILD_VERSION_NUMBER\""/ Boomerang/MPulse.m

# Build mPulse Mobile Library
buildLibrary "Boomerang" "BoomerangLib" "libMPulse"

# Remove old version of MPulse.framework.zip
rm -rf "build/MPulse.framework.zip"

# Zip up the MPulse.framework
# We do the zipping in this script so we could preserve the symbolic links inside the framework
cd "build/StaticLibraries"
/usr/bin/zip -r -y "../MPulse.framework.zip" "MPulse.framework" -x "*.DS_Store" -x "*.svn*"

# Return to origin
cd "../.."
