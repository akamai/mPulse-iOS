#
# This is called by the BoomerangLib target during its build
#

#
# Make output folders
#
mkdir -p "${BUILD_DIR}/${CONFIGURATION}/Library"
mkdir -p "${BUILD_DIR}/StaticLibraries"
mkdir -p "${BUILD_DIR}/StaticLibraries/Pods"
mkdir -p "${BUILD_DIR}/StaticLibraries/Pods/include"
mkdir -p "${BUILD_DIR}/DynamicLibraries"
mkdir -p "${BUILD_DIR}/${CONFIGURATION}-iphoneos"
mkdir -p "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator"

#
# MPulse.framework
#

# dirs
rm -rf "${BUILD_DIR}/StaticLibraries/MPulse.framework"
mkdir -p "${BUILD_DIR}/StaticLibraries/MPulse.framework"
mkdir -p "${BUILD_DIR}/StaticLibraries/MPulse.framework/Versions"
mkdir -p "${BUILD_DIR}/StaticLibraries/MPulse.framework/Versions/A"
mkdir -p "${BUILD_DIR}/StaticLibraries/MPulse.framework/Versions/A/Headers"

# create symlinks
cd "${BUILD_DIR}/StaticLibraries/MPulse.framework"
ln -s Versions/Current/Headers Headers
ln -s Versions/Current/MPulse MPulse
cd Versions
ln -s A Current
cd ../../../../

#
# Copy iphoneos and iphonesim library versions for CocoaPods deployment
#
cp "${BUILD_DIR}/${CONFIGURATION}-iphoneos/libMPulse.a" "${BUILD_DIR}/StaticLibraries/Pods/libMPulse.a"
cp "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/libMPulse.a" "${BUILD_DIR}/StaticLibraries/Pods/libMPulseSim.a"

#
# Combine lib files for device and simulator platforms into one
#
lipo -create "${BUILD_DIR}/${CONFIGURATION}-iphoneos/libMPulse.a" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/libMPulse.a" -output "${BUILD_DIR}/${CONFIGURATION}/Library/libMPulse.a"

# combine dynamic lib files for device and simulator platforms into one
lipo -create "${BUILD_DIR}/${CONFIGURATION}-iphoneos/libMPulse.dylib" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/libMPulse.dylib" -output "${BUILD_DIR}/${CONFIGURATION}/Library/libMPulse.dylib"

#
# Copy the headers (we could have used a copy files build phase, too)
#
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/usr" "${BUILD_DIR}/${CONFIGURATION}/Library"

#
# Copy the recently created files to an accessible folder
#
cp "${BUILD_DIR}/${CONFIGURATION}/Library/libMPulse.a" "${BUILD_DIR}/StaticLibraries/"

#
# Move headers to regular and pods dirs
#
cp -R "${BUILD_DIR}/${CONFIGURATION}/Library/usr/local/include/" "${BUILD_DIR}/StaticLibraries/"
cp -R "${BUILD_DIR}/${CONFIGURATION}/Library/usr/local/include/" "${BUILD_DIR}/StaticLibraries/Pods/include"

#
# Copy the recently created files to an accessible folder
#
cp "${BUILD_DIR}/${CONFIGURATION}/Library/libMPulse.dylib" "${BUILD_DIR}/DynamicLibraries/"

#
# Copy recently created library and headers to the Framework directory as well
#
cp "${BUILD_DIR}/${CONFIGURATION}/Library/libMPulse.a" "${BUILD_DIR}/StaticLibraries/MPulse.framework/Versions/A/MPulse"
cp -R "${BUILD_DIR}/${CONFIGURATION}/Library/usr/local/include/" "${BUILD_DIR}/StaticLibraries/MPulse.framework/Versions/A/Headers/"

#
# Remove the old MPulse.framework.zip
#
rm -f "${BUILD_DIR}/MPulse.framework.zip"

#
# Create MPulse.framework.zip
#
cd "${BUILD_DIR}/StaticLibraries"
zip -r -y "MPulse.framework.zip" "MPulse.framework" -x "*.DS_Store" -x "*.svn*"

