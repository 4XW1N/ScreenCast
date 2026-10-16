#!/bin/bash
# Build a signed APK locally using a debug keystore
set -e

cd "$(dirname "$0")"

export JAVA_HOME="$HOME/jdk-17.0.2"
export PATH="$JAVA_HOME/bin:$PATH"

# Generate debug keystore if not exists
if [ ! -keystore/debug.keystore ]; then
    mkdir -p keystore
    keytool -genkeypair \
        -v \
        -keystore keystore/debug.keystore \
        -storepass android \
        -alias androiddebugkey \
        -keypass android \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -dname "CN=Android Debug,O=Android,C=US"
fi

# Build signed APK
./gradlew assembleRelease -Pandroid.injected.signing.store.file=keystore/debug.keystore \
    -Pandroid.injected.signing.store.password=android \
    -Pandroid.injected.signing.key.alias=androiddebugkey \
    -Pandroid.injected.signing.key.password=android

echo "=== BUILD SUCCESSFUL ==="
echo "APK: $(pwd)/app/build/outputs/apk/release/app-release.apk"
ls -la app/build/outputs/apk/release/app-release.apk