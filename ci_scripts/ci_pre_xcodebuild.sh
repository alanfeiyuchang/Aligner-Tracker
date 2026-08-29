#!/bin/sh
#
#  ci_pre_xcodebuild.sh
#  Aligner Tracker — Xcode Cloud
#
#  Stamps the archive with Xcode Cloud's own build number so successive
#  archives can be told apart, and so the build number is already unique the
#  day a distribution step gets added (App Store Connect refuses a build
#  number it has seen before).
#
#  CURRENT_PROJECT_VERSION lives on the project's build configurations and
#  every target inherits it, so rewriting it here covers the app and the
#  widget extension in one edit.
#
#  Outside Xcode Cloud CI_BUILD_NUMBER is unset and this does nothing, so
#  local builds keep whatever is committed. Delete this file if you would
#  rather the build number stay under manual control.
#

set -e

if [ -z "$CI_BUILD_NUMBER" ]; then
    echo "CI_BUILD_NUMBER is not set — leaving the committed build number alone."
    exit 0
fi

PROJECT="$CI_PRIMARY_REPOSITORY_PATH/Aligner Tracker.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT" ]; then
    echo "error: cannot find $PROJECT" >&2
    exit 1
fi

before=$(grep -c "CURRENT_PROJECT_VERSION = " "$PROJECT" || true)
sed -i '' "s/CURRENT_PROJECT_VERSION = .*;/CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER;/" "$PROJECT"
after=$(grep -c "CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER;" "$PROJECT" || true)

if [ "$before" -eq 0 ] || [ "$before" -ne "$after" ]; then
    echo "error: expected to rewrite $before CURRENT_PROJECT_VERSION entries, rewrote $after" >&2
    exit 1
fi

echo "Build number set to $CI_BUILD_NUMBER ($after entries)."
