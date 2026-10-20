#!/usr/bin/env bash
# One-time project bootstrap. Run by the team leader ONCE, then commit android/ and ios/.
# Requires: Flutter SDK, python3. On Windows run it from Git Bash.
set -e

if [ -d android ]; then echo "android/ already exists, nothing to do."; exit 0; fi

# 1) Generate the native folders without touching our own files.
flutter create --project-name classtrack --org com.classtrack --platforms android,ios _tmp
cp -rn _tmp/. . || true
rm -rf _tmp

# 2) Location permissions.
python3 - <<'PY'
import re
p = "android/app/src/main/AndroidManifest.xml"
s = open(p).read()
if "ACCESS_FINE_LOCATION" not in s:
    perms = ('<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>\n'
             '    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>\n'
             '    <uses-permission android:name="android.permission.INTERNET"/>\n    ')
    s = s.replace("<application", perms + "<application", 1)
    open(p, "w").write(s)

p = "ios/Runner/Info.plist"
s = open(p).read()
if "NSLocationWhenInUseUsageDescription" not in s:
    key = ("\t<key>NSLocationWhenInUseUsageDescription</key>\n"
           "\t<string>ClassTrack needs your location to verify you are in the classroom.</string>\n")
    s = s.replace("</dict>\n</plist>", key + "</dict>\n</plist>")
    open(p, "w").write(s)
PY

flutter pub get
echo ""
echo "Done. Next: flutterfire configure  (see README, step 3)"
