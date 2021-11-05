#!/bin/sh

cd "$(dirname "$0")" || exit 1

# some environments have cmake v2 as 'cmake' and v3 as 'cmake3'
# check for cmake3 first then fallback to just cmake

B_CMAKE=$(command -v cmake3 2>/dev/null)
if [ "$?" -eq 0 ]; then
    continue
else
    # OK, so cmake3 isn't in path, so let's test to see if `cmake` itself exists, before proceeding.
    if command -v cmake 2>/dev/null; then
        B_CMAKE=$(command -v cmake)
        # We have a cmake executable available, now let's proceed!
    else
        echo "ERROR: CMake not in $PATH, cannot build! Please install CMake, or if this persists, file a bug report."
        exit 1
    fi
fi

B_BUILD_TYPE="${B_BUILD_TYPE:-Debug}"
B_CMAKE_FLAGS="-DCMAKE_BUILD_TYPE=${B_BUILD_TYPE} ${B_CMAKE_FLAGS:-}"

if [ "$(uname)" = "Darwin" ]; then
    # macOS needs a little help, so we source this environment script to fix paths.
    . ./macos_environment.sh

    B_CMAKE_FLAGS="${B_CMAKE_FLAGS} -DCMAKE_OSX_SYSROOT=$(xcode-select --print-path)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9"
fi

# Source local build variables to the environment, if available.
# If not, continue as normal, and silently.
if [ -e "./build_env.sh" ]; then
    . "./build_env.sh"
fi

# Initialise Git submodules
git submodule update --init --recursive

rm -rf ./build
mkdir build
cd ./build

$B_CMAKE "$B_CMAKE_FLAGS" .. || exit 1

echo "INFO: Now commencing Barrier build process..."
echo "INFO: We're building an $B_BUILD_TYPE output type."
$(command -v make) || exit 1

exit
