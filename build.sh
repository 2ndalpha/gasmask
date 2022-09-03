#!/bin/bash
set -eu

xcodebuild -project "Gas Mask.xcodeproj" -scheme "Gas Mask" ARCHS="i386 x86_64" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
