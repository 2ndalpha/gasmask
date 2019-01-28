#!/bin/bash
set -eu

# Workaround for a Cocoapods 1.5 bug: https://github.com/CocoaPods/CocoaPods/issues/7708
export EXPANDED_CODE_SIGN_IDENTITY="-"
export EXPANDED_CODE_SIGN_IDENTITY_NAME="-"

pod install
xcodebuild -workspace "Gas Mask.xcworkspace" -scheme "Gas Mask" ARCHS="i386 x86_64" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
