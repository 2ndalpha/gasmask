#!/bin/bash
set -eu
pod install
xcodebuild -workspace "Gas Mask.xcworkspace" -scheme "Gas Mask" ARCHS="i386 x86_64" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
