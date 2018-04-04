#!/bin/sh
set -ex
if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then     # on pull requests
    echo "Build on PR"
    FASTLANE_EXPLICIT_OPEN_SIMULATOR=2 bundle exec fastlane test project:"BridgeApp/BridgeApp.xcodeproj" scheme:"BridgeAppExample"
elif [[ -z "$TRAVIS_TAG" && "$TRAVIS_BRANCH" == "master" ]]; then  # non-tag commits to master branch
    echo "Build on merge to master"
#    bundle exec fastlane ci_archive scheme:"BridgeAppExample" export_method:"app-store" project:"BridgeApp/BridgeApp.xcodeproj"
elif [[ -z "$TRAVIS_TAG" && "$TRAVIS_BRANCH" =~ ^stable-.* ]]; then # non-tag commits to stable branches
    echo "Build on stable branch"
    FASTLANE_EXPLICIT_OPEN_SIMULATOR=2 bundle exec fastlane test project:"BridgeApp/BridgeApp.xcodeproj" scheme:"BridgeAppExample"
#    bundle exec fastlane beta scheme:"BridgeAppExample" export_method:"app-store" project:"BridgeApp/BridgeApp.xcodeproj"
fi
exit $?
