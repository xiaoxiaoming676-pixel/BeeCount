#!/usr/bin/env bash
set -euo pipefail

apk=smoke/app-dev-debug.apk
aapt_bin=$(find "${ANDROID_HOME}/build-tools" -name aapt -type f | sort -V | tail -n 1)
test -n "$aapt_bin"
package_name=$($aapt_bin dump badging "$apk" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")
test -n "$package_name"
echo "Installing package: $package_name"
adb install "$apk"
adb shell monkey -p "$package_name" -c android.intent.category.LAUNCHER 1
sleep 12
adb shell pidof "$package_name"
